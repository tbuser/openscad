#ifndef SYSTEMGL_H_
#define SYSTEMGL_H_

#define SHADERINFO_COUNT 11

#include <GL/glew.h>
#include <string>

std::string glew_dump(bool dumpall=false);
bool report_glerror(const char *task);

#endif
