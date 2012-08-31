# run with '. ./scripts/setenv-openbsdbuild.sh'

# use in conjuction with openbsd-build-dependencies.sh

ulimit -d 2036792
export LD_LIBRARY_PATH=/usr/X11R6/lib:$LD_LIBRARY_PATH
export QMAKESPEC=openbsd-g++4
export QTDIR=/usr/local/lib/qt4
export PATH=/usr/local/lib/qt4/bin:/usr/local/bin:$PATH


