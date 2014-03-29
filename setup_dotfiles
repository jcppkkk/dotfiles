#!/bin/bash -e
set -x
# new machine setup
which ctags >& /dev/null || sudo apt-get install exuberant-ctags || sudo apt-get install ctags
which git >& /dev/null || sudo apt-get install git
# sudo locale-gen zh_TW.UTF-8 || true

# Setup self default using rebase when pull
git config branch.master.rebase true


current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
cd $current

# prepare vim plugins
[ ! -e vim/bundle/vundle ] && git clone https://github.com/gmarik/vundle.git vim/bundle/vundle

# link dotfiles
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
\ls | while read file;
do 
    [ "$file" = "dotfiles_setup" ] && continue
    localfile="$HOME/.$file"
    dotfile="$(readlink -f "$file" )"
    [ -e "$localfile" ] && mv -f "$localfile" "$dotfiles_oldfolder/"
    ln -fvs -T "$dotfile" "$localfile"
done

vim +BundleInstall +qall

which dos2unix &>/dev/null && find $HOME/.vim/ -name \*.vim -exec dos2unix {} \;

sudo chown ${USER}. ~/.bash_history ~/.viminfo

# patch fonts for powerline
fc-cache -vf ~/.fonts
exec bash -i


