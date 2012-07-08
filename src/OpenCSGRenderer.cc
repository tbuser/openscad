/*
 *  OpenSCAD (www.openscad.org)
 *  Copyright (C) 2009-2011 Clifford Wolf <clifford@clifford.at> and
 *                          Marius Kintel <marius@kintel.net>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  As a special exception, you have permission to link this program
 *  with the CGAL library and distribute executables, as long as you
 *  follow the requirements of the GNU GPL in regard to all of the
 *  software in the executable aside from CGAL.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#include "system-gl.h"
#include "OpenCSGRenderer.h"
#include "polyset.h"
#include "csgterm.h"
#include "stl-utils.h"

#ifdef ENABLE_OPENCSG
#include <sstream>
#include "printutils.h"
#include <opencsg.h>

/* create the Info object. */
OpenCSG_GLInfo::OpenCSG_GLInfo()
{
        is_opencsg_capable = has_shaders = opencsg_support = false;
	this->opencsg_id = 0;
        glinfo = "";
	for (int i=0;i<SHADERINFO_COUNT;i++) shaderinfo[i]=0;
};

/* Set up the current OpenGL context for OpenCSG. */
OpenCSG_GLInfo enable_opencsg_shaders()
{
	static int opencsg_context = 0;

	OpenCSG_GLInfo si = OpenCSG_GLInfo();
	// FIXME: glGetString(GL_EXTENSIONS) is deprecated in OpenGL 3.0.
	// Use: glGetIntegerv(GL_NUM_EXTENSIONS, &NumberOfExtensions) and
	// glGetStringi(GL_EXTENSIONS, i)

	const char *openscad_disable_gl20_env = getenv("OPENSCAD_DISABLE_GL20");
	if (openscad_disable_gl20_env && !strcmp(openscad_disable_gl20_env, "0")) {
		openscad_disable_gl20_env = NULL;
	}

	// All OpenGL 2 contexts are OpenCSG capable
	if (GLEW_VERSION_2_0) {
		if (!openscad_disable_gl20_env) {
			si.is_opencsg_capable = true;
			si.has_shaders = true;
		}
	}
	// If OpenGL < 2, check for extensions
	else {
		if (GLEW_ARB_framebuffer_object) si.is_opencsg_capable = true;
		else if (GLEW_EXT_framebuffer_object && GLEW_EXT_packed_depth_stencil) {
			si.is_opencsg_capable = true;
		}
#ifdef WIN32
		else if (WGLEW_ARB_pbuffer && WGLEW_ARB_pixel_format) si.is_opencsg_capable = true;
#elif !defined(__APPLE__) && defined(GLXEW_SGIX_pbuffer) && defined(GLXEW_SGIX_fbconfig)
		else if (GLXEW_SGIX_pbuffer && GLXEW_SGIX_fbconfig) si.is_opencsg_capable = true;
#endif
	}

	if ( si.is_opencsg_capable ) si.opencsg_id = opencsg_context++;

	if ( si.has_shaders ) {
  /*
		Uniforms:
		  1 color1 - face color
			2 color2 - edge color
			7 xscale
			8 yscale

		Attributes:
		  3 trig
			4 pos_b
			5 pos_c
			6 mask

		Other:
		  9 width
			10 height

		Outputs:
		  tp
			tr
			shading
	 */
		const char *vs_source =
			"uniform float xscale, yscale;\n"
			"attribute vec3 pos_b, pos_c;\n"
			"attribute vec3 trig, mask;\n"
			"varying vec3 tp, tr;\n"
			"varying float shading;\n"
			"void main() {\n"
			"  vec4 p0 = gl_ModelViewProjectionMatrix * gl_Vertex;\n"
			"  vec4 p1 = gl_ModelViewProjectionMatrix * vec4(pos_b, 1.0);\n"
			"  vec4 p2 = gl_ModelViewProjectionMatrix * vec4(pos_c, 1.0);\n"
			"  float a = distance(vec2(xscale*p1.x/p1.w, yscale*p1.y/p1.w), vec2(xscale*p2.x/p2.w, yscale*p2.y/p2.w));\n"
			"  float b = distance(vec2(xscale*p0.x/p0.w, yscale*p0.y/p0.w), vec2(xscale*p1.x/p1.w, yscale*p1.y/p1.w));\n"
			"  float c = distance(vec2(xscale*p0.x/p0.w, yscale*p0.y/p0.w), vec2(xscale*p2.x/p2.w, yscale*p2.y/p2.w));\n"
			"  float s = (a + b + c) / 2.0;\n"
			"  float A = sqrt(s*(s-a)*(s-b)*(s-c));\n"
			"  float ha = 2.0*A/a;\n"
			"  gl_Position = p0;\n"
			"  tp = mask * ha;\n"
			"  tr = trig;\n"
			"  vec3 normal, lightDir;\n"
			"  normal = normalize(gl_NormalMatrix * gl_Normal);\n"
			"  lightDir = normalize(vec3(gl_LightSource[0].position));\n"
			"  shading = abs(dot(normal, lightDir));\n"
			"}\n";

		/*
			Inputs:
			  tp && tr - if any components of tp < tr, use color2 (edge color)
				shading  - multiplied by color1. color2 is is without lighting
		 */
		const char *fs_source =
			"uniform vec4 color1, color2;\n"
			"varying vec3 tp, tr, tmp;\n"
			"varying float shading;\n"
			"void main() {\n"
			"  gl_FragColor = vec4(color1.r * shading, color1.g * shading, color1.b * shading, color1.a);\n"
			"  if (tp.x < tr.x || tp.y < tr.y || tp.z < tr.z)\n"
			"    gl_FragColor = color2;\n"
			"}\n";

		GLuint vs = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vs, 1, (const GLchar**)&vs_source, NULL);
		glCompileShader(vs);

		GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fs, 1, (const GLchar**)&fs_source, NULL);
		glCompileShader(fs);

		GLuint edgeshader_prog = glCreateProgram();
		glAttachShader(edgeshader_prog, vs);
		glAttachShader(edgeshader_prog, fs);
		glLinkProgram(edgeshader_prog);

		si.shaderinfo[0] = edgeshader_prog;
		si.shaderinfo[1] = glGetUniformLocation(edgeshader_prog, "color1");
		si.shaderinfo[2] = glGetUniformLocation(edgeshader_prog, "color2");
		si.shaderinfo[3] = glGetAttribLocation(edgeshader_prog, "trig");
		si.shaderinfo[4] = glGetAttribLocation(edgeshader_prog, "pos_b");
		si.shaderinfo[5] = glGetAttribLocation(edgeshader_prog, "pos_c");
		si.shaderinfo[6] = glGetAttribLocation(edgeshader_prog, "mask");
		si.shaderinfo[7] = glGetUniformLocation(edgeshader_prog, "xscale");
		si.shaderinfo[8] = glGetUniformLocation(edgeshader_prog, "yscale");

		GLenum err = glGetError();
		if (err != GL_NO_ERROR) {
			PRINTB( "OpenGL Error: %s\n", gluErrorString(err));
		}

		GLint status;
		glGetProgramiv(edgeshader_prog, GL_LINK_STATUS, &status);
		if (status == GL_FALSE) {
			int loglen;
			char logbuffer[1000];
			glGetProgramInfoLog(edgeshader_prog, sizeof(logbuffer), &loglen, logbuffer);
			PRINTB( "OpenGL Program Linker Error:\n%.*s", std::string(logbuffer).c_str());
		} else {
			int loglen;
			char logbuffer[1000];
			glGetProgramInfoLog(edgeshader_prog, sizeof(logbuffer), &loglen, logbuffer);
			if (loglen > 0) {
				PRINTB( "OpenGL Program Link OK:\n%.*s",  std::string(logbuffer).c_str());
			}
			glValidateProgram(edgeshader_prog);
			glGetProgramInfoLog(edgeshader_prog, sizeof(logbuffer), &loglen, logbuffer);
			if (loglen > 0) {
				PRINTB( "OpenGL Program Validation results:\n%.*s",  std::string(logbuffer).c_str());
			}
		}
	}

	GLint rbits, gbits, bbits, abits, dbits, sbits;
	glGetIntegerv(GL_RED_BITS, &rbits);
	glGetIntegerv(GL_GREEN_BITS, &gbits);
	glGetIntegerv(GL_BLUE_BITS, &bbits);
	glGetIntegerv(GL_ALPHA_BITS, &abits);
	glGetIntegerv(GL_DEPTH_BITS, &dbits);
	glGetIntegerv(GL_STENCIL_BITS, &sbits);

	std::stringstream info;
	info << "GLEW version " <<  glewGetString(GLEW_VERSION)
	  << "\nOpenGL version " << glGetString(GL_VERSION) << " "
	  << glGetString(GL_RENDERER) << "(" <<  glGetString(GL_VENDOR) << ")"
	  << "\nRGBA(" <<  rbits<< gbits << bbits << abits << ")"
	  << "\ndepth(" << dbits << "), stencil(" << sbits << ")"
	  << "\nExtensions:\n" << glGetString(GL_EXTENSIONS);

	si.glinfo = info.str();
	return si;
}
#endif // ENABLE_OPENCSG

