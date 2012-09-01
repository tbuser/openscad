# run with '. ./scripts/setenv-openbsdbuild.sh'

# use in conjuction with bsd-get-dependencies.sh

ulimit -d 2036792
LD_LIBRARY_PATH=/usr/local/lib/qt4:/usr/X11R6/lib:$LD_LIBRARY_PATH
QMAKESPEC=openbsd-g++4
QTDIR=/usr/local/lib/qt4
PATH=/usr/local/lib/qt4/bin:/usr/local/bin:$PATH

export LD_LIBRARY_PATH
export QMAKESPEC
export QTDIR
export PATH

. ./scripts/setenv-linbuild.sh



