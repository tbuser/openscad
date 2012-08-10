#!/bin/sh -e
#
# This script builds all library dependencies of OpenSCAD for Linux
#
# This script must be run from the OpenSCAD source root directory
#
# Usage: linux-build-dependencies.sh
#
# Prerequisites:
# - wget or curl
# - Qt4
#

printUsage()
{
  echo "Usage: $0"
  echo
}

build_git()
{
  version=$1
  echo "Building git" $version "..."
  cd $BASEDIR/src
  rm -rf git-$version
  if [ ! -f git-$version.tar.gz ]; then
    curl -O http://git-core.googlecode.com/files/git-$version.tar.gz
  fi
  tar zxf git-$version.tar.gz
  cd git-$version
  ./configure --prefix=$DEPLOYDIR
  make -j$NUMCPU
  make install
}

build_cmake()
{
  version=$1
  echo "Building cmake" $version "..."
  cd $BASEDIR/src
  rm -rf cmake-$version
  if [ ! -f cmake-$version.tar.gz ]; then
    curl -O http://www.cmake.org/files/v2.8/cmake-$version.tar.gz
  fi
  tar zxf cmake-$version.tar.gz
  cd cmake-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR
  make -j$NUMCPU
  make install
}

build_curl()
{
  version=$1
  echo "Building curl" $version "..."
  cd $BASEDIR/src
  rm -rf curl-$version
  if [ ! -f curl-$version.tar.bz2 ]; then
    wget http://curl.haxx.se/download/curl-$version.tar.bz2
  fi
  tar xjf curl-$version.tar.bz2
  cd curl-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR
  make -j$NUMCPU
  make install
}

build_gmp()
{
  version=$1
  echo "Building gmp" $version "..."
  cd $BASEDIR/src
  rm -rf gmp-$version
  if [ ! -f gmp-$version.tar.bz2 ]; then
    curl -O ftp://ftp.gmplib.org/pub/gmp-$version/gmp-$version.tar.bz2
  fi
  tar xjf gmp-$version.tar.bz2
  cd gmp-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR --enable-cxx
  make install
}

build_mpfr()
{
  version=$1
  echo "Building mpfr" $version "..."
  cd $BASEDIR/src
  rm -rf mpfr-$version
  if [ ! -f mpfr-$version.tar.bz2 ]; then
    curl -O http://www.mpfr.org/mpfr-$version/mpfr-$version.tar.bz2
  fi
  tar xjf mpfr-$version.tar.bz2
  cd mpfr-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR --with-gmp=$DEPLOYDIR
  make install
  cd ..
}

build_boost_without_bootstrap()
{
  # older versions of boost dont have it
  ./configure --prefix=$DEPLOYDIR --with-libraries=thread,program_options,filesystem,system,regex
  make -j$NUMCPU
  make install
  return
}

build_boost_with_bootstrap()
{
  # newer versions of boost have a 'bootstrap' script
  # We only need certain portions of boost
  ./bootstrap.sh --prefix=$DEPLOYDIR --with-libraries=thread,program_options,filesystem,system,regex
  BJAM_EXEC=./bjam
  if [ -e ./b2 ]; then
    BJAM_EXEC=./b2
  fi
	if [ $CXX ]; then
		if [ $CXX = "clang" ]; then
		  $BJAM_EXEC -j$NUMCPU toolset=clang install
		  # ./b2 -j$NUMCPU toolset=clang cxxflags="-stdlib=libc++" linkflags="-stdlib=libc++" install
		fi
	else
	  $BJAM_EXEC -j$NUMCPU
	  $BJAM_EXEC install
	fi
  return
}