class OpenCSGPrim : public OpenCSG::Primitive
{
public:
	OpenCSGPrim(OpenCSG::Operation operation, unsigned int convexity) :
			OpenCSG::Primitive(operation, convexity) { }
	shared_ptr<PolySet> ps;
	Transform3d m;
	PolySet::csgmode_e csgmode;
	virtual void render() {
		glPushMatrix();
		glMultMatrixd(m.data());
		ps->render_surface(csgmode, m);
		glPopMatrix();
	}
};

OpenCSGRenderer::OpenCSGRenderer(CSGChain *root_chain, CSGChain *highlights_chain,
																 CSGChain *background_chain, GLint *shaderinfo)
	: root_chain(root_chain), highlights_chain(highlights_chain), 
		background_chain(background_chain), shaderinfo(shaderinfo)
{
}

void OpenCSGRenderer::draw(bool /*showfaces*/, bool showedges) const
{
	if (this->root_chain) {
		GLint *shaderinfo = this->shaderinfo;
		if (!shaderinfo[0]) shaderinfo = NULL;
		renderCSGChain(this->root_chain, showedges ? shaderinfo : NULL, false, false);
		if (this->background_chain) {
			renderCSGChain(this->background_chain, showedges ? shaderinfo : NULL, false, true);
		}
		if (this->highlights_chain) {
			renderCSGChain(this->highlights_chain, showedges ? shaderinfo : NULL, true, false);
		}
	}
}

