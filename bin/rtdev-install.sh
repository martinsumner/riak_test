#!/usr/bin/env bash

# bail out if things go south
set -e

: ${RT_DEST_DIR:="$HOME/rt/riak"}
if [[ $# < 1 ]]; then
    echo "Missing release directory as argument, e.g. riak_ee-2.1.2"
    exit 1
fi
RELEASE=$1

echo "Making $(pwd) the $RELEASE release:"
cwd=$(pwd)

echo -n " - Determining version: "
if [[ -f $cwd/dependency_manifest.git ]]
then
    VERSION="$(awk '/^-/ { print $NF }' $cwd/dependency_manifest.git)"
else
    VERSION="$(git describe --tags)-$(git branch | awk '/\*/ {print $2}')"
fi

if [[ "$RELEASE" == "current" && ! -z "$RT_CURRENT_TAG" ]]; then
    VERSION=$RT_CURRENT_TAG
fi

echo $VERSION
cd $RT_DEST_DIR

echo " - Resetting existing $RT_DEST_DIR"
export GIT_WORK_TREE="$RT_DEST_DIR"
git reset HEAD --hard > /dev/null
git clean -fd > /dev/null

echo " - Removing and recreating $RT_DEST_DIR/$RELEASE"
rm -rf $RT_DEST_DIR/$RELEASE
mkdir $RT_DEST_DIR/$RELEASE
cd $cwd

echo " - Copying devrel to $RT_DEST_DIR/$RELEASE"
cp -p -P -R dev $RT_DEST_DIR/$RELEASE
echo " - Writing $RT_DEST_DIR/$RELEASE/VERSION"
echo -n $VERSION > $RT_DEST_DIR/$RELEASE/VERSION
cd $RT_DEST_DIR

echo " - Reinitializing git state"

## Some versions of git and/or OS require these fields
HAS_LOCAL=$(git config --local 2>&1 | grep unknown)
if [ -z "$HAS_LOCAL" ]; then
    git config --local user.name "Riak Test"
    git config --local user.email "dev@basho.com"
    git config --local core.autocrlf input
    git config --local core.safecrlf false
    git config --local core.filemode true
fi

git add --all --force .
git commit -a -m "riak_test init" --amend > /dev/null

echo " - Successfully re-initialized git state in $RT_DEST_DIR"
