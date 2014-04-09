#!/bin/bash -xe
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current


## Replace dotfiles with link and backup old ones
dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
( set +x
\ls | grep -v "~$\|/setup_" | while read file;
do 
    target="$HOME/.$file"
    [ -e "$target" ] && mv -f "$target" "$dotfiles_oldfolder/"
    ln -fvs -T "$(readlink -f "$file" )" "$target"
done )


## new machine setup
sudo apt-get -y install ctags git dos2unix wget
# sudo locale-gen zh_TW.UTF-8 || true


## install pyenv & powerline
curl https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
export setupdotfile=yes
set +xe
source ~/.bashrc
set -xe
pyenv versions | grep -q 2.7.6 || pyenv install 2.7.6
pyenv global 2.7.6
pip install git+git://github.com/Lokaltog/powerline


## install vim plugins
[ ! -e vim/bundle/vundle ] && git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
vim +BundleInstall +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;


## Local changes/fixes
git config branch.master.rebase true                        # Setup self default using rebase when pull
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts   # patch fonts for powerline
sudo chown ${USER}. ~/.bash_history ~/.viminfo

exec bash -i # reload bash
