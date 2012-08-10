# setup environment variables for building OpenSCAD against the oldest
# versions of the dependency libraries, as specificed under the
# 'oldest versions' section of dependency-versions.sh
#
# By default the libraries will be built in $HOME/openscad_deps_min instead of
# the normal $HOME/openscad_deps

export BASEDIR=$HOME/openscad_deps_min
export OPENSCAD_DEP_VERSIONS=lowest
echo OPENSCAD_DEP_VERSIONS set to $OPENSCAD_DEP_VERSIONS

. ./scripts/setenv-linbuild.sh
