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

#include "export.h"
#include "printutils.h"
#include "polyset.h"
#include "dxfdata.h"

#include "OffscreenView.h"
#include "bboxhelp.h"

#ifdef ENABLE_EXPORT_PNG

#ifdef ENABLE_OPENCSG
#include <boost/foreach.hpp>
#include <opencsg.h>
#include "OpenCSGRenderer.h"
#include "CSGTermEvaluator.h"
#include "csgterm.h"
#include "csgtermnormalizer.h"
#include "node.h"
#include "module.h"
#include "polyset.h"
#include "builtin.h"
#include "Tree.h"
#include "CGALEvaluator.h"

class CsgInfo
{
public:
	CsgInfo();
	shared_ptr<CSGTerm> root_norm_term;  // Normalized CSG products
	class CSGChain *root_chain;
	std::vector<shared_ptr<CSGTerm> > highlight_terms;
	CSGChain *highlights_chain;
	std::vector<shared_ptr<CSGTerm> > background_terms;
	CSGChain *background_chain;
	OffscreenView *glview;
};

CsgInfo::CsgInfo() {
	root_chain = highlights_chain = background_chain = NULL;
	glview = NULL;
}

void export_png_opencsg( AbstractNode *absolute_root_node, std::string outfile )
{
	CsgInfo csgInfo = CsgInfo();
	try {
		csgInfo.glview = new OffscreenView(512,512);
	} catch (int error) {
		PRINT("Can't create OpenGL OffscreenView. Exiting.\n");
		return;
	};
	shared_ptr<CSGTerm> root_raw_term;
	// Do we have an explicit root node (! modifier)?
	AbstractNode *root_node = find_root_tag(absolute_root_node);
	if (!root_node) root_node = absolute_root_node;

	Tree tree(root_node);

	CGALEvaluator cgalevaluator(tree);
	CSGTermEvaluator evaluator(tree, &cgalevaluator.psevaluator);
	root_raw_term = evaluator.evaluateCSGTerm(*root_node, csgInfo.highlight_terms, csgInfo.background_terms);

	if (!root_raw_term) {
		PRINT("Error: CSG generation failed! (no top level object found)\n");
		return;
	}

	// CSG normalization
	CSGTermNormalizer normalizer(5000);
	csgInfo.root_norm_term = normalizer.normalize(root_raw_term);
	if (csgInfo.root_norm_term) {
		csgInfo.root_chain = new CSGChain();
		csgInfo.root_chain->import(csgInfo.root_norm_term);
		PRINTB( "Normalized CSG tree has %d elements", int(csgInfo.root_chain->polysets.size()));
	}
	else {
		csgInfo.root_chain = NULL;
		PRINT( "WARNING: CSG normalization resulted in an empty tree\n");
	}
	if (csgInfo.highlight_terms.size() > 0) {
		PRINTB("Compiling highlights (%i CSG Trees)...",csgInfo.highlight_terms.size() );
		csgInfo.highlights_chain = new CSGChain();
		for (unsigned int i = 0; i < csgInfo.highlight_terms.size(); i++) {
			csgInfo.highlight_terms[i] = normalizer.normalize(csgInfo.highlight_terms[i]);
			csgInfo.highlights_chain->import(csgInfo.highlight_terms[i]);
		}
	}
	if (csgInfo.background_terms.size() > 0) {
		PRINTB("Compiling backgrounds (%i CSG Trees)...",csgInfo.background_terms.size() );
		csgInfo.background_chain = new CSGChain();
		for (unsigned int i = 0; i < csgInfo.background_terms.size(); i++) {
			csgInfo.background_terms[i] = normalizer.normalize(csgInfo.background_terms[i]);
			csgInfo.background_chain->import(csgInfo.background_terms[i]);
		}
	}

	Vector3d center(0,0,0);
	double radius = 1.0;

	if (csgInfo.root_chain) {
		BoundingBox bbox = csgInfo.root_chain->getBoundingBox();
		center = (bbox.min() + bbox.max()) / 2;
		radius = (bbox.max() - bbox.min()).norm() / 2;
	}

	Vector3d cameradir(1, 1, -0.5);
	Vector3d camerapos = center - radius*1.8*cameradir;
	csgInfo.glview->setCamera(camerapos, center);

	OpenCSGRenderer opencsgRenderer(csgInfo.root_chain, csgInfo.highlights_chain, csgInfo.background_chain, &csgInfo.glview->opencsg_glinfo);
	csgInfo.glview->setRenderer(&opencsgRenderer);

	OpenCSG::setContext(0);
	OpenCSG::setOption(OpenCSG::OffscreenSetting, OpenCSG::FrameBufferObject);

	csgInfo.glview->paintGL();
	csgInfo.glview->save(outfile.c_str());

	Builtins::instance(true);
}

