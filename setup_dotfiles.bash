#!/bin/bash -e
set -x
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current


## new machine setup
sudo apt-get install ctags git dos2unix wget
# sudo locale-gen zh_TW.UTF-8 || true


## install powerline

pip install --user git+git://github.com/Lokaltog/powerline


## Replace dotfiles with link and backup old ones
dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
( set +x
\ls | grep -v "~$\|/setup_" | while read file;
do 
    target="$HOME/.$file"
    mv -f "$target" "$dotfiles_oldfolder/"
    ln -fvs -T "$(readlink -f "$file" )" "$target"
done )


## install vim plugins
[ ! -e vim/bundle/vundle ] && git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
vim +BundleInstall +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;


## Local changes/fixes
git config branch.master.rebase true                        # Setup self default using rebase when pull
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts   # patch fonts for powerline
sudo chown ${USER}. ~/.bash_history ~/.viminfo

exec bash -i # reload bash
