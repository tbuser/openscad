# must be run using bash

OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi


if [ `uname | grep NetBSD` ]; then
  echo "NetBSD detected"
  echo "Tested on NetBSD 5/6. See README.md for more build info"
  . ./scripts/setenv-netbsdbuild.sh

  sudo pkgin install boost-libs boost-headers \
   cmake git eigen glew gmp glu mpfr qt4 \
   qt4-libs qt4-tools qt4-qdbus Mesa modular-xorg-libs \
   libXmu bison flex git cmake gmake curl wget # cgal opencsg

  NEED_OPENCSG=
  NEED_CGAL=
  if [ ! -e /usr/pkg/include/CGAL ] ; then NEED_CGAL=1; fi  
  if [ ! -e /usr/pkg/include/opencsg.h ]; then 
    NEED_OPENCSG=1; 
  elif [ ! "`grep VERSION /usr/pkg/include/opencsg.h`" ] ; then 
    NEED_OPENCSG=1; 
  fi

  if [ $NEED_OPENCSG ]; then
    echo "Copy/paste the following to install other libraries from source:"
    echo " sudo bash"
    echo " export BASEDIR=/usr/pkg"
    echo " . ./scripts/setenv-netbsdbuild.sh"
    if [ $NEED_CGAL ]; then 
      echo " ./scripts/uni-build-dependencies.sh cgal"
    fi
    if [ $NEED_OPENCSG ]; then 
      echo " ./scripts/uni-build-dependencies.sh opencsg"
    fi
    echo " exit"
  fi
fi


if [ `uname | grep OpenBSD` ]; then
  echo "OpenBSD detected"
  echo "Tested on OpenBSD 5.0. See README.md for more build info"

  . ./scripts/setenv-openbsdbuild.sh

  sudo pkg_add -v bison flex cmake git bash gmake qt4
  sudo pkg_add -v boost eigen2 gmp mpfr glew

  sudo pkg_add -v cgal opencsg
  sudo pkg_add -v ImageMagick--   # -- = avoid ambiguous package

  if [ ! "`grep OPENCSG_VERSION /usr/local/include/opencsg.h`" ]; then
    echo "Your BSD is using an old version of OpenCSG. "
    echo "if you want the newest OpenCSG (for test suite) you can copy/paste the following"
    echo sudo su
    echo pkg_delete opencsg
    echo BASEDIR=/usr/local . ./scripts/setenv-openbsdbuild.sh
    echo ./scripts/uni-build-dependencies.sh opencsg
    echo exit
  fi
fi


if [ `uname | grep FreeBSD` ]; then
  echo "FreeBSD detected"
  echo "Tested on FreeBSD 9. Please see README.md for info on older systems."
	
  . ./scripts/setenv-freebsdbuild.sh

  sudo pkg_add -r bison boost-libs cmake git bash eigen2 flex gmake gmp mpfr 
  sudo pkg_add -r xorg libGLU libXmu libXi xorg-vfbserver glew
  sudo pkg_add -r qt4-corelib qt4-gui qt4-moc qt4-opengl qt4-qmake qt4-rcc qt4-uic
  sudo pkg_add -r cgal opencsg

  if [ ! -e /usr/local/include/opencsg.h ]; then NEED_OPENCSG=1; fi
  if [ ! "`grep OPENCSG_VERSION /usr/local/include/opencsg.h`" ]; then NEED_OPENCSG=1; fi

  if [ $NEED_OPENCSG ]; then
    echo "Your BSD is missing an updated OpenCSG"
    echo "You can copy/paste the following to install from source"
    echo sudo su
    echo pkg_delete opencsg
    echo BASEDIR=/usr/local . ./scripts/setenv-openbsdbuild.sh
    echo ./scripts/uni-build-dependencies.sh opencsg
    echo exit
  fi
fi
	
