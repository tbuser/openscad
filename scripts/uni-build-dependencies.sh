#!/bin/sh -e
#
# This script downloads, builds, and installs the main library
# dependencies needed by OpenSCAD into a path specified by the BASEDIR
# environment variable. This script works on Linux, BSD, and similar systems.
#
# This script must be run from the OpenSCAD source root directory
#
# Usage:
#  uni-build-dependencies.sh
#
#  # build only CGAL
#  uni-build-dependencies.sh cgal
#
#  # build only OpenCSG
#  uni-build-dependencies.sh opencsg
#
#
# Prerequisites:
#  wget or curl
#  Qt4
#
# Notes:
#  This is designed to be portable, with simple
#  commands, and testing on the major BSDs + Linuxes

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
    curl -kO http://git-core.googlecode.com/files/git-$version.tar.gz
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
    curl -kO http://www.cmake.org/files/v2.8/cmake-$version.tar.gz
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
    if [ "`command -v wget`" ]; then
      wget http://curl.haxx.se/download/curl-$version.tar.bz2
    elif [ "`command -v fetch`" ]; then
      fetch http://curl.haxx.se/download/curl-$version.tar.bz2
    else
      echo 'cannot find curl, wget, or fetch'
      exit
    fi
  fi
  tar xjf curl-$version.tar.bz2
  cd curl-$version
  mkdir build
  cd build
  # manual requires 'perl' to be installed. we might not have it.
  ../configure --prefix=$DEPLOYDIR --disable-manual
  make -j$NUMCPU
  make install
}

openbsd_fix_so_link()
{
  if [ "`uname | grep OpenBSD`" ]; then
    if [ ! -e $DEPLOYDIR/lib/lib$1.so ]; then
      echo "On OpenBSD and lib$1.so link not created. Attempting to fix..." 
      ln -s $DEPLOYDIR/lib/lib$1.so.[0-9].* $DEPLOYDIR/lib/lib$1.so
    fi
  fi
}

build_gmp()
{
  version=$1
  if [ -e $DEPLOYDIR/include/gmp.h ]; then
    echo "gmp already installed. not building"
    return
  fi
  echo "Building gmp" $version "..."
  cd $BASEDIR/src
  rm -rf gmp-$version
  if [ ! -f gmp-$version.tar.bz2 ]; then
    curl -kO ftp://ftp.gmplib.org/pub/gmp-$version/gmp-$version.tar.bz2
  fi
  tar xjf gmp-$version.tar.bz2
  cd gmp-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR --enable-cxx
  make
  make install
  openbsd_fix_so_link gmp
  openbsd_fix_so_link gmpxx
}

build_mpfr()
{
  if [ -e $DEPLOYDIR/include/mpfr.h ]; then
    echo "mpfr already installed. not building"
    return
  fi
  version=$1
  echo "Building mpfr" $version "..."
  cd $BASEDIR/src
  rm -rf mpfr-$version
  if [ ! -f mpfr-$version.tar.bz2 ]; then
    curl -kO http://www.mpfr.org/mpfr-$version/mpfr-$version.tar.bz2
  fi
  tar xjf mpfr-$version.tar.bz2
  cd mpfr-$version
  mkdir build
  cd build
  ../configure --prefix=$DEPLOYDIR --with-gmp=$DEPLOYDIR
  make 
  make install
  openbsd_fix_so_link mpfr
  cd ..
}

build_boost()
{
  if [ -e $DEPLOYDIR/include/boost ]; then
    echo "boost already installed. not building"
    return
  fi
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
  # We only need certain portions of boost
  ./bootstrap.sh --prefix=$DEPLOYDIR --with-libraries=thread,program_options,filesystem,system,regex
  if [ -e "./bjam" ]; then BUILDER=./bjam; fi
  if [ -e "./b2" ]; then BUILDER=./b2; fi

  BJAM_FEATURES=
  if [ "`uname | grep OpenBSD`" ]; then
    BJAM_FEATURES='cxxflags=-D__STDC_LIMIT_MACROS'
  fi

  if [ $CXX ]; then
    if [ $CXX = "clang++" ]; then
      ./$BUILDER -j$NUMCPU toolset=clang $BJAM_FEATURES
      # ./b2 -j$NUMCPU toolset=clang cxxflags="-stdlib=libc++" linkflags="-stdlib=libc++" install
    fi
  else
    ./$BUILDER -j$NUMCPU $BJAM_FEATURES
  fi
  ./$BUILDER install
}