#endif //ENABLE_OPENCSG


#ifdef ENABLE_CGAL

#include "CGAL_renderer.h"
#include "CGALRenderer.h"

void export_png_cgal( CGAL_Nef_polyhedron *root_N, std::string outfile )
{
	OffscreenView *glview=NULL;
	try {
		glview = new OffscreenView(512,512);
	} catch (int error) {
		PRINT("Can't create OpenGL OffscreenView. Exiting.\n");
		return;
	};

	assert(root_N!=NULL);
	CGALRenderer cgalRenderer(*root_N);

	BoundingBox bbox;
	if (cgalRenderer.polyhedron) {
		CGAL::Bbox_3 cgalbbox = cgalRenderer.polyhedron->bbox();
		bbox = BoundingBox(Vector3d(cgalbbox.xmin(), cgalbbox.ymin(), cgalbbox.zmin()),
		Vector3d(cgalbbox.xmax(), cgalbbox.ymax(), cgalbbox.zmax()));
	} else if (cgalRenderer.polyset) {
		bbox = cgalRenderer.polyset->getBoundingBox();
	}

	//cout << bbox.min() << "\n" << bbox.max() << "\n";


	Vector3d center = getBoundingCenter(bbox);
	double radius = getBoundingRadius(bbox);

	Vector3d cameradir(1, 1, -0.5);
	Vector3d camerapos = center - radius*2*cameradir;

	glview->setCamera(camerapos, center);
	glview->setRenderer(&cgalRenderer);
	glview->paintGL();
	glview->save(outfile.c_str());

}
#endif //ENABLE_CGAL

#endif //ENABLE_EXPORT_PNG


#ifdef ENABLE_CGAL

#include "CGAL_Nef_polyhedron.h"
#include "cgal.h"

/*!
	Saves the current 3D CGAL Nef polyhedron as STL to the given file.
	The file must be open.
 */
void export_stl(CGAL_Nef_polyhedron *root_N, std::ostream &output)
{
	CGAL::Failure_behaviour old_behaviour = CGAL::set_error_behaviour(CGAL::THROW_EXCEPTION);
	try {
		CGAL_Polyhedron P;
	  root_N->p3->convert_to_Polyhedron(P);

		typedef CGAL_Polyhedron::Vertex Vertex;
		typedef CGAL_Polyhedron::Vertex_const_iterator  VCI;
		typedef CGAL_Polyhedron::Facet_const_iterator   FCI;
		typedef CGAL_Polyhedron::Halfedge_around_facet_const_circulator HFCC;

		setlocale(LC_NUMERIC, "C"); // Ensure radix is . (not ,) in output

		output << "solid OpenSCAD_Model\n";

		for (FCI fi = P.facets_begin(); fi != P.facets_end(); ++fi) {
			HFCC hc = fi->facet_begin();
			HFCC hc_end = hc;
			Vertex v1, v2, v3;
			v1 = *VCI((hc++)->vertex());
			v3 = *VCI((hc++)->vertex());
			do {
				v2 = v3;
				v3 = *VCI((hc++)->vertex());
				double x1 = CGAL::to_double(v1.point().x());
				double y1 = CGAL::to_double(v1.point().y());
				double z1 = CGAL::to_double(v1.point().z());
				double x2 = CGAL::to_double(v2.point().x());
				double y2 = CGAL::to_double(v2.point().y());
				double z2 = CGAL::to_double(v2.point().z());
				double x3 = CGAL::to_double(v3.point().x());
				double y3 = CGAL::to_double(v3.point().y());
				double z3 = CGAL::to_double(v3.point().z());
				std::stringstream stream;
				stream << x1 << " " << y1 << " " << z1;
				std::string vs1 = stream.str();
				stream.str("");
				stream << x2 << " " << y2 << " " << z2;
				std::string vs2 = stream.str();
				stream.str("");
				stream << x3 << " " << y3 << " " << z3;
				std::string vs3 = stream.str();
				if (vs1 != vs2 && vs1 != vs3 && vs2 != vs3) {
					// The above condition ensures that there are 3 distinct vertices, but
					// they may be collinear. If they are, the unit normal is meaningless
					// so the default value of "1 0 0" can be used. If the vertices are not
					// collinear then the unit normal must be calculated from the
					// components.
					if (!CGAL::collinear(v1.point(),v2.point(),v3.point())) {
						CGAL_Polyhedron::Traits::Vector_3 normal = CGAL::normal(v1.point(),v2.point(),v3.point());
						output << "  facet normal "
									 << CGAL::sign(normal.x()) * sqrt(CGAL::to_double(normal.x()*normal.x()/normal.squared_length()))
									 << " "
									 << CGAL::sign(normal.y()) * sqrt(CGAL::to_double(normal.y()*normal.y()/normal.squared_length()))
									 << " "
									 << CGAL::sign(normal.z()) * sqrt(CGAL::to_double(normal.z()*normal.z()/normal.squared_length()))
									 << "\n";
					}
					else output << "  facet normal 1 0 0\n";
					output << "    outer loop\n";
					output << "      vertex " << vs1 << "\n";
					output << "      vertex " << vs2 << "\n";
					output << "      vertex " << vs3 << "\n";
					output << "    endloop\n";
					output << "  endfacet\n";
				}
			} while (hc != hc_end);
		}
		output << "endsolid OpenSCAD_Model\n";
		setlocale(LC_NUMERIC, "");      // Set default locale
	}
	catch (CGAL::Assertion_exception e) {
		PRINTB("CGAL error in CGAL_Nef_polyhedron3::convert_to_Polyhedron(): %s", e.what());
	}
	CGAL::set_error_behaviour(old_behaviour);
}

