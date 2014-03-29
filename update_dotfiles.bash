#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Update powerline
pip install --user git+git://github.com/Lokaltog/powerline --upgrade

# Update vim plugins
vim +BundleInstall! +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

# Update git-completion.bash
wget -N https://github.com/git/git/raw/master/contrib/completion/git-completion.bash
wget -N https://github.com/git/git/raw/master/contrib/completion/git-prompt.sh
