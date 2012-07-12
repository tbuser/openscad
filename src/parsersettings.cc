#include "parsersettings.h"
#include <boost/filesystem.hpp>
#include <boost/foreach.hpp>
#include "boosty.h"
#include <fstream>
#include "handle_dep.h"

namespace fs = boost::filesystem;

std::vector<std::string> librarypath;

void add_librarydir(const std::string &libdir)
{
	librarypath.push_back(libdir);
}

/*!
	Searces for the given file in library paths and returns the full path if found.
	Returns an empty path if file cannot be found.
*/
std::string locate_file(const std::string &filename)
{
	BOOST_FOREACH(const std::string &dir, librarypath) {
		fs::path usepath = fs::path(dir) / filename;
		if (fs::exists(usepath)) return usepath.string();
	}
	return std::string();
}

void parser_init(const std::string &applicationpath)
{
  // FIXME: Append paths from OPENSCADPATH before adding built-in paths

	std::string librarydir;
	fs::path libdir(applicationpath);
	fs::path tmpdir;
#ifdef __APPLE__
	libdir /= "../Resources"; // Libraries can be bundled
	if (!is_directory(libdir / "libraries")) libdir /= "../../..";
#elif not defined(_WIN32)
	if (is_directory(tmpdir = libdir / "../share/openscad/libraries")) {
		librarydir = boosty::stringy( tmpdir );
	} else if (is_directory(tmpdir = libdir / "../../share/openscad/libraries")) {
		librarydir = boosty::stringy( tmpdir );
	} else if (is_directory(tmpdir = libdir / "../../libraries")) {
		librarydir = boosty::stringy( tmpdir );
	} else
#endif
		if (is_directory(tmpdir = libdir / "libraries")) {
			librarydir = boosty::stringy( tmpdir );
		}
	if (!librarydir.empty()) add_librarydir(librarydir);
}


Module *parsefile( std::string filename, std::string parentpath, std::string cmdline_commands )
{
	handle_dep( filename );
        std::ifstream ifs( filename.c_str() );
	Module *result = NULL;
	if (!ifs.is_open()) {
		PRINTB( "Can't open input file '%s'!\n", filename.c_str());
	} else {
		std::string text((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
		text += "\n" + cmdline_commands;
		result = parse(text.c_str(), parentpath.c_str(), false);
	}
	if (result) result->handleDependencies();
	return result;
}


