
# run with '. ./scripts/setenv-freebsdbuild.sh'

# use in conjuction with freebsd-build-dependencies.sh

QMAKESPEC=freebsd-g++
QTDIR=/usr/local/share/qt4
export QMAKESPEC
export QTDIR
. ./scripts/setenv-linbuild.sh

