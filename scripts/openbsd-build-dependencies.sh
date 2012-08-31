#!/usr/local/bin/bash -e

echo "Tested on OpenBSD 5.0. See README.md for more build info"

OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi

. ./scripts/setenv-openbsdbuild.sh

sudo pkg_add -v bison boost cmake git bash eigen2 flex gmake gmp mpfr 
sudo pkg_add -v glew
sudo pkg_add -v qt4 
sudo pkg_add -v cgal opencsg
sudo pkg_add -v ImageMagick--   # -- = avoid ambiguous package

#sudo pkg_add -v qt4-corelib qt4-gui qt4-moc qt4-opengl qt4-qmake 
#qt4-rcc qt4-uic
# sudo pkg_add -v xorg libGLU libXmu libXi xorg-vfbserver glew

#echo "now copy/paste these lines to build cgal + opencsg from source"
#echo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh cgal-use-sys-libs
#echo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh opencsg
