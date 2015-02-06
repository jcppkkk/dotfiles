#!/bin/bash
hash git || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
git remote update > /dev/null
