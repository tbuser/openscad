# Determine which versions of dependency tools and libraries are available
# on the system.
#
# usage
#  dependency-version.sh                # check version of all dependencies
#  dependency-version.sh debug          # debug this script
#  dependency-version.sh qmake          # output for qmake & openscad.pro
#
# design
#  goal is portability and lack of complicated regex.
#  code style is 'pretend its python'. functions return strings under
#  the $function_name_result variable. tmp variables are
#  funcname_abbreviated_tmp. locals are not used for portability.
#

DEBUG=
QMAKE_MODE=

debug()
{
  if [ $DEBUG ]; then echo dependency-versions.sh: $* ; fi
}

search_ver()
{
  path=$1
  dep=$2
  search_ver_result=none
  local ver=none
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
    ver=`echo $hex | sed s/"0x"//`
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
    # on some systems you have VERSION in gmp-$arch.h not gmp.h. use gmp*.h
    gmppaths=`ls $ipath | grep ^gmp`
    if [ ! "$gmppaths" ]; then return; fi
    for gmpfile in $gmppaths; do
      gmppath=$ipath/$gmpfile
      if [ "`grep __GNU_MP_VERSION $gmppath`" ]; then
        gmpmaj=`grep "define  *__GNU_MP_VERSION  *[0-9]*" $gmppath | awk '{print $3}'`
        gmpmin=`grep "define  *__GNU_MP_VERSION_MINOR  *[0-9]*" $gmppath | awk '{print $3}'`
        gmppat=`grep "define  *__GNU_MP_VERSION_PATCHLEVEL  *[0-9]*" $gmppath | awk '{print $3}'`
      fi
    done
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
    # bash is a special case. normally we dont search elsewhere than the
    # prefix $path given, but as a shell it can be in unusual places
    if [ -x /bin/bash ]; then binbash=/bin/bash ;fi
    if [ -x /usr/bin/bash ]; then binbash=/usr/bin/bash ;fi
    if [ -x $bpath/bash ]; then binbash=$bpath/bash ;fi
    if [ ! -x $binbash ]; then return; fi
    ver=`$binbash --version | grep bash | sed s/"[^0-9. ]"/" "/g|awk '{print $1}'`
  fi
  if [ $dep = python ]; then
    if [ ! -x $bpath/python ]; then return; fi
    ver=`$bpath/python --version 2>&1 | awk '{print $2}'`
  fi
  ver=`echo $ver | sed s/"^ *"//`  # trim leading/trailing spaces
  ver=`echo $ver | sed s/" *$"//`
  search_ver_result=$ver
}


find_installed_version()
{
  find_installed_version=
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
  find_installed_version_result=$search_ver_result
}

find_installed_versions()
{
  fivdeps=$*
  fivtmp=
  find_installed_versions_result=
  for fivdep in $fivdeps; do
    find_installed_version $fivdep
    debug find_installed_versions $fivdep $fivtmp
    fivtmp="$fivtmp $dep"_instver"=$find_installed_version_result"
  done
  find_installed_versions_result=$fivtmp
}

checkargs()
{
  for i in $*; do
    if [ $i = "debug" ]; then DEBUG=1 ; fi
    if [ $i = "qmake" ]; then QMAKE_MODE=1 ; fi
  done
}

get_readme_version()
{
  if [ ! $1 ]; then return; fi
  depname=$1
  local tmp=
  debug $depname
  # example-->     * [CGAL (3.6 - 3.9)] (www.cgal.org)  becomes 3.6
  # steps: eliminate *, find left (, find -, make 'x' into 0, delete junk
  tmp=`grep -i ".$depname.*([0-9]" README.md | sed s/"*"//`
  debug $tmp
  tmp=`echo $tmp | awk -F"(" '{print $2}'`
  debug $tmp
  tmp=`echo $tmp | awk -F"-" '{print $1}'`
  debug $tmp
  tmp=`echo $tmp | sed s/"x"/"0"/g`
  debug $tmp
  tmp=`echo $tmp | sed s/"[^0-9.]"//g`
  debug $tmp
  get_readme_version_result=$tmp
}

