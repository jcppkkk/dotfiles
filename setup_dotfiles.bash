#!/bin/bash
if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root" 1>&2
	exit 1
fi
here=$(cd $(dirname $0); pwd)
cd $here
. lib/traceback.sh
## predefined functions

realpath() {
	[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

retry_root() {
	if ! command -v $1; then
		echo "$1 not existed!"
		exit 1
	fi
	cmd=$(command -v $1)
	shift
	if ! $cmd $@; then
		sudo -H LANG=C $cmd $@
	fi
}

# setup env and location
source bashrc.d/get-platform
source /etc/lsb-release
DIST=${DISTRIB_CODENAME/serena/xenial}
DIST=${DIST/sonya/xenial}

function install_pkg () {
	if ! _install_pkg $@; then
		update_pkg_list
		_install_pkg $@
	fi
}
case $platform in
'linux')
	check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
	# aptitude can solve depenency problem for clang-*
	_install_pkg() { sudo apt-get install -y $@; }
	update_pkg_list() { sudo apt-get update; }
	# setup aptitude first
	install_pkg aptitude
	_install_pkg() { sudo aptitude install -y $@; }
	;;
'mac')
	check_pkg() { brew list -1 | grep -q "^${1}\$"; }
	_install_pkg() { brew install $@; }
	update_pkg_list() { :; }
	if ! brew help > /dev/null; then
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	;;
esac
#######################
## install pips & powerline
#######################
packages+=(python)
install_pkg ${packages[@]}
# Remove deprecated pyenv version powerline
if command -v powerline-daemon 2>/dev/null; then
	powerline-daemon -k || true
fi

if ! command -v pip; then
	wget https://bootstrap.pypa.io/get-pip.py -q -O get-pip.py
	retry_root python get-pip.py
fi
retry_root pip install -U pip
retry_root pip install -U -r requirements_dotfiles.txt
if command -v pyenv; then
	pyenv rehash
fi

#
# Main script start, install ansible
#
ansible-playbook -i "localhost," -c local site.yml

#######################
## Backup dotfiles and replace with link
#######################

dotfiles_oldfolder="$HOME/.dotfiles_old_`date +%Y%m%d%H%M%S`"
[ ! -e "$dotfiles_oldfolder" ] && mkdir "$dotfiles_oldfolder"
(
	unset GREP_OPTIONS
	\ls | grep -v "~$" | while read file;
	do
		[[ "$file" =~ _dotfiles.bash ]] && continue
		target="$HOME/.$file"
		[ -e "$target" ] && mv -f "$target" "$dotfiles_oldfolder/"
		case $platform in
		'linux') FLAG=T ;;
	esac
	ln -${FLAG}fvs "$(realpath "$file" )" "$target"
done
)

find "$dotfiles_oldfolder" -type d -empty | xargs rm -rvf

#######################
## install packages on new machine
#######################

packages=(git dos2unix wget curl)

case $platform in
'linux')
	sudo add-apt-repository -y ppa:git-core/ppa
	packages+=(apt-file)
	packages+=(bmon)
	packages+=(build-essential)
	packages+=(exuberant-ctags silversearcher-ag) # Coding tools
	packages+=(meld tig) # SVC tools
	packages+=(unzip)
	packages+=(manpages-dev manpages-posix-dev)
	packages+=(vim)
	packages+=(cmake) # vim YouCompleteMe
	packages+=(bikeshed)
	;;
'mac')
	packages+=(ctags)
	packages+=(python)
	packages+=(coreutils)
	;;
esac
install_pkg ${packages[@]}

#######################
## install vim plugins
#######################
mkdir -p ~/.backup vim/autoload
curl -fLo vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +PlugInstall +qa
find $HOME/.vim/ -name \*.vim -exec dos2unix -q {} \;


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
if [ -n "$USER" -a "$USER" != "root" ]; then
	sudo chown -R $USER:$GROUPS $HOME
fi

# auto cleanup old-kernels
if [[ -n "$(\which purge-old-kernels)" ]]; then
	sudo ln -fs $(\which purge-old-kernels) /etc/cron.daily/
	sudo purge-old-kernels
fi

