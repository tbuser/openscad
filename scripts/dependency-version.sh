# Determine which versions of dependency tools and libraries are available
# on the system.
#
# usage
#  dependency-version.sh                # check version of all dependencies
#  dependency-version.sh cgal           # check version of cgal library
#  dependency-version.sh debug          # debug this script
#
# design
#  speed has been traded-off for an attempt at correctness
#

DEBUG=

debug()
{
  if [ $DEBUG ]; then echo dependency-versions.sh: $* ; fi
}

search_ver()
{
  path=$1
  dep=$2
  search_ver_result=
  local ver=
  if [ ! $1 ]; then return; fi
  if [ ! $2 ]; then return; fi
  debug search_ver: $path $dep

  # header searches
  ipath=$path/include
  if [ $dep = eigen ]; then
    debug eigen
    eigpath=
    eig3path=$ipath/eigen3/Eigen/src/Core/util/Macros.h
    eig2path=$ipath/eigen2/Eigen/src/Core/util/Macros.h
    if [ -e $eig3path ]; then eigpath=$eig3path; fi
    if [ -e $eig2path ]; then eigpath=$eig2path; fi
    debug $eig2path
    if [ ! $eigpath ]; then return; fi
    wrld=`grep "define  *EIGEN_WORLD_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    maj=`grep "define  *EIGEN_MAJOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    min=`grep "define  *EIGEN_MINOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    ver="$wrld.$maj.$min"
  fi
  if [ $dep = opencsg ]; then
    if [ ! -e $ipath/opencsg.h ]; then return; fi
    hex=`grep "define  *OPENCSG_VERSION  *[0-9x]*" $ipath/opencsg.h`
    if [ ! $hex ]; then hex="0x0000" ; fi  # before 1.3.2 there's no vers num
    ver=$hex
  fi
  if [ $dep = cgal ]; then
    if [ ! -e $ipath/CGAL/version.h ]; then return; fi
    ver=`grep "define  *CGAL_VERSION  *[0-9.]*" $ipath/CGAL/version.h | awk '{print $3}'`
  fi
  if [ $dep = boost ]; then
    if [ ! -e $ipath/boost/version.hpp ]; then return; fi
    ver=`grep 'define  *BOOST_LIB_VERSION *[0-9_"]*' $ipath/boost/version.hpp | awk '{print $3}'`
    ver=`echo $ver | sed s/'"'//g | sed s/'_'/'.'/g`
  fi
  if [ $dep = mpfr ]; then
    mpfrpath=$ipath/mpfr.h
    if [ ! -e $mpfrpath ]; then return; fi
    ver=`grep 'define  *MPFR_VERSION_STRING  *' $mpfrpath | awk '{print $3}'`
    ver=`echo $ver | sed s/"-.*"// | sed s/'"'//`
  fi
  if [ $dep = gmp ]; then
    gmppath=$ipath/gmp.h
    if [ ! -e $gmppath ]; then return; fi
    gmpmaj=`grep "define  *__GNU_MP_VERSION  *[0-9]*" $gmppath | awk '{print $3}'`
    gmpmin=`grep "define  *__GNU_MP_VERSION_MINOR  *[0-9]*" $gmppath | awk '{print $3}'`
    gmppat=`grep "define  *__GNU_MP_VERSION_PATCHLEVEL  *[0-9]*" $gmppath | awk '{print $3}'`
    ver="$gmpmaj.$gmpmin.$gmppat"
  fi
  if [ $dep = qt4 ]; then
    qt4path=$ipath/qt4/QtCore/qglobal.h
    if [ ! -e $qt4path ]; then return; fi
    ver=`grep 'define  *QT_VERSION_STR  *' $qt4path | awk '{print $3}'`
    ver=`echo $ver | sed s/'"'//g`
  fi
  if [ $dep = glew ]; then
    ver=unknown # glew has no traditional version numbers
  fi

  # program searches
  bpath=$path/bin
  if [ $dep = imagemagick ]; then
    if [ ! -x $bpath/convert ]; then return; fi
    ver=`$bpath/convert --version | grep -i version`
    ver=`echo $ver | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
  fi
  if [ $dep = flex ]; then
    flexbin=$bpath/flex
    if [ -x $bpath/gflex ]; then flexbin=$bpath/gflex; fi # openbsd
    if [ ! -x $flexbin ]; then return ; fi
    ver=`$flexbin --version | sed s/"[^0-9.]"/" "/g`
  fi
  if [ $dep = bison ]; then
    if [ ! -x $bpath/bison ]; then return ; fi
    ver=`$bpath/bison --version | grep bison | sed s/"[^0-9.]"/" "/g`
  fi
  if [ $dep = gcc ]; then
    bingcc=$bpath/gcc
    if [ ! -x $bpath/gcc ]; then bingcc=gcc; fi
    if [ ! "`$bingcc --version`" ]; then return; fi
    ver=`$bingcc --version| grep -i gcc`
    ver=`echo $ver | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
  fi
  if [ $dep = git ]; then
    if [ ! -x $bpath/git ]; then return ; fi
    ver=`$bpath/git --version | grep git | sed s/"[^0-9.]"/" "/g`
  fi
  if [ $dep = curl ]; then
    if [ ! -x $bpath/curl ]; then return; fi
    ver=`$bpath/curl --version | grep curl | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
  fi
  if [ $dep = cmake ]; then
    if [ ! -x $bpath/cmake ]; then return ; fi
    ver=`$bpath/cmake --version | grep cmake | sed s/"[^0-9.]"/" "/g`
  fi
  if [ $dep = make ]; then
    binmake=$bpath/make
    if [ -x $bpath/gmake ]; then binmake=$bpath/gmake ;fi
    if [ ! -x $binmake ]; then return ;fi
    ver=`$binmake --version 2>&1 | grep -i 'gnu make' | sed s/"[^0-9.]"/" "/g`
    if [ ! "`echo $ver | grep [0-9]`" ]; then return; fi
  fi
  if [ $dep = bash ] ; then
    if [ ! -x $bpath/bash ]; then return; fi
    ver=`$bpath/bash --version | grep bash | sed s/"[^0-9. ]"/" "/g|awk '{print $1}'`
  fi
  if [ $dep = python ]; then
    if [ ! -x $bpath/python ]; then return; fi
    ver=`$bpath/python --version 2>&1 | awk '{print $2}'`
  fi
  search_ver_result=$ver
}

dep_ver()
{
  dep_ver_result=
  if [ "`uname | grep Linux`" ]; then
    search_ver /usr $*
  elif [ "`uname | grep -i 'FreeBSD\|OpenBSD'`" ]; then
    search_ver /usr/local $*
  elif [ "`uname | grep -i NetBSD`" ]; then
    search_ver /usr/pkg $*
  else
    echo unknown system type. assuming prefix is /usr
    search_ver /usr $*
  fi
  dep_ver_result=$search_ver_result
}

checkargs()
{
  for i in $*; do
    if [ $i = "debug" ]; then DEBUG=1 ; fi
  done
}

libdeps="cgal boost mpfr gmp eigen opencsg qt4 glew"
bindeps="imagemagick flex bison gcc git curl cmake make bash python"

checkargs $*
checklist="$libdeps $bindeps"

echo "depname, version found"
for i in $checklist; do
  dep_ver $i
  echo $i $dep_ver_result
done