set_min_versions()
{
  set_min_versions_result=
  smvtmp=
  for dep in $*; do
    get_readme_version $dep
    smvtmp="$smvtmp $dep"_minver"=$get_readme_version_result"
  done
  smvtmp="$smvtmp git_minver=1.5 curl_minver=6 make_minver=3"
  set_min_versions_result=$smvtmp
  smvtmp=
}

vers_to_int()
{
  # change x.y.z.p into x0y0z0p
  # it will work as long as the resulting int is less than 2.147 billion
  # and y z and p are less than 99
  # 1.2.3.4 into 1020304
  # 1.11.0.12 into 1110012
  # 2011.2.3 into 20110020300
  # the resulting integer can be simply compared using -lt or -gt
  if [ ! $1 ] ; then return ; fi
  vtoi_ver=$1
  vtoi_test=`echo $vtoi_ver | sed s/"[^0-9.]"//g`
  if [ ! "$vtoi_test" = "$vtoi_ver" ]; then
    debug failure in version-to-integer conversion.
    debug '"'$vtoi_ver'"' has letters, etc in it. setting to 0
    vtoi_ver="0"
  fi
  vers_to_int_result=`echo $vtoi_ver | awk -F. '{print $1*1000000+$2*10000+$3*100+$4}'`
  vtoi_ver=
}


version_less_than_or_equal()
{
  if [ ! $1 ]; then return; fi
  if [ ! $2 ]; then return; fi
  v1=$1
  v2=$2
  vers_to_int $v1
  v1int=$vers_to_int_result
  vers_to_int $v2
  v2int=$vers_to_int_result
  if [ $v1int -le $v2int ]; then
    debug "v1 < v2, v1int < v2int:" $v1, $v2, $v1int, $v2int
    return 0
  else
    debug "v1 >= v2, v1int < v2int:" $v1, $v2, $v1int, $v2int
    return 1
  fi
  v1=
  v2=
  v1int=
  v2int=
}

compare_versions()
{
  compare_versions_result=
  cvtmp=
  for cvdep in $*; do
    cvminver=`eval echo "$"$cvdep"_minver"`
    cvinstver=`eval echo "$"$cvdep"_instver"`
    version_less_than_or_equal $cvminver $cvinstver
    if [ $? = 0 ]; then
      debug comp vers one: $cvtmp
      cvtmp="$cvtmp $cvdep"_compared"=OK"
    else
      debug comp vers notone: $cvtmp
      cvtmp="$cvtmp $cvdep"_compared"=NotOK"
    fi
  done
  compare_versions_result=$cvtmp
  cvtmp=
}


pretty_print()
{
  ppdeps=$*
  brightred="\033[1;31m"
  red="\033[0;31m"
  brown="\033[0;33m"
  yellow="\033[1;33m"
  white="\033[1;37m"
  purple="\033[1;35m"
  green="\033[0;32m"
  cyan="\033[0;36m"
  gray="\033[0;37m"
  nocolor="\033[0m"
  str="%s%-12s"
  format='{printf("'$str$str$str$str$nocolor'\n",$1,$2,$3,$4,$5,$6,$7,$8)}'
  title="$gray depname $gray minimum $gray installed $gray status"
  echo -e $title | awk $format
  for ppdep in $ppdeps; do
    minver=`eval echo "$"$ppdep"_minver"`
    instver=`eval echo "$"$ppdep"_instver"`
    compared=`eval echo "$"$ppdep"_compared"`
    if [ $compared = "NotOK" ]; then
      cmpcolor=$purple;
      ivcolor=$red;
    else
      cmpcolor=$green;
      ivcolor=$gray;
    fi
    echo -e $cyan $ppdep $gray $minver $ivcolor $instver $cmpcolor $compared | awk $format
  done
}


checkargs $*
deps="qt4 cgal gmp cmake mpfr boost opencsg glew eigen gcc imagemagick python bison flex git curl make"
#deps=opencsg
#deps=glew
set_min_versions $deps
eval $set_min_versions_result
find_installed_versions $deps
eval $find_installed_versions_result
compare_versions $deps
eval $compare_versions_result
pretty_print $deps
exit 0





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
#  check-dependencies.sh                # run
#  check-dependencies.sh debug          # debug run
#
# design
#  speed and elegance have been traded-off for an attempt at correctness

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