build_cgal()
{
  if [ -e $DEPLOYDIR/include/CGAL/version.h ]; then
    echo "CGAL already installed. not building"
    return
  fi
  version=$1
  echo "Building CGAL" $version "..."
  cd $BASEDIR/src
  rm -rf CGAL-$version
  if [ ! -f CGAL-$version.tar.gz ]; then
    if [ $version = 4.0.2 ]; then
      curl -kO https://gforge.inria.fr/frs/download.php/31174/CGAL-$version.tar.gz
    elif [ $version = 4.0 ];  then
      curl -kO https://gforge.inria.fr/frs/download.php/30387/CGAL-$version.tar.gz
    elif [ $version = 3.9 ];  then
      curl -kO https://gforge.inria.fr/frs/download.php/29125/CGAL-$version.tar.gz
    elif [ $version = 3.8 ];  then
      curl -kO https://gforge.inria.fr/frs/download.php/28500/CGAL-$version.tar.gz
    elif [ $version = 3.7 ];  then
      curl -kO https://gforge.inria.fr/frs/download.php/27641/CGAL-$version.tar.gz
    else
      echo unknown CGAL version $version . please edit script
      exit
    fi
  fi
  tar zxf CGAL-$version.tar.gz
  cd $BASEDIR/src/CGAL-$version

  if [ "`uname -a | grep NetBSD.*amd64`" ]; then
    echo patching CGAL FPU.h for netbsd amd64
    cd $BASEDIR/src/CGAL-$version/include/CGAL
    patch < $OPENSCADDIR/patches/CGAL-NetBSD-FPU-amd64.patch
    cd $BASEDIR/src/CGAL-$version
  fi

  mkdir build
  cd build
  CMAKEOPTS="-DCMAKE_INSTALL_PREFIX=$DEPLOYDIR -DGMP_INCLUDE_DIR=$DEPLOYDIR/include -DGMP_LIBRARIES=$DEPLOYDIR/lib/libgmp.so -DGMPXX_LIBRARIES=$DEPLOYDIR/lib/libgmpxx.so -DGMPXX_INCLUDE_DIR=$DEPLOYDIR/include -DMPFR_INCLUDE_DIR=$DEPLOYDIR/include -DMPFR_LIBRARIES=$DEPLOYDIR/lib/libmpfr.so -DWITH_CGAL_Qt3=OFF -DWITH_CGAL_Qt4=OFF -DWITH_CGAL_ImageIO=OFF -DBOOST_ROOT=$DEPLOYDIR -DCMAKE_BUILD_TYPE=Debug"
  if [ $2 ]; then
    if [ $2 = use-sys-libs ]; then
      CMAKEOPTS="-DCMAKE_INSTALL_PREFIX=$DEPLOYDIR -DWITH_CGAL_Qt3=OFF -DWITH_CGAL_Qt4=OFF -DWITH_CGAL_ImageIO=OFF -DCMAKE_BUILD_TYPE=Debug"
    fi
  fi
  cmake $CMAKEOPTS ..
  make -j$NUMCPU
  make install
}

build_glew()
{
  if [ -e $DEPLOYDIR/include/GL/glew.h ]; then
    echo "glew already installed. not building"
    return
  fi
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
    echo "modifying glew makefile for 64 bit machine"
    if [ -e /usr/lib64/libXmu.so.6 ]; then ADD_SO=.6; else ADD_SO= ; fi
    sed -ibak s/"\-lXmu"/"\-L\/usr\/lib64\/libXmu.so$ADD_SO"/ config/Makefile.linux
  fi

  MAKER=make
  if [ "`uname | grep BSD`" ]; then
    if [ "`command -v gmake`" ]; then
      MAKER=gmake
    else
      echo "building glew on BSD requires gmake (gnu make)"
      exit
    fi
  fi

  GLEW_DEST=$DEPLOYDIR $MAKER -j$NUMCPU
  GLEW_DEST=$DEPLOYDIR $MAKER install
}

