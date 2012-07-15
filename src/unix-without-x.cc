// unix-without-x.cc copyright 2012 don bright. released under the GPL 2 or
// later as described in the file named 'COPYING' in OpenSCAD's project root.

/*

Convenience routine for running OpenSCAD on Unix systems where no normal
X server is available (for example, over an ssh link).

Note: xvfb-run is a bash script that comes with the xorg server (xvfb debian
 linux package).

*/

#include <boost/algorithm/string/join.hpp>
#include <boost/algorithm/string.hpp>
#include <sstream>
#include <string>
#include <iostream>
#include <vector>
#include <stdio.h>

int restart_under_virtual_x_server( int argc, char **argv, int width, int height, int bpp)
{
	int result = -1;
#if not defined(__APPLE__) && not defined (__WIN32__)

	std::string logfile = "openscad.virtualx.log";
	std::cerr << "logging xvfb-run output to ./" << logfile <<"\n";
	remove( logfile.c_str() );

	std::stringstream geom; geom << width << "x" << height << "x" << bpp;
	std::vector<std::string> cmd;
	//cmd.push_back("echo"); // debugging
	cmd.push_back("xvfb-run");
	cmd.push_back("--auto-servernum" );
	cmd.push_back("--server-args=-screen 0 " + geom.str() + "" );
	cmd.push_back("--error-file="+logfile);
	//cmd.push_back("glxinfo"); // debugging
	for (int i=0;i<argc;i++) cmd.push_back( argv[i] );
	cmd.push_back("--virtualx-started");

	std::string commandline = boost::algorithm::join( cmd, " " );
	std::cerr << "running the following command: " << commandline << "\n";

	std::vector<const char*> chunks( cmd.size()+2, NULL );
	for(int i =0; i<cmd.size(); i++) chunks[i] = cmd[i].c_str() ;

	//for (int i=0;i<chunks.size();i++) debug << i << ":"<<chunks[i] << "\n";
	//debug << "\n";

	result = execvp( chunks[0], const_cast<char* const*>(&chunks[0]) );

	if (result<0) {
		std::cerr << "\nUnable to execute xvfb-run. Please try to install xvfb-run\n"
			<< "on your system. If that is not possible please try to run a virtual\n"
			<< "X server manually, such as Xvfb or Xvnc. An example follows:\n"
			<< "\n"
			<< "Xvfb :5 -screen 0 800x600x24 &> xlog &\n"
			<< "DISPLAY=:5 ./openscad -o out.png ./examples/example004.scad\n"
			<< "killall Xvfb\n\n";
	}

#endif // not defined(__APPLE__) && not defined (__WIN32__)

	return result;
}


/*
int main( int argc, char**argv) {
	for (int i=0;i<argc;i++) if(std::string(argv[i])=="--virtualx-started") return 0;
	restart_under_virtual_x_server( argc, argv, 800, 600, 24 );
}
*/