void export_off(CGAL_Nef_polyhedron *root_N, std::ostream &output)
{
	CGAL::Failure_behaviour old_behaviour = CGAL::set_error_behaviour(CGAL::THROW_EXCEPTION);
	try {
		CGAL_Polyhedron P;
		root_N->p3->convert_to_Polyhedron(P);
		output << P;
	}
	catch (CGAL::Assertion_exception e) {
		PRINTB("CGAL error in CGAL_Nef_polyhedron3::convert_to_Polyhedron(): %s", e.what());
	}
	CGAL::set_error_behaviour(old_behaviour);
}

/*!
	Saves the current 2D CGAL Nef polyhedron as DXF to the given absolute filename.
 */
void export_dxf(CGAL_Nef_polyhedron *root_N, std::ostream &output)
{
	setlocale(LC_NUMERIC, "C"); // Ensure radix is . (not ,) in output
	// Some importers (e.g. Inkscape) needs a BLOCKS section to be present
	output << "  0\n"
				 <<	"SECTION\n"
				 <<	"  2\n"
				 <<	"BLOCKS\n"
				 <<	"  0\n"
				 << "ENDSEC\n"
				 << "  0\n"
				 << "SECTION\n"
				 << "  2\n"
				 << "ENTITIES\n";

	DxfData *dd =root_N->convertToDxfData();
	for (size_t i=0; i<dd->paths.size(); i++)
	{
		for (size_t j=1; j<dd->paths[i].indices.size(); j++) {
			const Vector2d &p1 = dd->points[dd->paths[i].indices[j-1]];
			const Vector2d &p2 = dd->points[dd->paths[i].indices[j]];
			double x1 = p1[0];
			double y1 = p1[1];
			double x2 = p2[0];
			double y2 = p2[1];
			output << "  0\n"
						 << "LINE\n";
			// Some importers (e.g. Inkscape) needs a layer to be specified
			output << "  8\n"
						 << "0\n"
						 << " 10\n"
						 << x1 << "\n"
						 << " 11\n"
						 << x2 << "\n"
						 << " 20\n"
						 << y1 << "\n"
						 << " 21\n"
						 << y2 << "\n";
		}
	}

	output << "  0\n"
				 << "ENDSEC\n";

	// Some importers (e.g. Inkscape) needs an OBJECTS section with a DICTIONARY entry
	output << "  0\n"
				 << "SECTION\n"
				 << "  2\n"
				 << "OBJECTS\n"
				 << "  0\n"
				 << "DICTIONARY\n"
				 << "  0\n"
				 << "ENDSEC\n";

	output << "  0\n"
				 <<"EOF\n";

	delete dd;
	setlocale(LC_NUMERIC, "");      // Set default locale
}

#endif

#ifdef DEBUG
#include <boost/foreach.hpp>
void export_stl(const PolySet &ps, std::ostream &output)
{
	output << "solid OpenSCAD_PolySet\n";
	BOOST_FOREACH(const PolySet::Polygon &p, ps.polygons) {
		output << "facet\n";
		output << "outer loop\n";
		BOOST_FOREACH(const Vector3d &v, p) {
			output << "vertex " << v[0] << " " << v[1] << " " << v[2] << "\n";
		}
		output << "endloop\n";
		output << "endfacet\n";
	}
	output << "endsolid OpenSCAD_PolySet\n";
}
#endif
