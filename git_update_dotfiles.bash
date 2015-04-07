#!/bin/bash
exec > /dev/null
hash git || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
git fetch --all --prune 

pushd vim
git pull 
vim +BundleInstall +qa
popd
