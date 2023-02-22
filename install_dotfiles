#!/bin/bash
# vim: set et fenc=utf-8 ff=unix sts=4 sw=4 ts=8 : 
if [[ $EUID -eq 0 ]]; then
    echo "This script must NOT be run as root" 1>&2
    exit 1
fi
cd "$(dirname "$0")" || exit
here=$(pwd)
. lib/traceback.sh
## predefined functions

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

retry_root() {
    if ! command -v "$1"; then
        echo "$1 not existed!"
        exit 1
    fi
    cmd=$(command -v "$1")
    shift
    if ! $cmd "$@"; then
        sudo -H LANG=C "$cmd" "$@"
    fi
}

# setup env and location
source files/.bashrc.d/get-platform
source /etc/lsb-release
DIST=${DISTRIB_CODENAME/serena/xenial}
DIST=${DIST/sonya/xenial}

function install_pkg () {
    if ! _install_pkg "$@"; then
        update_pkg_list
        _install_pkg "$@"
    fi
}
case $platform in
    'linux')
        check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
        # aptitude can solve depenency problem for clang-*
        _install_pkg() { sudo apt-get install -y "$@"; }
        update_pkg_list() { sudo apt-get update; }
        # setup aptitude first
        install_pkg aptitude
        _install_pkg() { sudo aptitude install -y "$@"; }
        ;;
    'mac')
        check_pkg() { brew list -1 | grep -q "^${1}\$"; }
        _install_pkg() { brew install "$@"; }
        update_pkg_list() { :; }
        if ! brew help > /dev/null; then
            ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        ;;
esac
#######################
## install pip
#######################
packages+=(python3-pip)
install_pkg "${packages[@]}"
# Remove deprecated pyenv version powerline

set -x
sudo pip install -U pip
sudo pip install -U -r requirements_dotfiles.txt
set +x
PATH=$PATH:$HOME/.local/bin

#######################
## install pyenv
#######################
curl https://pyenv.run | bash

if command -v pyenv; then
    pyenv rehash
fi

# reload powerline after install powerline-gitstatus
if command -v powerline-daemon 2>/dev/null; then
    powerline-daemon -k || true
fi

#
# Main script start, install ansible
#
ansible-playbook -i "localhost," -c local site.yml

#######################
## Backup dotfiles and replace with link
#######################

find -L ~ -maxdepth 1 -type l -delete
(
    unset GREP_OPTIONS
    if [[ -d ~/.config && ! -h ~/.config ]]; then
        rm -rvf ~/.config
    fi
    find "$here/files/" -maxdepth 1 -mindepth 1 | while read -r src; do
        if [[ "$(realpath "$HOME/${src##*/}")" -ef "$src" ]]; then
            echo "$HOME/${src##*/}" is ready
        else
            ln -sv "$src" ~/
        fi
    done
)

#######################
## install packages on new machine
#######################

packages=(git dos2unix wget curl)

case $platform in
    'linux')
        sudo snap install lnav
        sudo add-apt-repository -y ppa:git-core/ppa
        packages+=(sshfs)                             # fs
        packages+=(sshpass)                           # fs
        packages+=(cifs-utils)                        # fs
        packages+=(plocate)                           # fs: search
        packages+=(silversearcher-ag)                 # fs: search
        packages+=(jq)                                # shell tool
        packages+=(moreutils)                         # shell tool: sponge
        packages+=(apt-file)                          # sysadmin
        packages+=(bmon)                              # sysadmin
        packages+=(ncdu)                              # sysadmin
        packages+=(build-essential)                   # dev: build tool
        packages+=(vim)                               # dev: build tool
        packages+=(meld tig)                          # dev: SVC tools
        packages+=(direnv)                            # dev: env control
        packages+=(exuberant-ctags)                   # dev: Coding tools
        packages+=(unzip)
        packages+=(manpages-dev manpages-posix-dev)
        packages+=(cmake)                             # vim YouCompleteMe
        packages+=(shellcheck)                        # for vim syntastic
        packages+=(bikeshed)
        packages+=(fonts-firacode)
        ;;
    'mac')
        packages+=(ctags)
        packages+=(python)
        packages+=(coreutils)
        ;;
esac
install_pkg "${packages[@]}"

#######################
## install vim plugins
#######################
mkdir -p ~/.backup vim/autoload
curl -fLo vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +PlugInstall +qa
find "$HOME/.vim/" -name \*.vim -exec dos2unix -q {} \;

#######################
## install tmux plugins
#######################
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    cd ~/.tmux/plugins/tpm || exit
    git pull --rebase
fi


#######################
## Local changes
#######################
# Setup self default using rebase when pull
git config branch.master.rebase true

# patch fonts for powerline
[ "$1" = "x" ] && get fontconfig && fc-cache -vf ~/.fonts

# Daily Update dotfiles repo
if ! (crontab -l | grep -q git_update_dotfiles.bash); then
    crontab -l \
        | { cat; echo "@daily $here/git_update_dotfiles.bash"; } \
        | crontab -
fi

#######################
## Local fixes
#######################
rm -rf local
[ -L ~/.local ] && rm ~/.local
if [[ -n "$USER" ]] && [[ "$USER" != "root" ]]; then
    sudo chown -R "$USER:${GROUPS[0]}" "$HOME"
fi

# auto cleanup old-kernels
if [[ -n "$(\which purge-old-kernels)" ]]; then
    sudo ln -fs "$(\which purge-old-kernels)" /etc/cron.daily/
    sudo purge-old-kernels
fi

