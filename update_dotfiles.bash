#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Clean old files
[ -d local ] && echo The local folder for powerline is not needed anymore, remove? && \rm -ri local

# Update powerline
pip install git+git://github.com/Lokaltog/powerline --upgrade

# Update vim plugins
pushd vim/bundle/vundle/
git pull
popd
vim +BundleUpdate +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

# Update git-completion.bash
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
