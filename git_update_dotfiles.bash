#!/bin/bash
clean_up() {
	echo "Error: Script $(basename $BASH_SOURCE) Line $1"
}
trap 'clean_up $LINENO' INT ERR
set -e
hash git || exit
hash vim || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
if (which git-up); then
	git-up
else
	git fetch --all --prune
	git stash
	git pull --rebase
	git stash pop
fi

PATH=$PATH:/usr/local/bin
hash powerline-daemon 2>/dev/null && powerline-daemon -k || true
if (which powerline | grep /usr -q); then
	sudo -H pip install powerline-status --upgrade
else
	pip install --user powerline-status --upgrade
fi

if [ -d $HOME/.vim/vundle ]; then
	mv -f $HOME/.vim/{vundle,Vundle.vim}
fi
vim +BundleInstall +qa 2> /dev/null
