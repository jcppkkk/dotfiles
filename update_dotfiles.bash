#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Clean old files
[ -d local ] && echo The local folder for powerline is not needed anymore, remove? && \rm -ri local

# Update powerline
hash powerline-daemon && powerline-daemon -k || true
if (which powerline | grep /usr -q); then
	sudo pip install powerline-status powerline-gitstatus argparse --upgrade
else
	pip install --user powerline-status powerline-gitstatus argparse --upgrade
fi

# Update vim plugins
if [ -e vim/bundle/vundle ]; then
	pushd vim/bundle/vundle/
	git pull
	popd
	vim +BundleUpdate +qall
fi
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

# Update git-completion.bash
wget -N https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark
pushd bash_completion.d/
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget -N https://raw.githubusercontent.com/bobthecow/git-flow-completion/master/git-flow-completion.bash
popd
