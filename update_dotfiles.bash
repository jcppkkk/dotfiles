#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Clean old files
[ -d local ] && echo The local folder for powerline is not needed anymore, remove? && \rm -ri local

# Update powerline
hash powerline-daemon && powerline-daemon -k || true
pip install `which powerline | grep -v /usr -q && echo --user` powerline-status --upgrade --ignore-installed

# Update vim plugins
pushd vim/bundle/vundle/
git pull
popd
vim +BundleUpdate +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

# Update git-completion.bash
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
wget -N https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark
