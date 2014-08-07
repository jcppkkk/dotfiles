#!/bin/bash -e
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current

# Disable DNS resolution to speedup ssh
sudo sed -i -e "s:^#\?UseDNS yes:UseDNS no:" /etc/ssh/sshd_config
grep "UseDNS no" /etc/ssh/sshd_config || echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config

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
packages="exuberant-ctags git dos2unix wget make build-essential libssl-dev zlib1g-dev libbz2-dev \
	libreadline-dev libsqlite3-dev wget curl llvm"
install_packages=""
for P in $packages; do
	if dpkg -s "$P" >/dev/null 2>&1; then 
		echo "$P is installed."
	else
		echo "$P is not installed."
		install_packages="$install_packages $P"
	fi
done
[ -n "$install_packages" ] && sudo apt-get install -y $install_packages

# sudo locale-gen zh_TW.UTF-8 || true


## install pyenv & powerline
CFLAGS='-g -O2'
curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
export setupdotfile=yes
set +e
source ~/.bashrc
set -e
pyenv versions | grep -q 2.7.7 || pyenv install 2.7.7
pyenv global 2.7.7
pip install git+git://github.com/Lokaltog/powerline


## install vim plugins
[ -e vim/bundle/vundle ] && (cd vim/bundle/vundle; git pull)
[ ! -e vim/bundle/vundle ] && git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
vim +BundleInstall +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;


## Local changes/fixes
rm -rf local
git config branch.master.rebase true                        # Setup self default using rebase when pull
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts   # patch fonts for powerline
[ -e ~/.bash_history ] && sudo -s chown ${USER}. ~/.bash_history
[ -e ~/.viminfo ] && sudo -s chown ${USER}. ~/.viminfo

exec bash -i # reload bash
