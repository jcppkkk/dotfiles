#!/bin/bash
exec > /dev/null
hash git || exit
hash vim || exit

cd "$( dirname "${BASH_SOURCE[0]}" )"
git fetch --all --prune
git pull --rebase

hash powerline-daemon && powerline-daemon -k || true
if (which powerline | grep /usr -q); then
	sudo -H pip install powerline-status --upgrade
else
	pip install --user powerline-status --upgrade
fi

(cd ~/dotfiles/vim; mv -f vundle Vundle.vim)
vim +BundleInstall +qa 2> /dev/null
