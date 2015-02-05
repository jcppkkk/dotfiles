#!/bin/bash -ex

if [ -z "$SUDO_COMMAND" ]
then
    sudo SUDOER_HOME=$HOME SUDOER_USER=$USER SUDOER_GROUP=`id -g` $0 $*
    exec bash -l
    exit 0
fi

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current
. ./get-platform

# Disable DNS resolution to speedup ssh
if [ -f /etc/ssh/sshd_config ]; then
    sed -i -e "s:^#\?UseDNS yes:UseDNS no:" /etc/ssh/sshd_config
    grep "UseDNS no" /etc/ssh/sshd_config || echo "UseDNS no" | tee -a /etc/ssh/sshd_config
fi

#######################
## Backup dotfiles and replace with link
#######################

dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
( 
\ls | grep -v "~$\|_dotfiles.bash" | while read file;
do 
    target="$HOME/.$file"
    [ -e "$target" ] && mv -f "$target" "$dotfiles_oldfolder/"
    ln -fvs "$(realpath "$file" )" "$target"
done )

#######################
## install packages on new machine
#######################

packages="git dos2unix wget wget curl"

case $platform in 
    'linux') 
        packages="$packages exuberant-ctags"
        packages="$packages make"
        packages="$packages build-essential"
        packages="$packages libssl-dev"
        packages="$packages libbz2-dev"
        packages="$packages zlib1g-dev"
        packages="$packages libreadline-dev"
        packages="$packages libsqlite3-dev"
        ;;
    'mac')
        brew help > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        packages="$packages ctags"
        packages="$packages python"
        ;;
esac

linux_check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
linux_install_pkg() { apt-get install -y $@; }
mac_check_pkg() { brew list -1 | grep -q "^${1}\$"; }
mac_install_pkg() { brew install $@; }

install_packages=""
for P in $packages; do
    if ${platform}_check_pkg $P; then 
        echo "$P is installed."
    else
        echo "$P is not installed."
        install_packages="$install_packages $P"
    fi
done
[ -n "$install_packages" ] && ${platform}_install_pkg $install_packages

# locale-gen zh_TW.UTF-8 || true


#######################
## install vim plugins
#######################
[ -e vim/bundle/vundle ] && (cd vim/bundle/vundle; git pull)
[ ! -e vim/bundle/vundle ] && git clone https://github.com/gmarik/vundle.git vim/bundle/vundle
vim +BundleInstall +qall
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;

#######################
## install pyenv
#######################
#CFLAGS='-g -O2'
#curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
#export setupdotfile=yes
#set +e
#source ~/.bashrc
#set -e
#pyenv versions | grep -q 2.7.7 || pyenv install 2.7.7
#pyenv global 2.7.7

#######################
## install powerline
#######################
# Remove deprecated pyenv version powerline
rm -rf ~/.pyenv/

if hash pip 2>/dev/null; then
	pip install -U pip
else
	# install pip
	#[[ $platform == 'mac' ]] 
	[[ $platform == 'linux' ]] && curl https://bootstrap.pypa.io/get-pip.py | python
fi

hash powerline-daemon && powerline-daemon -k || true
pip install --user git+git://github.com/Lokaltog/powerline --upgrade --ignore-installed


#######################
## Local changes
#######################
git config branch.master.rebase true                        # Setup self default using rebase when pull
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts   # patch fonts for powerline
if (crontab -l | grep -q git_update_dotfiles.bash); then 
	crontab -l | { cat; echo "@daily $current/git_update_dotfiles.bash"; } | crontab - # Daily Update dotfiles repo
fi

#######################
## Local fixes
#######################
rm -rf local
[ -L ~/.local ] && rm ~/.local
chown -R $SUDOER_USER:$SUDOER_GROUP $SUDOER_HOME

