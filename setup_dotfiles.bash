#!/bin/bash -ex
if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root" 1>&2
	exit 1
fi
script_error_report() {
	set +x
	local script="$1"
	local parent_lineno="$2"
	local message="$3"
	local code="${4:-1}"
	echo "Error near ${script} line ${parent_lineno}; exiting with status ${code}"
	if [[ -n "$message" ]] ; then
		echo -e "Message: ${message}"
	fi
	exit "${code}"
}
trap 'script_error_report "${BASH_SOURCE[0]}" ${LINENO}' ERR

# Setup for password-less sudo
if [ -n "$USER" -a "$USER" != "root" -a ! -f /etc/sudoers.d/50_${USER}_sh ]; then
	sudo mkdir -p /etc/sudoers.d
	echo "Add NOPASSWD for user, required by functional test to replace /etc/hcfs.conf"
	sudo grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers || (echo "#includedir /etc/sudoers.d" | sudo tee -a /etc/sudoers)
	( umask 226 && echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/50_${USER}_sh )
fi

realpath() {
	[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current
source bashrc.d/get-platform

# Disable DNS resolution to speedup ssh
if [ -f /etc/ssh/sshd_config ]; then
	sudo sed -i -e "s:^#\?UseDNS yes:UseDNS no:" /etc/ssh/sshd_config
	grep "UseDNS no" /etc/ssh/sshd_config || echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config
fi

#######################
## Delete dead links
#######################

sudo find -L ~ -maxdepth 1 -type l -print -delete

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

CL_V=4.0
packages=(git dos2unix wget curl)

case $platform in
'linux')
	check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
	# aptitude can solve depenency problem for clang-*
	install_pkg() { sudo aptitude install -y $@; } 
	update_pkg_list() { sudo apt-get update; }

	# Add clang ${CL_V}
	source /etc/lsb-release
	DIST=$DISTRIB_CODENAME
	if ! test -f /etc/apt/sources.list.d/llvm.list; then
		cat <<-EOF |
		deb http://apt.llvm.org/${DIST}/ llvm-toolchain-${DIST}-${CL_V} main
		deb-src http://apt.llvm.org/${DIST}/ llvm-toolchain-${DIST}-${CL_V} main
		EOF
		sudo tee /etc/apt/sources.list.d/llvm.list
	fi
	curl http://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
	packages+=(clang-${CL_V} clang-format-${CL_V} libclang-${CL_V}-dev)

	packages+=(apt-file)
	packages+=(bmon)
	packages+=(build-essential)
	packages+=(exuberant-ctags silversearcher-ag) # Coding tools
	packages+=(meld tig) # SVC tools
	packages+=(unzip)
	packages+=(manpages-dev manpages-posix-dev manpages-zh)
	if lsb_release -a | grep 14.04; then
		packages+=(vim)
	else
		packages+=(vim-nox-py2)
	fi
	packages+=(cmake) # vim YouCompleteMe
	packages+=(bikeshed)
	;;
'mac')
	check_pkg() { brew list -1 | grep -q "^${1}\$"; }
	install_pkg() { brew install $@; }
	update_pkg_list() { :; }
	if ! brew help > /dev/null; then
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	packages+=(ctags)
	packages+=(python)
	packages+=(coreutils)
	;;
esac


list=""
for P in "${packages[@]}"; do
	if ! check_pkg $P; then
		list+=" $P"
	fi
done
[ -n "$list" ] && update_pkg_list && install_pkg $list

if [ -f /usr/bin/clang-${CL_V} ]; then
	sudo ln -fs /usr/bin/clang-${CL_V} /usr/bin/clang
	sudo ln -fs /usr/bin/clang++-${CL_V} /usr/bin/clang++
fi

# auto cleanup old-kernels
if [[ -n "$(\which purge-old-kernels)" ]]; then
	sudo ln -fs $(\which purge-old-kernels) /etc/cron.daily/
fi
sudo purge-old-kernels

#######################
## install vim plugins
#######################
mkdir -p vim/autoload
curl -fLo vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vim +PlugInstall +qa
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
export LANG=C
if hash pip 2>/dev/null; then
	sudo -H LANG=C pip install -U pip
else
	# install pip
	#[[ $platform == 'mac' ]]
	if [[ $platform == 'linux' ]]; then
		curl https://bootstrap.pypa.io/get-pip.py | sudo python
		hash -r
	fi
fi

hash powerline-daemon && powerline-daemon -k || :
sudo -H LANG=C pip install --upgrade -r requirements_dotfiles.txt


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
		| { cat; echo "@daily $current/git_update_dotfiles.bash"; } \
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

