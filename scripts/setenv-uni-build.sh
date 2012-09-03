#
# Setup environment variables for building OpenSCAD on Un*x-like systems
#
# On ordinary linux, OpenSCAD will not require any of this.
# But on several platforms, special settings are required.
#
# This script also handles the case where one has to 'custom build'
# the dependency libraries from source, and they have been installed
# into BASEDIR ( by default, $HOME/openscad_deps )
#
# run this file with '. ./scripts/setenv-unibuild.sh' every time you login
# to a shell and want to build or run OpenSCAD
#
# to build with clang, run '. ./scripts/setenv-unibuild.sh clang'
#

if [ `uname | grep FreeBSD` ]; then
  echo FreeBSD detected
  QMAKESPEC=freebsd-g++
  QTDIR=/usr/local/share/qt4
  export QMAKESPEC
  export QTDIR
fi


if [ `uname | grep NetBSD` ]; then
  echo NetBSD detected
  QMAKESPEC=netbsd-g++
  QTDIR=/usr/pkg/qt4
  PATH=/usr/pkg/qt4/bin:$PATH
  LD_LIBRARY_PATH=/usr/pkg/qt4/lib:$LD_LIBRARY_PATH

  export QMAKESPEC
  export QTDIR
  export PATH
  export LD_LIBRARY_PATH
fi


if [ `uname | grep OpenBSD` ]; then
  echo OpenBSD detected
  ulimit -d 2036792
  LD_LIBRARY_PATH=/usr/local/lib/qt4:/usr/X11R6/lib:$LD_LIBRARY_PATH
  QMAKESPEC=openbsd-g++4
  QTDIR=/usr/local/lib/qt4
  PATH=/usr/local/lib/qt4/bin:/usr/local/bin:$PATH

  export LD_LIBRARY_PATH
  export QMAKESPEC
  export QTDIR
  export PATH
fi


clang_option()
{
  echo Building with clang compiler
  if [ ! "`command -v clang`" ]; then
    echo ----- warning ------
    echo clang command not found
  fi

  CC=clang
  CXX=clang++
  QMAKESPEC=unsupported/linux-clang
  export CC
  export CXX
  export QMAKESPEC

}

for i in $*; do
  if [ $i = "clang" ]; then
    clang_option
  fi
  if [ "`echo $i | grep BASEDIR`" ]; then
    BASEDIR=`echo $i | sed s/.*=//`
    echo "BASEDIR option detected. Argument:" $BASEDIR
  fi
done



# default. always set these variables.

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
echo PATH: $PATH
echo LD_LIBRARY_PATH: $LD_LIBRARY_PATH
echo LD_RUN_PATH: $LD_RUN_PATH
echo OPENSCAD_LIBRARIES: $OPENSCAD_LIBRARIES
echo GLEWDIR: $GLEWDIR
echo QTDIR: $QTDIR
echo CC, CXX, QMAKESPEC: $CC , $CXX , $QMAKESPEC

##if [ "`command -v qmake-qt4`" ]; then
#	echo "Please re-run qmake-qt4 and run 'make clean' if necessary"
#else
#	echo "Please re-run qmake and run 'make clean' if necessary"
#fi

