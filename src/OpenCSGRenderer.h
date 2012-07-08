#ifndef OPENCSGRENDERER_H_
#define OPENCSGRENDERER_H_

#include "renderer.h"
#include "system-gl.h"

#include <string>

#define SHADERINFO_COUNT 11

class OpenCSG_GLInfo
{
public:
	OpenCSG_GLInfo();
	bool is_opencsg_capable, has_shaders, opencsg_support;
	int opencsg_id;
	std::string glinfo;
	GLint shaderinfo[SHADERINFO_COUNT];
};

OpenCSG_GLInfo enable_opencsg_shaders();

class OpenCSGRenderer : public Renderer
{
public:
	OpenCSGRenderer(class CSGChain *root_chain, CSGChain *highlights_chain, 
									CSGChain *background_chain, OpenCSG_GLInfo *opencsg_glinfo);
	void draw(bool showfaces, bool showedges) const;
private:
	void renderCSGChain(class CSGChain *chain, GLint *shaderinfo, 
											bool highlight, bool background) const;

	CSGChain *root_chain;
	CSGChain *highlights_chain;
	CSGChain *background_chain;
	OpenCSG_GLInfo *opencsg_glinfo;
};

#endif