build_opencsg()
{
  if [ -e $DEPLOYDIR/include/opencsg.h ]; then
    echo "OpenCSG already installed. not building"
    return
  fi
  version=$1
  echo "Building OpenCSG" $version "..."
  cd $BASEDIR/src
  rm -rf OpenCSG-$version
  if [ ! -f OpenCSG-$version.tar.gz ]; then
    curl -kO http://www.opencsg.org/OpenCSG-$version.tar.gz
  fi
  tar xzf OpenCSG-$version.tar.gz
  cd OpenCSG-$version
  cp opencsg.pro opencsg.pro.bak
  cat opencsg.pro.bak | sed s/example// > opencsg.pro

  if [ "`command -v qmake-qt4`" ]; then
    OPENCSG_QMAKE=qmake-qt4
  elif [ "`command -v qmake4`" ]; then
    OPENCSG_QMAKE=qmake4
  else
    OPENCSG_QMAKE=qmake
  fi

  # manually rebuild the src/Makefile (some systems don't auto-rebuild it)
  cd $BASEDIR/src/OpenCSG-$version/src
  $OPENCSG_QMAKE

  cd $BASEDIR/src/OpenCSG-$version
  $OPENCSG_QMAKE
  make

  ls lib/* include/*
  echo "installing to -->" $DEPLOYDIR
  mkdir -p $DEPLOYDIR/lib
  mkdir -p $DEPLOYDIR/include
  install lib/* $DEPLOYDIR/lib
  install include/* $DEPLOYDIR/include

  openbsd_fix_so_link opencsg

  cd $OPENSCADDIR
}

build_eigen()
{
  version=$1
  if [ -e $DEPLOYDIR/include/eigen2 ]; then
    if [ `echo $version | grep 2....` ]; then
      echo "Eigen2 already installed. not building"
      return
    fi
  fi
  if [ -e $DEPLOYDIR/include/eigen3 ]; then
    if [ `echo $version | grep 3....` ]; then
      echo "Eigen3 already installed. not building"
      return
    fi
  fi
  echo "Building eigen" $version "..."
  cd $BASEDIR/src
  rm -rf eigen-$version
  EIGENDIR="none"
  if [ $version = "2.0.17" ]; then EIGENDIR=eigen-eigen-b23437e61a07; fi
  if [ $version = "3.1.1" ]; then EIGENDIR=eigen-eigen-43d9075b23ef; fi
  if [ $EIGENDIR = "none" ]; then
    echo Unknown eigen version. Please edit script.
    exit 1
  fi
  rm -rf ./$EIGENDIR
  if [ ! -f eigen-$version.tar.bz2 ]; then
    curl -kLO http://bitbucket.org/eigen/eigen/get/$version.tar.bz2
    mv $version.tar.bz2 eigen-$version.tar.bz2
  fi
  tar xjf eigen-$version.tar.bz2
  ln -s ./$EIGENDIR eigen-$version
  cd eigen-$version
  mkdir build
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=$DEPLOYDIR -DEIGEN_TEST_NO_OPENGL=1 ..
  make -j$NUMCPU
  make install
}


OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi

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
	build_curl 7.26.0
fi

# Singly build OpenCSG. Most systems won't have it, so we make a special
# case here to ease installation on those systems. 
if [ $1 ]; then
  if [ $1 = "opencsg" ]; then
    build_opencsg 1.3.2
    exit
  fi
fi

# NB! For cmake, also update the actual download URL in the function
if [ ! "`command -v cmake`" ]; then
	build_cmake 2.8.8
fi
if [ "`cmake --version | grep 'version 2.[1-6][^0-9]'`" ]; then
	build_cmake 2.8.8
fi

# build_git 1.7.10.3

# Singly build CGAL (Some systems lack an updated CGAL. This eases building)
# (They can be built singly here by passing a command line arg to the script)
if [ $1 ]; then
  if [ $1 = "cgal" ]; then
    build_cgal 4.0.2 use-sys-libs
    exit
  fi
fi


#
# Main build of libraries
# edit version numbers here as needed.
#

build_eigen 3.1.1
build_gmp 5.0.5
build_mpfr 3.1.1
build_boost 1.47.0
# NB! For CGAL, also update the actual download URL in the function
build_cgal 3.9
build_glew 1.8.0
build_opencsg 1.3.2

echo "OpenSCAD dependencies built and installed to " $BASEDIR