void OpenCSGRenderer::renderCSGChain(CSGChain *chain, GLint *shaderinfo, 
																		 bool highlight, bool background) const
{
	std::vector<OpenCSG::Primitive*> primitives;
	size_t j = 0;
	for (size_t i = 0;; i++) {
		bool last = i == chain->polysets.size();
		if (last || chain->types[i] == CSGTerm::TYPE_UNION) {
			if (j+1 != i) {
				 OpenCSG::render(primitives);
				glDepthFunc(GL_EQUAL);
			}
			if (shaderinfo) glUseProgram(shaderinfo[0]);
			for (; j < i; j++) {
				const Transform3d &m = chain->matrices[j];
				const Color4f &c = chain->colors[j];
				glPushMatrix();
				glMultMatrixd(m.data());
				PolySet::csgmode_e csgmode = chain->types[j] == CSGTerm::TYPE_DIFFERENCE ? PolySet::CSGMODE_DIFFERENCE : PolySet::CSGMODE_NORMAL;
				if (highlight) {
					setColor(COLORMODE_HIGHLIGHT, shaderinfo);
					csgmode = PolySet::csgmode_e(csgmode + 20);
				}
				else if (background) {
					setColor(COLORMODE_BACKGROUND, shaderinfo);
					csgmode = PolySet::csgmode_e(csgmode + 10);
				} else if (c[0] >= 0 || c[1] >= 0 || c[2] >= 0 || c[3] >= 0) {
					// User-defined color or alpha from source
					setColor(c.data(), shaderinfo);
				} else if (chain->types[j] == CSGTerm::TYPE_DIFFERENCE) {
					setColor(COLORMODE_CUTOUT, shaderinfo);
				} else {
					setColor(COLORMODE_MATERIAL, shaderinfo);
				}
				chain->polysets[j]->render_surface(csgmode, m, shaderinfo);
				glPopMatrix();
			}
			if (shaderinfo) glUseProgram(0);
			for (unsigned int k = 0; k < primitives.size(); k++) {
				delete primitives[k];
			}
			glDepthFunc(GL_LEQUAL);
			primitives.clear();
		}

		if (last) break;

		OpenCSGPrim *prim = new OpenCSGPrim(chain->types[i] == CSGTerm::TYPE_DIFFERENCE ?
				OpenCSG::Subtraction : OpenCSG::Intersection, chain->polysets[i]->convexity);
		prim->ps = chain->polysets[i];
		prim->m = chain->matrices[i];
		prim->csgmode = chain->types[i] == CSGTerm::TYPE_DIFFERENCE ? PolySet::CSGMODE_DIFFERENCE : PolySet::CSGMODE_NORMAL;
		if (highlight) prim->csgmode = PolySet::csgmode_e(prim->csgmode + 20);
		else if (background) prim->csgmode = PolySet::csgmode_e(prim->csgmode + 10);
		primitives.push_back(prim);
	}
	std::for_each(primitives.begin(), primitives.end(), del_fun<OpenCSG::Primitive>());
}
