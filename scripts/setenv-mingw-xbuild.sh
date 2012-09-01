#!/bin/sh -e
#
# set environment variables for mingw/mxe cross-build
#
# Usage: source ./scripts/setenv-mingw-xbuild.sh
#
# Prerequisites:
#
# Please see http://mxe.cc/#requirements
#
# Also see http://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Cross-compiling_for_Windows_on_Linux_or_Mac_OS_X
#

OPENSCADDIR=$PWD
export OPENSCADDIR

if [ ! $BASEDIR ]; then
	BASEDIR=$HOME/openscad_deps
	export BASEDIR
fi

if [ ! $DEPLOYDIR ]; then
	DEPLOYDIR=$OPENSCADDIR/mingw32
        export DEPLOYDIR
fi

if [ ! $MXEDIR ]; then
	MXEDIR=$BASEDIR/mxe
	export MXEDIR
fi

PATH=$MXEDIR/usr/bin:$PATH
export PATH

echo BASEDIR: $BASEDIR
echo "(BASEDIR is not used during mingw cross builds)"
echo MXEDIR: $MXEDIR
echo DEPLOYDIR: $DEPLOYDIR
echo PATH modified with $MXEDIR/usr/bin

if [ ! -e $DEPLOYDIR ]; then
  mkdir -p $DEPLOYDIR
fi

echo linking $MXEDIR/usr/i686-pc-mingw32/ to $DEPLOYDIR/mingw-cross-env
rm -f $DEPLOYDIR/mingw-cross-env
ln -s $MXEDIR/usr/i686-pc-mingw32/ $DEPLOYDIR/mingw-cross-env