build_boost()
{
  version=$1
  bversion=`echo $version | tr "." "_"`
  echo "Building boost" $version "..."
  cd $BASEDIR/src
  rm -rf boost_$bversion
  if [ ! -f boost_$bversion.tar.bz2 ]; then
    curl -LO http://downloads.sourceforge.net/project/boost/boost/$version/boost_$bversion.tar.bz2
  fi
  tar xjf boost_$bversion.tar.bz2
  cd boost_$bversion
  case $version in
    1.3[5-6].*)
      if [ "`gcc --verbose 2>&1 | grep 'version 4.4' `" ]; then
        # https://svn.boost.org/trac/boost/ticket/2069
        echo boost version $version not compatible with `gcc --verbose 2>&1 | grep 'version 4.4' `
        echo please use a newer version of boost or gcc
        exit 1
      else
        build_boost_without_bootstrap
      fi
      ;;
    1.3[7-8].*)
      build_boost_without_bootstrap
      ;;
    *)
      build_boost_with_bootstrap
      ;;
  esac
}

build_cgal()
{
  version=$1
  echo "Building CGAL" $version "..."
  cd $BASEDIR/src
  rm -rf CGAL-$version
  if [ ! -f CGAL-$version.tar.gz ]; then
    if [ $version = "4.0.2" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/31174/CGAL-$version.tar.gz
    elif [ $version = "4.0" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/30387/CGAL-$version.tar.gz
    elif [ $version = "3.9" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/29125/CGAL-$version.tar.gz
    elif [ $version = "3.8" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/28500/CGAL-$version.tar.gz
    elif [ $version = "3.7" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/27641/CGAL-$version.tar.gz
    elif [ $version = "3.6" ]; then
      curl -O https://gforge.inria.fr/frs/download.php/26688/CGAL-$version.tar.gz
    fi
  fi
  tar xf CGAL-$version.tar.gz
  cd CGAL-$version
  cmake -DCMAKE_INSTALL_PREFIX=$DEPLOYDIR -DGMP_INCLUDE_DIR=$DEPLOYDIR/include -DGMP_LIBRARIES=$DEPLOYDIR/lib/libgmp.so -DGMPXX_LIBRARIES=$DEPLOYDIR/lib/libgmpxx.so -DGMPXX_INCLUDE_DIR=$DEPLOYDIR/include -DMPFR_INCLUDE_DIR=$DEPLOYDIR/include -DMPFR_LIBRARIES=$DEPLOYDIR/lib/libmpfr.so -DWITH_CGAL_Qt3=OFF -DWITH_CGAL_Qt4=OFF -DWITH_CGAL_ImageIO=OFF -DBOOST_ROOT=$DEPLOYDIR -DCMAKE_BUILD_TYPE=Debug
  make -j$NUMCPU
  make install
}

build_glew()
{
  version=$1
  echo "Building GLEW" $version "..."
  cd $BASEDIR/src
  rm -rf glew-$version
  if [ ! -f glew-$version.tgz ]; then
    curl -LO http://downloads.sourceforge.net/project/glew/glew/$version/glew-$version.tgz
  fi
  tar xzf glew-$version.tgz
  cd glew-$version
  mkdir -p $DEPLOYDIR/lib/pkgconfig

  # Fedora 64-bit
	if [ -e /usr/lib64 ]; then
	  if [ "`ls /usr/lib64 | grep Xmu`" ]; then
	    echo "modifying glew makefile for 64 bit machine"
	    sed -ibak s/"\-lXmu"/"\-L\/usr\/lib64\/libXmu.so.6"/ config/Makefile.linux
	  fi
	fi

	if [ $CC ]; then
		if [ $CC = "clang" ]; then
			echo "modifying glew makefile for clang"
			sed -i s/\$\(CC\)/clang/ Makefile
		fi
	fi

	GLEW_DEST=$DEPLOYDIR make -j$NUMCPU
  GLEW_DEST=$DEPLOYDIR make install
}

build_opencsg()
{
  version=$1
  echo "Building OpenCSG" $version "..."
  cd $BASEDIR/src
  rm -rf OpenCSG-$version
  if [ ! -f OpenCSG-$version.tar.gz ]; then
    curl -O http://www.opencsg.org/OpenCSG-$version.tar.gz
  fi
  tar xzf OpenCSG-$version.tar.gz
  cd OpenCSG-$version
  sed -ibak s/example// opencsg.pro # examples might be broken without GLUT

  # Fedora 64-bit
	if [ -e /usr/lib64 ]; then
	  if [ "`ls /usr/lib64 | grep Xmu`" ]; then
	    echo "modifying opencsg makefile for 64 bit machine"
	    sed -ibak s/"\-lXmu"/"\-L\/usr\/lib64\/libXmu.so.6"/ src/Makefile 
	  fi
	fi

  if [ `uname | grep FreeBSD` ]; then
    sed -ibak s/X11R6/local/g src/Makefile
   fi

  if [ "`command -v qmake-qt4`" ]; then
    OPENCSG_QMAKE=qmake-qt4
  else
    OPENCSG_QMAKE=qmake
  fi

	if [ $CXX ]; then
		if [ $CXX = "clang++" ]; then
		  cd $BASEDIR/src/OpenCSG-$version/src
			$OPENCSG_QMAKE
		  cd $BASEDIR/src/OpenCSG-$version
			$OPENCSG_QMAKE
		fi
	else
		$OPENCSG_QMAKE
	fi

  make

  cp -av lib/* $DEPLOYDIR/lib
  cp -av include/* $DEPLOYDIR/include
  cd $OPENSCADDIR
}

build_eigen()
{
  version=$1
  echo "Building eigen" $version "..."
  cd $BASEDIR/src
  rm -rf ./eigen-$version
  rm -rf ./eigen-eigen-*
  if [ ! -f eigen-$version.tar.bz2 ]; then
    curl -LO http://bitbucket.org/eigen/eigen/get/$version.tar.bz2
    mv $version.tar.bz2 eigen-$version.tar.bz2
  fi
  tar xjf eigen-$version.tar.bz2
  # attempt to portably link a path you dont know exact name of (should only do 1 loop)
  for i in eigen-eigen-*; do
    ln -s $i eigen-$version
  done
  cd eigen-$version
  cmake -DCMAKE_INSTALL_PREFIX=$DEPLOYDIR
  make -j$NUMCPU
  make install
}


OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi

# This sets other env. variables for the libraries & tools.
# '.' is equivalent to 'source' for dash shell
BASEDIR=$BASEDIR
. ./scripts/setenv-linbuild.sh

# This sets the version numbers of libraries & tools. Please edit the
# file to change version numbers.
. ./scripts/dependency-versions.sh

SRCDIR=$BASEDIR/src

if [ ! $NUMCPU ]; then
	echo "Note: The NUMCPU environment variable can be set for paralell builds"
	NUMCPU=1 
fi

if [ ! -d $BASEDIR/bin ]; then
  mkdir -p $BASEDIR/bin
fi

echo "Using basedir:" $BASEDIR
echo "Using deploydir:" $DEPLOYDIR
echo "Using srcdir:" $SRCDIR
echo "Number of CPUs for parallel builds:" $NUMCPU
mkdir -p $SRCDIR $DEPLOYDIR


if [ ! "`command -v curl`" ]; then
	build_curl $CURL_VERSION
fi

# NB! For cmake, also update the actual download URL in the function
if [ ! "`command -v cmake`" ]; then
	build_cmake $CMAKE_VERSION
fi
if [ "`cmake --version | grep 'version 2.[1-6][^0-9]'`" ]; then
	build_cmake $CMAKE_VERSION
fi

# build_git $GIT_VERSION

#
# Main build of libraries
#

build_eigen $EIGEN_VERSION
build_gmp $GMP_VERSION
build_mpfr $MPFR_VERSION
build_boost $BOOST_VERSION
# NB! For CGAL, also update the actual download URL in the function
build_cgal $CGAL_VERSION
build_glew $GLEW_VERSION
build_opencsg $OPENCSG_VERSION

echo "OpenSCAD dependencies built and installed to " $BASEDIR
