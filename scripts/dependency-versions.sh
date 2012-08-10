#
# called by various scripts to set versions of libraries & tools to build/use
#
# Notes:
# - MingW/MXE cross builds use their own versions, usually very new, and ignore this
# - This file doesn't do QT version, G++ version, bison version, or flex version
# - If you add a new version of CGAL, you must update the URL in the scripts
#

#
# Default settings: Newest
#
# This sets the 'maximum' version and should match README.md
#

# libraries
CGAL_VERSION=4.0.2 # note - new CGAL must also have url updated in all scripts
OPENCSG_VERSION=1.3.2
EIGEN_VERSION=2.0.17
GMP_VERSION=5.0.5
MPFR_VERSION=3.1.1
BOOST_VERSION=1.50.0
GLEW_VERSION=1.7.0

# tools
CURL_VERSION=7.26.0
CMAKE_VERSION=2.8.8
GIT_VERSION=1.7.10.3



#
# Custom settings.
#
# Good for running the test suite against versions included in Distros
#

if [ $OPENSCAD_DEP_VERSIONS = "custom" ]; then
	CGAL_VERSION=3.8
	OPENCSG_VERSION=1.3.2
	EIGEN_VERSION=2.0.17
	GMP_VERSION=5.0.5
	MPFR_VERSION=3.1.1
	BOOST_VERSION=1.47.0
	GLEW_VERSION=1.6.0
fi


#
# Lowest settings.
#
# This should match the 'minimum' listed in the README.md
#

if [ $OPENSCAD_DEP_VERSIONS = "lowest" ]; then
	CGAL_VERSION=3.6
	OPENCSG_VERSION=1.3.1
	EIGEN_VERSION=2.0.13
	GMP_VERSION=5.0.0
	MPFR_VERSION=3.0.0
	BOOST_VERSION=1.35.0
	GLEW_VERSION=1.6.0
fi

