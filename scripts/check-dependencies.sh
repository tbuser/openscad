# Determine which versions of dependency tools and libraries are
# available on the system. This helps the build-dependencies script
# to build only what's needed.
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
# todo
#  check if running from main OPENSCAD dir (or at leats check for README)
#  refactor main loop.
#  look in /usr/local/ on linux
#  if /usr/ and /usr/local/ on linux both hit, throw an error
#  fallback- pkgconfig --exists, then --modversion
#  fallback2 - pkg manager
#  todo - use OPENSCAD_LIBRARIES ???
#  - print location found, how found???
#  
# more todo:
#  look in /usr and /usr/local on linux
#
DEBUG=
QMAKE_MODE=

debug()
{
  if [ $DEBUG ]; then echo dependency-versions.sh: $* ; fi
}


find_syspath()
{
  sptmp=
  syspath=
  if [ "`uname | grep -i 'Linux\|Debian'`" ]; then
    sptmp="/usr"
  elif [ "`uname | grep -i 'FreeBSD\|OpenBSD'`" ]; then
    sptmp="/usr/local"
  elif [ "`uname | grep -i NetBSD`" ]; then
    sptmp="/usr/pkg"
  else
    echo unknown system type. assuming prefix is /usr
    sptmp="/usr"
  fi
  find_syspath_result=$sptmp
}

eigen_sysver()
{
  debug eigen
  eigpath=
  eig3path=$syspath/include/eigen3/Eigen/src/Core/util/Macros.h
  eig2path=$syspath/include/eigen2/Eigen/src/Core/util/Macros.h
  if [ -e $eig3path ]; then eigpath=$eig3path; fi
  if [ -e $eig2path ]; then eigpath=$eig2path; fi
  debug $eig2path
  if [ ! $eigpath ]; then return; fi
  eswrld=`grep "define  *EIGEN_WORLD_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
  esmaj=`grep "define  *EIGEN_MAJOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
  esmin=`grep "define  *EIGEN_MINOR_VERSION  *[0-9]*" $eigpath | awk '{print $3}'`
  eigen_sysver_result="$eswrld.$esmaj.$esmin"
}

opencsg_sysver()
{
  debug opencsg_sysver
  if [ ! -e $syspath/include/opencsg.h ]; then return; fi
  # OpenCSG version is a hex number, 0x0xyz where x=maj, y=min, z=patch
  # So we convert the hex to "x.y.z" format.
  # Note that before 1.3.2 there's no version number at all.
  hex=`grep "define  *OPENCSG_VERSION  *[0-9x]*" $syspath/include/opencsg.h`
  if [ ! "$hex" ]; then
    ocver=
  else
    ocver=`echo $hex | sed s/"[^0-9x.]"//g | sed s/"0x"// | sed s/"^0*"//` # de-hex
    debug parse opencsg - removed leading 0x0. $ver
    ocver=`echo $ver | awk 'BEGIN{FS=""}{for(i=1;i<=NF;i++) printf($i".")}' | sed s/"\.$"//`
    debug parse opencsg - inserted dots. $ver
  fi
  opencsg_sysver_result=$ocver
}

cgal_sysver()
{
  cgalpath=$syspath/include/CGAL/version.h
  if [ ! -e $cgalpath ]; then return; fi
  cgal_sysver_result=`grep "define  *CGAL_VERSION  *[0-9.]*" $cgalpath | awk '{print $3}'`
}

boost_sysver()
{
  boostpath=$syspath/include/boost/version.hpp
  if [ ! -e $boostpath ]; then return; fi
  bsver=`grep 'define  *BOOST_LIB_VERSION *[0-9_"]*' $boostpath | awk '{print $3}'`
  bsver=`echo $bsver | sed s/'"'//g | sed s/'_'/'.'/g`
  boost_sysver_result=$bsver
}

mpfr_sysver()
{
  mpfrpath=$syspath/include/mpfr.h
  if [ ! -e $mpfrpath ]; then return; fi
  mpfrsver=`grep 'define  *MPFR_VERSION_STRING  *' $mpfrpath | awk '{print $3}'`
  mpfrsver=`echo $mpfrsver | sed s/"-.*"// | sed s/'"'//`
  mpfr_sysver_result=$mpfrsver
}

