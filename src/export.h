#ifndef EXPORT_H_
#define EXPORT_H_

#include <iostream>
#include <string>

#ifdef ENABLE_CGAL
#include "node.h"

void export_stl(class CGAL_Nef_polyhedron *root_N, std::ostream &output);
void export_off(CGAL_Nef_polyhedron *root_N, std::ostream &output);
void export_dxf(CGAL_Nef_polyhedron *root_N, std::ostream &output);
void export_png_cgal( CGAL_Nef_polyhedron *root_N, std::string outfile );
void export_png_opencsg( AbstractNode *absolute_root_node, std::string outfile );
#endif

#ifdef DEBUG
void export_stl(const class PolySet &ps, std::ostream &output);
#endif

#endif
