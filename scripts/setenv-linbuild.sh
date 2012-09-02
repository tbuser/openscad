# setup environment variables for building OpenSCAD against custom built
# dependency libraries. called by linux-build-dependencies.sh

# run this file with 'source setenv-linbuild.sh' every time you re-login
# and want to build or run openscad against custom libraries installed
# into BASEDIR.

if [ ! $BASEDIR ]; then
  BASEDIR=$HOME/openscad_deps
fi

DEPLOYDIR=$BASEDIR
PATH=$BASEDIR/bin:$PATH
LD_LIBRARY_PATH=$DEPLOYDIR/lib:$DEPLOYDIR/lib64:$LD_LIBRARY_PATH
LD_RUN_PATH=$LD_LIBRARY_PATH:$LD_RUN_PATH
OPENSCAD_LIBRARIES=$DEPLOYDIR
GLEWDIR=$DEPLOYDIR

export BASEDIR
export DEPLOYDIR
export PATH
export LD_LIBRARY_PATH
export LD_RUN_PATH
export OPENSCAD_LIBRARIES
export GLEWDIR

echo BASEDIR: $BASEDIR
echo DEPLOYDIR: $DEPLOYDIR
echo PATH modified
echo LD_LIBRARY_PATH modified
echo LD_RUN_PATH modified
echo OPENSCAD_LIBRARIES modified
echo GLEWDIR modified

if [ "`command -v qmake-qt4`" ]; then
	echo "Please re-run qmake-qt4 and run 'make clean' if necessary"
else
	echo "Please re-run qmake and run 'make clean' if necessary"
fi