gmp_sysver()
{
  # on some systems you have VERSION in gmp-$arch.h not gmp.h. use gmp*.h
  gmppaths=`ls $syspath/include | grep ^gmp`
  if [ ! "$gmppaths" ]; then return; fi
  for gmpfile in $gmppaths; do
    gmppath=$syspath/include/$gmpfile
    if [ "`grep __GNU_MP_VERSION $gmppath`" ]; then
      gmpmaj=`grep "define  *__GNU_MP_VERSION  *[0-9]*" $gmppath | awk '{print $3}'`
      gmpmin=`grep "define  *__GNU_MP_VERSION_MINOR  *[0-9]*" $gmppath | awk '{print $3}'`
      gmppat=`grep "define  *__GNU_MP_VERSION_PATCHLEVEL  *[0-9]*" $gmppath | awk '{print $3}'`
    fi
  done
  gmp_sysver_result="$gmpmaj.$gmpmin.$gmppat"
}

qt4_sysver()
{
  qt4path=$syspath/include/qt4/QtCore/qglobal.h
  if [ ! -e $qt4path ]; then return; fi
  qt4ver=`grep 'define  *QT_VERSION_STR  *' $qt4path | awk '{print $3}'`
  qt4ver=`echo $qt4ver | sed s/'"'//g`
  qt4_sysver_result=$qt4ver
}

glew_sysver()
{
  glew_sysver_result= # glew has no traditional version numbers
}

imagemagick_sysver()
{
  if [ ! -x $syspath/bin/convert ]; then return; fi
  imver=`$syspath/bin/convert --version | grep -i version`
  imagemagick_sysver_result=`echo $imver | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
}

flex_sysver()
{
  flexbin=$syspath/bin/flex
  if [ -x $syspath/bin/gflex ]; then flexbin=$syspath/bin/gflex; fi # openbsd
  if [ ! -x $flexbin ]; then return ; fi
  flex_sysver_result=`$flexbin --version | sed s/"[^0-9.]"/" "/g`
}

bison_sysver()
{
  if [ ! -x $syspath/bin/bison ]; then return ; fi
  bison_sysver_result=`$syspath/bin/bison --version | grep bison | sed s/"[^0-9.]"/" "/g`
}

gcc_sysver()
{
  bingcc=$syspath/bin/gcc
  if [ ! -x $syspath/bin/gcc ]; then bingcc=gcc; fi
  if [ ! "`$bingcc --version`" ]; then return; fi
  gccver=`$bingcc --version| grep -i gcc`
  gccver=`echo $gccver | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
  gcc_sysver_result=$gccver
}

git_sysver()
{
  if [ ! -x $syspath/bin/git ]; then return ; fi
  git_sysver_result=`$syspath/bin/git --version | grep git | sed s/"[^0-9.]"/" "/g`
}

curl_sysver()
{
  if [ ! -x $syspath/bin/curl ]; then return; fi
  curl_sysver_result=`$syspath/bin/curl --version | grep curl | sed s/"[^0-9. ]"/" "/g | awk '{print $1}'`
}

cmake_sysver()
{
  if [ ! -x $syspath/bin/cmake ]; then return ; fi
  cmake_sysver_result=`$syspath/bin/cmake --version | grep cmake | sed s/"[^0-9.]"/" "/g`
}

make_sysver()
{
  binmake=$syspath/bin/make
  if [ -x $syspath/bin/gmake ]; then binmake=$syspath/bin/gmake ;fi
  if [ ! -x $binmake ]; then return ;fi
  make_sysver_result=`$binmake --version 2>&1 | grep -i 'gnu make' | sed s/"[^0-9.]"/" "/g`
  if [ ! "`echo $make_sysver_result | grep [0-9]`" ]; then return; fi
}

