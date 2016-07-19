#!/bin/bash
exec > /dev/null
hash git || exit
hash vim || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
if (which git-up); then
	git-up
else
	git fetch --all --prune
	git pull --rebase
fi

hash powerline-daemon && powerline-daemon -k || true
if (which powerline | grep /usr -q); then
	sudo -H pip install powerline-status --upgrade
else
	pip install --user powerline-status --upgrade
fi

if [ -d $HOME/.vim/vundle ]; then
	mv -f $HOME/.vim/{vundle,Vundle.vim}
fi
vim +BundleInstall +qa 2> /dev/null
