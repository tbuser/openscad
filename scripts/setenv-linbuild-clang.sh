# build dependencies and/or openscad on linux with the clang compiler

CC=clang
CXX=clang++
QMAKESPEC=unsupported/linux-clang

export CC
export CXX
export QMAKESPEC

echo CC has been modified: $CC
echo CXX has been modified: $CXX
echo QMAKESPEC has been modified: $QMAKESPEC

. ./scripts/setenv-linbuild.sh


