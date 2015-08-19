#!/bin/bash
exec > /dev/null
hash git || exit
hash vim || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
git fetch --all --prune
git pull --rebase

vim +BundleInstall +qa
