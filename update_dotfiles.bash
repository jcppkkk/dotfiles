#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Clean old files
[ -d local ] && echo The local folder for powerline is not needed anymore, remove? && \rm -ri local

# Update python pkgs
hash powerline-daemon && powerline-daemon -k || true
sudo -H pip install --upgrade -r requirements_dotfiles.txt

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
pushd bashrc.d/
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
wget -N https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
wget -N https://raw.githubusercontent.com/bobthecow/git-flow-completion/master/git-flow-completion.bash
popd
