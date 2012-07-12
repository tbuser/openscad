#ifndef PARSERSETTINGS_H_
#define PARSERSETTINGS_H_

#include <string>
#include "module.h"

extern int parser_error_pos;

void parser_init(const std::string &applicationpath);
void add_librarydir(const std::string &libdir);
std::string locate_file(const std::string &filename);
Module *parsefile( std::string filename, std::string parentpath,std::string cmdline_commands );
Module *parse(const char *text, const char *path, int debug);

#endif
