# must be run using bash

OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi

# check that OpenCSG exists and is the minimum version
check_opencsg()
{
  prefix=$1
  if [ -e $1/include/opencsg.h ]; then
    # we need 1.3.2. before 1.3.2 there is no VERSION in the header.
    if [ grep VERSION $1/include/opencsg.h ]; then
      return 1
    fi
  fi 
  return 0
}

# check that CGAL exists and is the minimum version
check_cgal()
{
  prefix=$1
  if [ -e /usr/pkg/include/CGAL/version ]; then 
    if [ "`grep CGAL_VERSION.*3.[7-9]..`" ]; then return 1; fi
    if [ "`grep CGAL_VERSION.*4.[0-9]..`" ]; then return 1; fi
  fi 
  return 0
}


# notify user that some libs should be upgraded, provide copy/paste to do so
advise_upgrade()
{
  prefix=$1
  envsetter=$2
  echo "Copy/paste the following to install other libraries from source:"
  echo " sudo bash"
  echo " export BASEDIR=$prefix"
  echo " . ./scripts/setenv-$2build"
  if [ $1 ]; then
    if [ `pkg_info | grep $1` ]; then echo " pkg_delete $1"; fi
    echo " ./scripts/uni-build-dependencies.sh $1"; 
  fi
  if [ $2 ]; then
    if [ `pkg_info | grep $2` ]; then echo " pkg_delete $2"; fi
    echo " ./scripts/uni-build-dependencies.sh $2"; 
  fi
}


if [ `uname | grep NetBSD` ]; then
  echo "NetBSD detected"
  echo "Tested on NetBSD 5/6. See README.md for more build info"
  . ./scripts/setenv-netbsdbuild.sh

  # sudo pkgin has bizarre problems on VMs. run it thru 'sudo bash' instead

  sudo bash -c "pkgin install boost-libs boost-headers \
   cmake git eigen glew gmp glu mpfr qt4 \
   qt4-libs qt4-tools qt4-qdbus Mesa modular-xorg-libs \
   libXmu bison flex scmgit cmake gmake curl wget \
   cgal opencsg \
   python imagemagick"

   if [ `check_opencsg /usr/pkg` ]; then NEED_LIBS=opencsg; fi
   if [ `check_cgal /usr/pkg` ]; then NEED_LIBS="$NEED_LIBS cgal"; fi
   if [ $NEED_LIBS ]; then 
     advise_upgrade /usr/pkg netbsd $NEED_LIBS
   fi
fi


if [ `uname | grep OpenBSD` ]; then
  echo "OpenBSD detected"
  echo "Tested on OpenBSD 5.0. See README.md for more build info"

  . ./scripts/setenv-openbsdbuild.sh

  sudo pkg_add -v bison flex cmake git bash gmake qt4
  sudo pkg_add -v boost eigen2 gmp mpfr glew

  sudo pkg_add -v cgal opencsg
  sudo pkg_add -v ImageMagick-- python  # -- = avoid ambiguous package

  if [ `check_opencsg /usr/local` ]; then NEED_LIBS=opencsg; fi
  if [ `check_cgal /usr/local` ]; then NEED_LIBS="$NEED_LIBS cgal"; fi
  if [ $NEED_LIBS ]; then 
    advise_upgrade /usr/local openbsd $NEED_LIBS
  fi
fi


if [ `uname | grep FreeBSD` ]; then
  echo "FreeBSD detected"
  echo "Tested on FreeBSD 9. Please see README.md for info on older systems."
	
  . ./scripts/setenv-freebsdbuild.sh

  # sudo pkg_add has bizarre problems on VMs. run it thru 'sudo bash' instead

  sudo bash -c "pkg_add -r bison boost-libs"
  sudo bash -c "pkg_add -r cmake git bash eigen2 flex gmake gmp mpfr"
  sudo bash -c "pkg_add -r xorg libGLU libXmu libXi xorg-vfbserver glew"
  sudo bash -c "pkg_add -r qt4-corelib qt4-gui qt4-moc qt4-opengl qt4-qmake qt4-rcc qt4-uic"
  sudo bash -c "pkg_add -r cgal opencsg"
  sudo bash -c "pkg_add -r python ImageMagick"

  if [ `check_opencsg /usr/local` ]; then NEED_LIBS=opencsg; fi
  if [ `check_cgal /usr/local` ]; then NEED_LIBS="$NEED_LIBS cgal"; fi
  if [ $NEED_LIBS ]; then 
    advise_upgrade /usr/local openbsd $NEED_LIBS
  fi
fi
	
