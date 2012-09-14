# figure out which versions of binary dependencies are available
# on a system. dependencies can be executable programs, like flex and
# bison, or they can be binary packages, like CGAL.

DEBUG=

debug()
{
  if [ $DEBUG ]; then echo dependency-versions.sh: $* ; fi
}


debian_dep_ver()
{
  debian_dep_ver_result=
  veri="none"
  vera="none"

  cgal=libcgal-dev
  boost=libboost-dev
  mpfr=libmpfr-dev
  gmp=libgmp-dev
  eigen=libeigen2-dev
  opencsg=libopencsg-dev
  qt=libqt4-dev

  bison=bison
  flex=flex
  imagemagick=imagemagick
  gcc=gcc
  cmake=cmake
  curl=curl
  git=git

  pkgname=`eval echo '$'$1`

  debug debian: $1 "->" $pkgname
  if [ ! "`command -v apt-cache`" ]; then
    echo command apt-cache not found.
    return
  fi
  if [ ! "`command -v dpkg`" ]; then
    echo command dpkg not found.    return
  fi
  # examples of debian version strings
  # cgal 4.0-4   gmp 2:5.0.5+dfsg  bison 1:2.5.dfsg-2.1 cmake 2.8.9~rc1
  debug "test dpkg on $pkgname"
  testdpkg=`dpkg --status $pkgname 2>&1`
  if [ "$testdpkg" ]; then
    if [ ! "`echo $testdpkg | grep not.installed`" ]; then
      ver=`dpkg --status $pkgname | grep ^Version: | awk ' { print $2 }'`
      ver=`echo $ver | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
      veri=$ver
    fi
  fi

  debug "test apt-cache on $pkgname"
  # apt-cache show is flaky on older debian. dont run unless search is OK
  test_aptcache=`apt-cache search $pkgname`
  if [ "$test_aptcache" ]; then
    test_aptcache=`apt-cache show $pkgname`
    if [ ! "`echo $test_aptcache | grep -i no.packages`" ]; then
      ver=`apt-cache show $pkgname | grep ^Version: | awk ' { print $2 }'`
      ver=`echo $ver | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
      vera=$ver
    fi
  fi

  debug vera: $vera veri: $veri
  debian_dep_ver_result="$veri $vera"
}



dep_ver()
{
  dep_ver_result=

  if [ "`cat /etc/issue | grep -i ubuntu`" ]; then
    debian_dep_ver $*
    dep_ver_result=$debian_dep_ver_result
  elif [ "`cat /etc/issue | grep -i debian`" ]; then
    debian_dep_ver $*
    dep_ver_result=$debian_dep_ver_result
  elif [ "`command -v apt-cache`" ]; then
    echo cant determine system type. assuming debian
    debian_dep_ver $*
    dep_ver_result=$debian_dep_ver_result
  fi
}


checkargs()
{
  for i in $*; do if [ $i = debug ]; then DEBUG=1 ; fi ; done
}

checkargs $*


libdeps="cgal boost mpfr gmp eigen opencsg qt"
bindeps="imagemagick flex bison gcc git curl cmake"

echo pkgname, installed, available

for i in $libdeps $bindeps; do
  dep_ver $i
  echo $i $dep_ver_result
done
