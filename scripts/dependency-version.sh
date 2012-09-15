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

header_ver()
{
  path=$1
  dep=$2
  header_ver_result=
  if [ ! $1 ]; then return; fi
  if [ ! $2 ]; then return; fi
  debug header_ver: $path $dep
  if [ $dep = eigen ]; then
    debug eigen
    eigpath=
    eig3path=$path/eigen3/Eigen/src/Core/util/Macros.h
    eig2path=$path/eigen2/Eigen/src/Core/util/Macros.h
    if [ -e $eig3path ]; then eigpath=$eig3path; fi
    if [ -e $eig2path ]; then eigpath=$eig2path; fi
    debug $eig2path
    if [ ! $eigpath ]; then return; fi
    wrld=`grep "define  *EIGEN_WORLD_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    maj=`grep "define  *EIGEN_MAJOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    min=`grep "define  *EIGEN_MINOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
    header_ver_result="$wrld.$maj.$min"
  fi
  if [ $dep = opencsg ]; then
    if [ ! -e $path/opencsg.h ]; then return; fi
    hex=`grep "define  *OPENCSG_VERSION  *[0-9x]*" $path/opencsg.h`
    if [ ! $hex ]; then hex="0x0000" ; fi  # before 1.3.2 there's no vers num
    header_ver_result=$hex
  fi
  if [ $dep = cgal ]; then
    if [ ! -e $path/CGAL/version.h ]; then return; fi
    ver=`grep "define  *CGAL_VERSION  *[0-9.]*" $path/CGAL/version.h | awk '{print $3}'`
    header_ver_result=$ver
  fi
}

dep_ver()
{
  dep_ver_result=
  find_header=true
  if [ $find_header ]; then
    debug finding header $*
    if [ "`uname | grep Linux`" ]; then
      header_ver /usr/include $*
    elif [ "`uname | grep -i 'FreeBSD\|OpenBSD'`" ]; then
      header_ver /usr/local/include $*
    elif [ "`uname | grep -i NetBSD`" ]; then
      header_ver /usr/pkg/include $*
    else
      echo unknown system type. assuming prefix is /usr/include
      header_ver /usr/include $*
    fi
  else
    bin_ver $i
  fi
  dep_ver_result=$header_ver_result
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
