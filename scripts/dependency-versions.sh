# use the sytem package manager to figure out which versions of
# binary dependencies are installed and which are available.
#
# dependencies can be executable programs, like flex and
# bison, or they can be binary packages, like CGAL.
#
# 'custom installed' dependencies created without the package system
# are not considered here.
#
# usage
#  dependency-versions.sh                # run
#  dependency-versions.sh debug          # debug run
#
# design
#  speed and elegance have been traded-off for an attempt at correctness
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
  ver=

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
    echo command apt-cache not found. cannot proceed.
    return
  fi
  if [ ! "`command -v dpkg`" ]; then
    echo command dpkg not found. cannot proceed.
    return
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
  ver=
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
  vera=unknown # freebsd can't easily + reliably determine remote package versions
  ver=

  # translate pkgname to freebsd packagename
  set_default_package_map
  boost=boost-libs
  eigen=eigen
  imagemagick=ImageMagick
  make=gmake
  qt4=qt4-corelib
  freebsd_pkgname=`eval echo "$"$pkgname`

  if [ ! $freebsd_pkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname". freebsd name:" $freebsd_pkgname
  if [ ! "`command -v pkg_info`" ]; then
    echo command pkg_info not found. cannot proceed.
    return
  fi
  # examples of freebsd package names
  # python-2.7,2  cmake-2.8.6_1 boost-libs-1.45.0_1
  test_pkginfo=`pkg_info | grep $freebsd_pkgname`
  if [ "$test_pkginfo" ]; then
    debug $test_pkginfo
    ver=`echo $test_pkginfo | awk '{print $1}' | sed s/"[_,].*"//`
    ver=`echo $ver | sed s/"$freebsd_pkgname"-//`
  fi
  if [ $pkgname = "gcc" ]; then
    ver=`gcc -v 2>&1 | grep -i version | awk '{print $3}'`
  fi
  if [ $ver ]; then veri=$ver; fi
  freebsd_dep_ver_result="$veri $vera"
}

openbsd_dep_ver()
{
  openbsd_dep_ver_result=
  pkgname=$1
  veri=none
  vera=unknown # openbsd can't easily + reliably determine remote package versions
  ver=

  # translate pkgname to openbsd packagename
  set_default_package_map
  eigen=eigen2
  imagemagick=ImageMagick
  make=gmake
  openbsd_pkgname=`eval echo "$"$pkgname`

  if [ ! $openbsd_pkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname". openbsd name:" $openbsd_pkgname
  if [ ! "`command -v pkg_info`" ]; then
    echo command pkg_info not found. cannot proceed.
    return
  fi

  # Installed
  # examples of openbsd package names
  # python-2.7  cmake-2.8.6p2 boost-libs-1.45.0p0
  test_pkginfo=`pkg_info -A | grep $openbsd_pkgname`
  if [ "$test_pkginfo" ]; then
    debug $test_pkginfo
    ver=`echo $test_pkginfo | awk '{print $1}' `
    ver=`echo $ver | sed s/"$openbsd_pkgname"-// | sed s/p[0-9]*//`
    if [ $ver ]; then veri=$ver; fi
  fi
  if [ $pkgname = "gcc" ]; then
    ver=`gcc -v 2>&1 | grep -i version | awk '{print $3}'`
    if [ $ver ]; then veri=$ver; fi
  fi

  openbsd_dep_ver_result="$veri $vera"
}


netbsd_dep_ver()
{
  netbsd_dep_ver_result=
  pkgname=$1
  veri=none
  vera=none
  ver=

  # translate pkgname to netbsd packagename
  set_default_package_map
  imagemagick=ImageMagick
  boost=boost-libs
  python=python27
  eigen=eigen
  make=gmake
  git=scmgit
  netbsd_pkgname=`eval echo "$"$pkgname`

  if [ ! $netbsd_pkgname ]; then echo "unknown package" $pkgname; return; fi

  debug $pkgname". netbsd name:" $netbsd_pkgname
  if [ ! "`command -v pkgin`" ]; then
    echo command pkgin not found. cannot proceed.
    return
  fi

  # Installed
  # examples of netbsd package names
  # zsh-4.3.15nb1
  test_pkgin=`pkgin list | grep $netbsd_pkgname`
  if [ "$test_pkgin" ]; then
    debug installed check - $test_pkgin
    ver=`pkgin list $netbsd_pkgname | grep "$netbsd_pkgname" | tail -1`
    debug strip 1 $ver
    ver=`echo $ver | awk '{print $1}' | sed s/.*-// | sed s/nb[0-9]*//`
    debug strip 2 $ver
    if [ $ver ]; then veri=$ver; fi
  fi
  if [ $pkgname = "gcc" ]; then
    ver=`gcc -v 2>&1 | grep -i version | awk '{print $3}'`
    if [ $ver ]; then veri=$ver; fi
    vera=unknown
  fi

  # Available
  ver=
  test_pkgin=`pkgin pkg-descr $netbsd_pkgname 2>&1 | grep -i ^information`
  # make ftp://netbsd.org/etc/etc/etc/package-x.y.z.tgz into x.y.z
  if [ "$test_pkgin" ]; then
    debug available check $test_pkgin
    ver=`echo $test_pkgin | awk '{print $3}' | tail -1`
    debug stripped $ver
    ver=`basename $ver | sed s/"^.*-"// | sed s/://`
    debug basename $ver
    ver=`echo $ver | sed s/.tgz$// | sed s/.bz2$// | sed s/.xz$//`
    ver=`echo $ver | sed s/nb[0-9]*//`
    debug strip2 $ver
  fi
  if [ $ver ]; then vera=$ver; fi

  netbsd_dep_ver_result="$veri $vera"
}



fedora_dep_ver()
{
  fedora_dep_ver_result=
  pkgname=$1
  veri=none
  vera=unknown # fedora can't easily + reliably determine remote package versions
  ver=

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
    echo command yum not found. cannot proceed.
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
  elif [ "`uname | grep NetBSD`" ]; then
    netbsd_dep_ver $*
    dep_ver_result=$netbsd_dep_ver_result
  elif [ "`uname | grep OpenBSD`" ]; then
    openbsd_dep_ver $*
    dep_ver_result=$openbsd_dep_ver_result
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
