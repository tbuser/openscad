# run with '. ./scripts/setenv-netbsdbuild.sh'

# use in conjuction with netbsd-build-dependencies.sh

QMAKESPEC=netbsd-g++
QTDIR=/usr/pkg/qt4
PATH=/usr/pkg/qt4/bin:$PATH
LD_LIBRARY_PATH=/usr/pkg/qt4/lib:$LD_LIBRARY_PATH

export QMAKESPEC
export QTDIR
export PATH
export LD_LIBRARY_PATH

. ./scripts/setenv-linbuild.sh
