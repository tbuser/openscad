#!/usr/pkg/bin/bash -e

echo "Tested on NetBSD 5/6. See README.md for more build info"

OPENSCADDIR=$PWD
if [ ! -f $OPENSCADDIR/openscad.pro ]; then
  echo "Must be run from the OpenSCAD source root directory"
  exit 0
fi

. ./scripts/setenv-netbsdbuild.sh

sudo pkgin install libXmu bison boost-libs boost-headers \
 cmake git eigen flex glew gmake gmp glu mpfr qt4 \
 qt4-libs qt4-tools qt4-qdbus Mesa modular-xorg-libs

echo "now run these to install cgal/opencsg from source"
echo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh cgal-use-sys-libs
echo BASEDIR=/usr/local ./scripts/linux-build-dependencies.sh opencsg