bash_sysver()
{
  if [ -x /bin/bash ]; then binbash=/bin/bash ;fi
  if [ -x /usr/bin/bash ]; then binbash=/usr/bin/bash ;fi
  if [ -x $syspath/bin/bash ]; then binbash=$syspath/bin/bash ;fi
  if [ ! -x $binbash ]; then return; fi
  bash_sysver_result=`$binbash --version | grep bash | sed s/"[^0-9. ]"/" "/g|awk '{print $1}'`
}

python_sysver()
{
  if [ ! -x $syspath/bin/python ]; then return; fi
  python_sysver_result=`$syspath/bin/python --version 2>&1 | awk '{print $2}'`
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


apt_pkg_search()
{
  debug apt_pkg_search $*
  apt_pkg_search_result=
  pkgname=$1
  dps_ver=

  # translate pkgname to apt packagename
  set_default_package_map
  for pn in cgal boost mpfr opencsg qt4; do eval $pn="lib"$pn"-dev" ; done

  # handle multiple version names of same package (ubuntu, debian, etc)
  if [ $pkgname = glew ]; then
    glewtest=`apt-cache search libglew-dev`
    if [ "`echo $glewtest | grep glew1.6-dev`" ]; then glew=libglew1.6-dev;
    elif [ "`echo $glewtest | grep glew1.5-dev`" ]; then glew=libglew1.5-dev;
    elif [ "`echo $glewtest | grep glew-dev`" ]; then glew=libglew-dev; fi
  elif [ $pkgname = gmp ]; then
    if [ "`apt-cache search libgmp3-dev`" ]; then gmp=libgmp3-dev ;fi
    if [ "`apt-cache search libgmp-dev`" ]; then gmp=libgmp-dev ;fi
  fi

  debpkgname=`eval echo "$"$pkgname`

  if [ ! $debpkgname ]; then
    debug "unknown package" $pkgname; return;
  fi

  debug $pkgname ".deb name:" $debpkgname
  if [ ! "`command -v dpkg`" ]; then
    debug command dpkg not found. cannot search packages.
    return
  fi

  # examples of apt version strings
  # cgal 4.0-4   gmp 2:5.0.5+dfsg  bison 1:2.5.dfsg-2.1 cmake 2.8.9~rc1

  if [ $pkgname = eigen ]; then
    aps_null=`dpkg --status libeigen3-dev 2>&1`
    if [ $? = 0 ]; then
      debpkgname=libeigen3-dev
    else
      debpkgname=libeigen2-dev
    fi
  fi

  debug "test dpkg on $debpkgname"
  testdpkg=`dpkg --status $debpkgname 2>&1`
  if [ "$testdpkg" ]; then
    #debug test dpkg: $testdpkg
    if [ "`echo $testdpkg | grep -i version`" ]; then
      dps_ver=`dpkg --status $debpkgname | grep -i ^version: | awk ' { print $2 }'`
      debug version line from dpkg: $dps_ver
      dps_ver=`echo $dps_ver | tail -1 | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
      debug version: $dps_ver
    else
      debug couldnt find version string after dpkg --status $debpkgname
    fi
  else
    debug testdpkg failed on $debpkgname
  fi

  # Available to be system
  #dps_ver=
  #debug "test apt-cache on $debpkgname"
  # apt-cache show is flaky on older apt. dont run unless search is OK
  #test_aptcache=`apt-cache search $debpkgname`
  #if [ "$test_aptcache" ]; then
  #  test_aptcache=`apt-cache show $debpkgname`
  #  if [ ! "`echo $test_aptcache | grep -i no.packages`" ]; then
  #    ver=`apt-cache show $debpkgname | grep ^Version: | awk ' { print $2 }'`
  #    ver=`echo $ver | tail -1 | sed s/"[-~].*"// | sed s/".*:"// | sed s/".dfsg*"//`
  #    if [ $ver ] ; then vera=$ver ; fi
  #  fi
  #fi

  apt_pkg_search_result="$dps_ver"
}

freebsd_pkg_search()
{
  freebsd_pkg_search_result=
  pkgname=$1
  veri=
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
  freebsd_pkg_search_result="$veri $vera"
}

openbsd_pkg_search()
{
  openbsd_pkg_search_result=
  pkgname=$1
  veri=
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

  # system
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

  openbsd_pkg_search_result="$veri $vera"
}


netbsd_pkg_search()
{
  netbsd_pkg_search_result=
  pkgname=$1
  veri=
  vera=
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

  # system
  # examples of netbsd package names
  # zsh-4.3.15nb1
  test_pkgin=`pkgin list | grep $netbsd_pkgname`
  if [ "$test_pkgin" ]; then
    debug system check - $test_pkgin
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

  netbsd_pkg_search_result="$veri $vera"
}



set_fedora_package_map()
{
  cgal=CGAL-devel
  eigen=eigen2-devel
  qt4=qt-devel
  imagemagick=ImageMagick
  for pn in  boost gmp mpfr glew; do eval $pn=$pn"-devel" ; done
}

yum_pkg_search()
{
  yum_pkg_search_result=
  pkgname=$1

  set_default_package_map
  set_fedora_package_map
  fedora_pkgname=`eval echo "$"$pkgname`

  debug $pkgname". fedora name:" $fedora_pkgname
  if [ ! $fedora_pkgname ]; then
    debug "unknown package" $pkgname; return;
  fi

  test_yum=`yum info $fedora_pkgname 2>&1`
  if [ "$test_yum" ]; then
    debug test_yum: $test_yum
    ydvver=`yum info $fedora_pkgname 2>&1 | grep ^Version | awk '{print $3}' `
    if [ $ydvver ]; then ydvver=$ydvver ; fi
  else
    debug test_yum failed on $pkgname
  fi
  yum_pkg_search_result="$ydvver"
}


pkg_search()
{
  debug pkg_search $*
  pkg_search_result=

  if [ "`command -v apt-get`" ]; then
    apt_pkg_search $*
    pkg_search_result=$apt_pkg_search_result
  elif [ "`command -v yum`" ]; then
    yum_pkg_search $*
    pkg_search_result=$yum_pkg_search_result
  elif [ "`uname | grep FreeBSD`" ]; then
    freebsd_pkg_search $*
    pkg_search_result=$freebsd_pkg_search_result
  elif [ "`uname | grep NetBSD`" ]; then
    netbsd_pkg_search $*
    pkg_search_result=$netbsd_pkg_search_result
  elif [ "`uname | grep OpenBSD`" ]; then
    openbsd_pkg_search $*
    pkg_search_result=$openbsd_pkg_search_result
  else
    echo unknown system type. cannot search packages.
  fi
}

pkg_config_search()
{
  debug pkg_config_search $*
  pkg_config_search_result=
  pcstmp=
  if [ ! $1 ]; then return; fi
  pkgname=$1

  pkg-config --exists $pkgname 2>&1
  if [ $? = 0 ]; then
    pkg_config_search_result=`pkg-config --modversion $pkgname`
  else
    debug pkg_config_search failed on $*, result of run was: $pcstmp
  fi
}




get_readme_version()
{
  debug get_readme_version $*
  if [ ! $1 ]; then return; fi
  depname=$1
  local grv_tmp=
  debug $depname
  # example-->     * [CGAL (3.6 - 3.9)] (www.cgal.org)  becomes 3.6
  # steps: eliminate *, find left (, find -, make 'x' into 0, delete junk
  grv_tmp=`grep -i ".$depname.*([0-9]" README.md | sed s/"*"//`
  debug $grv_tmp
  grv_tmp=`echo $grv_tmp | awk -F"(" '{print $2}'`
  debug $grv_tmp
  grv_tmp=`echo $grv_tmp | awk -F"-" '{print $1}'`
  debug $grv_tmp
  grv_tmp=`echo $grv_tmp | sed s/"x"/"0"/g`
  debug $grv_tmp
  grv_tmp=`echo $grv_tmp | sed s/"[^0-9.]"//g`
  debug $grv_tmp
  get_readme_version_result=$grv_tmp
}


find_min_version()
{
  find_min_version_result=
  fmvtmp=
  if [ ! $1 ] ; then return; fi
  fmvdep=$1
  get_readme_version $fmvdep
  fmvtmp=$get_readme_version_result
  if [ $fmvdep = "git" ]; then fmvtmp=1.5 ; fi
  if [ $fmvdep = "curl" ]; then fmvtmp=6 ; fi
  if [ $fmvdep = "make" ]; then fmvtmp=3 ; fi
  find_min_version_result=$fmvtmp
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
  debug "v1, v2, v1int, v2int" , $v1, $v2, $v1int, $v2int
  if [ $v1int -le $v2int ]; then
    debug "v1 <= v2"
    return 0
  else
    debug "v1 > v2"
    return 1
  fi
  v1=
  v2=
  v1int=
  v2int=
}

compare_version()
{
  debug compare_version $*
  compare_version_result="NotOK"
  if [ ! $1 ] ; then return; fi
  if [ ! $2 ] ; then return; fi
  cvminver=$1
  cvsysver=$2
  cvtmp=
  version_less_than_or_equal $cvminver $cvsysver
  if [ $? = 0 ]; then
    cvtmp="OK"
  else
    cvtmp="NotOK"
  fi
  compare_version_result=$cvtmp
  cvtmp=
}

pretty_print()
{
  debug pretty_print $*

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

  ppstr="%s%-12s"
  pp_format='{printf("'$ppstr$ppstr$ppstr$ppstr$nocolor'\n",$1,$2,$3,$4,$5,$6,$7,$8)}'
  pp_title="$gray depname $gray minimum $gray system $gray OKness"
  if [ $1 ]; then pp_dep=$1; fi
  if [ $pp_dep = "title" ]; then
    echo -e $pp_title | awk $pp_format
    return ;
  fi

  if [ $2 ]; then pp_minver=$2; else pp_minver="unknown"; fi
  if [ $3 ]; then pp_sysver=$3; else pp_sysver="unknown"; fi
  if [ $4 ]; then pp_compared=$4; else pp_compared="NotOK"; fi

  if [ $pp_compared = "NotOK" ]; then
    pp_cmpcolor=$purple;
    pp_ivcolor=$purple;
  else
    pp_cmpcolor=$green;
    pp_ivcolor=$gray;
  fi
  echo -e $cyan $pp_dep $gray $pp_minver $pp_ivcolor $pp_sysver $pp_cmpcolor $pp_compared | awk $pp_format
  pp_dep=
  pp_minver=
  pp_sysver=
  pp_compared=
}




find_sys_version()
{
  debug find_sys_version $*
  find_sys_version_result=unknown
  fsv_tmp=
  dep=$1

  # pkg-config search
  if [ "`command -v pkg-config`" ]; then
    pkg_config_search $dep
    fsv_tmp=$pkg_config_search_result
  fi

  # header/binary program search
  if [ ! $fsv_tmp ]; then
    find_syspath
    syspath=$find_syspath_result
    debug $dep"_sysver" $syspath
    eval $dep"_sysver" $syspath
    fsv_tmp=`eval echo "$"$dep"_sysver_result"`
  fi

  # package search
  if [ ! $fsv_tmp ]; then
    pkg_search $dep
    fsv_tmp=$pkg_search_result
  fi

  if [ $fsv_tmp ]; then
    find_sys_version_result=$fsv_tmp
  fi
}






checkargs()
{
  for i in $*; do
    if [ $i = "debug" ]; then DEBUG=1 ; fi
    if [ $i = "qmake" ]; then QMAKE_MODE=1 ; fi
  done
}

main()
{
  deps="qt4 cgal gmp cmake mpfr boost opencsg glew eigen gcc"
  deps="$deps imagemagick python bison flex git curl make"
  #deps="eigen glew opencsg"
  pretty_print title
  for dep in $deps; do
    debug "processing $dep"
    find_sys_version $dep
    dep_sysver=$find_sys_version_result
    find_min_version $dep
    dep_minver=$find_min_version_result
    compare_version $dep_minver $dep_sysver
    dep_compare=$compare_version_result
  	pretty_print $dep $dep_minver $dep_sysver $dep_compare
  done
}

checkargs $*
main
exit 0

