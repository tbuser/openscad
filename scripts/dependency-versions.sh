# use the sytem package manager to figure out which versions of
# binary dependencies are installed and which are available.
#
# dependencies can be executable programs, like flex and
# bison, or they can be binary packages, like CGAL.
#
# 'custom installed' dependencies created without the package system
# are not considered here.
#
# design
# correct output is more important than speed or elegance (in this script)
#

DEBUG=

debug()
{
  if [ $DEBUG ]; then echo dependency-versions.sh: $* ; fi
}

set_default_package_map()
{
  glew=glew
  boost=boost
  eigen=eigen3
  imagemagick=imagemagick
  make=make
  python=python
  opencsg=opencsg
  cgal=cgal
  bison=bison
  gmp=gmp
  mpfr=mpfr
  bash=bash
  flex=flex
  gcc=gcc
  cmake=cmake
  curl=curl
  git=git
  qt4=qt4
}


debian_dep_ver()
{
  debian_dep_ver_result=
  pkgname=$1
  veri=none
  vera=none

  # translate pkgname to debian packagename
  set_default_package_map
  for pn in cgal boost mpfr opencsg qt4; do eval $pn="lib"$pn"-dev" ; done
  # handle multiple version names of same package (ubuntu, debian, etc)
  if [ $pkgname = glew ]; then
    glewtest=`apt-cache search libglew-dev`
    if [ "`echo $glewtest | grep glew1.6-dev`" ]; then glew=libglew1.6-dev;
    elif [ "`echo $glewtest | grep glew1.5-dev`" ]; then glew=libglew1.5-dev;
    elif [ "`echo $glewtest | grep glew-dev`" ]; then glew=libglew-dev; fi
  elif [ $pkgname = eigen ]; then
    if [ "`apt-cache search libeigen2-dev`" ]; then eigen=libeigen2-dev ;fi
    if [ "`apt-cache search libeigen3-dev`" ]; then eigen=libeigen3-dev ;fi
  elif [ $pkgname = gmp ]; then
    if [ "`apt-cache search libgmp3-dev`" ]; then gmp=libgmp3-dev ;fi
    if [ "`apt-cache search libgmp-dev`" ]; then gmp=libgmp-dev ;fi
  fi

  debpkgname=`eval echo "$"$pkgname`

  if [ ! $debpkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname ".deb name:" $debpkgname
  if [ ! "`command -v apt-cache`" ]; then
    echo command apt-cache not found.
    return
  fi
  if [ ! "`command -v dpkg`" ]; then
    echo command dpkg not found.    return
  fi

  # Already installed
  # examples of debian version strings
  # cgal 4.0-4   gmp 2:5.0.5+dfsg  bison 1:2.5.dfsg-2.1 cmake 2.8.9~rc1
  debug "test dpkg on $debpkgname"
  testdpkg=`dpkg --status $debpkgname 2>&1`
  if [ "$testdpkg" ]; then
    if [ ! "`echo $testdpkg | grep not.installed`" ]; then
      ver=`dpkg --status $debpkgname | grep ^Version: | awk ' { print $2 }'`
      ver=`echo $ver | tail -1 | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
      if [ $ver ] ; then veri=$ver ; fi
    fi
  fi

  # Available to be installed
  debug "test apt-cache on $debpkgname"
  # apt-cache show is flaky on older debian. dont run unless search is OK
  test_aptcache=`apt-cache search $debpkgname`
  if [ "$test_aptcache" ]; then
    test_aptcache=`apt-cache show $debpkgname`
    if [ ! "`echo $test_aptcache | grep -i no.packages`" ]; then
      ver=`apt-cache show $debpkgname | grep ^Version: | awk ' { print $2 }'`
      ver=`echo $ver | tail -1 | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
      if [ $ver ] ; then vera=$ver ; fi
    fi
  fi

  debian_dep_ver_result="$veri $vera"
}

freebsd_dep_ver()
{
  freebsd_dep_ver_result=
  pkgname=$1
  veri=none
  vera=unknown # freebsd can't determine remote package versions??

  set_default_package_map
  boost=boost-libs
  eigen=eigen
  imagemagick=ImageMagick
  make=gmake
  qt4=qt4-corelib
  # translate pkgname to freebsd packagename
  fbsd_pkgname=`eval echo "$"$pkgname`

  if [ ! $fbsd_pkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname". freebsd name:" $fbsd_pkgname
  if [ ! "`command -v pkg_info`" ]; then
    echo command pkg_info not found.
    return
  fi
  # examples of freebsd package names
  # python-2.7,2  cmake-2.8.6_1 boost-libs-1.45.0_1
  test_pkginfo=`pkg_info | grep $fbsd_pkgname`
  if [ "$test_pkginfo" ]; then
    debug $test_pkginfo
    ver=`echo $test_pkginfo | awk '{print $1}' | sed s/"[_,].*"//`
    ver=`echo $veri | sed s/"$fbsd_pkgname"-//`
  fi
  if [ $pkgname = "gcc" ]; then
    ver=`gcc -v 2>&1 | grep -i version | awk '{print $3}'`
  fi
  if [ $ver ]; then veri=$ver; fi
  freebsd_dep_ver_result="$veri $vera"
}


fedora_dep_ver()
{
  fedora_dep_ver_result=
  pkgname=$1
  veri=none
  vera=unknown # fedora can't determine remote package versions??

  # translate pkgname to fedora packagename
  set_default_package_map
  cgal=CGAL-devel
  eigen=eigen2-devel
  qt4=qt-devel
  imagemagick=ImageMagick
  for pn in  boost gmp mpfr glew; do eval $pn=$pn"-devel" ; done
  fedora_pkgname=`eval echo "$"$pkgname`

  if [ ! $fedora_pkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname". fedora name:" $fedora_pkgname
  if [ ! "`command -v yum`" ]; then
    echo command yum not found.
    return
  fi

  test_yum=`yum info $fedora_pkgname 2>&1`
  if [ "$test_yum" ]; then
    debug $test_yum
    ver=`yum info $fedora_pkgname 2>&1 | grep ^Version | awk '{print $3}' `
    if [ $ver ]; then veri=$ver ; fi
  else
    debug test_yum failed on $pkgname
  fi
  fedora_dep_ver_result="$veri $vera"
}



dep_ver()
{
  dep_ver_result=

  if [ "`uname | grep Linux`" ]; then
    if [ "`cat /etc/issue | grep -i 'ubuntu\|debian'`" ]; then
      debian_dep_ver $*
      dep_ver_result=$debian_dep_ver_result
    elif [ "`cat /etc/issue | grep -i 'Red.Hat\|Fedora'`" ]; then
      fedora_dep_ver $*
      dep_ver_result=$fedora_dep_ver_result
    else
      echo unknown linux system. cannot proceed
      return
    fi
  elif [ "`uname | grep FreeBSD`" ]; then
    freebsd_dep_ver $*
    dep_ver_result=$freebsd_dep_ver_result
  elif [ "`command -v apt-cache`" ]; then
    echo cant determine system type. assuming debian because apt-cache exists
    debian_dep_ver $*
    dep_ver_result=$debian_dep_ver_result
  else
    echo unknown system type. cannot proceed
  fi
}


checkargs()
{
  for i in $*; do if [ $i = debug ]; then DEBUG=1 ; fi ; done
}

checkargs $*


libdeps="cgal boost mpfr gmp eigen opencsg qt4 glew"
bindeps="imagemagick flex bison gcc git curl cmake make bash python"

echo pkgname, pkginstalled, pkgavail

for i in $libdeps $bindeps; do
#for i in cmake; do
  dep_ver $i
  echo $i $dep_ver_result
done
