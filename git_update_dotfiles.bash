#!/bin/bash
hash git || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
git fetch --all --prune > /dev/null

pushd vim
git fetch --all --prune > /dev/null
vim +BundleInstall +qa
popd
