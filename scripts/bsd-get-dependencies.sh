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

  sudo pkgin install libXmu bison boost-libs boost-headers \
   cmake git eigen flex glew gmake gmp glu mpfr qt4 \
   qt4-libs qt4-tools qt4-qdbus Mesa modular-xorg-libs

  echo "now install CGAL + OpenCSG from source:"
  echo BASEDIR=/usr/pkg ./scripts/uni-build-dependencies.sh opencsg
  echo BASEDIR=/usr/pkg ./scripts/uni-build-dependencies.sh cgal
fi

if [ `uname | grep OpenBSD` ]; then
  echo "OpenBSD detected"
  echo "Tested on OpenBSD 5.0. See README.md for more build info"

  . ./scripts/setenv-openbsdbuild.sh

  sudo pkg_add -v bison flex cmake git bash gmake qt4

  sudo pkg_add -v boost eigen2 gmp mpfr glew
  sudo pkg_add -v cgal opencsg
  sudo pkg_add -v ImageMagick--   # -- = avoid ambiguous package

  echo "if you want the newest OpenCSG (for test suite) you can copy/paste the following"
  echo sudo pkg_delete opencsg
  echo sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh opencsg
fi

if [ `uname | grep FreeBSD` ]; then

  echo "Tested on FreeBSD 9. Please see README.md for info on older systems."
	
  . ./scripts/setenv-freebsdbuild.sh

  pkg_add -r bison boost-libs cmake git bash eigen2 flex gmake gmp mpfr 
  pkg_add -r xorg libGLU libXmu libXi xorg-vfbserver glew
  pkg_add -r qt4-corelib qt4-gui qt4-moc qt4-opengl qt4-qmake qt4-rcc qt4-uic

  echo "Now copy/paste the following for CGAL + OpenCSG:"
  echo sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh cgal
  echo sudo BASEDIR=/usr/local ./scripts/uni-build-dependencies.sh opencsg
fi
	
