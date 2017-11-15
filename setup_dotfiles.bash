#!/bin/bash -x
if [[ $EUID -eq 0 ]]; then
	echo "This script must NOT be run as root" 1>&2
	exit 1
fi

## predefined functions
script_error_report() {
	local code="$?"
	local script="$1"
	local lineno="$2"
	local printnear=4
	start=$(($lineno - $printnear))
	start=$(($start > 0 ? $start : 1))
	end=$(($lineno + $printnear))
	echo "Error at file ${script}:${lineno}. Exit code: ${code}"
	sed -e 's/^/ /' -e $lineno's/^/>/' -e $start,$end'!d;=' "${script}" \
		| sed -e 'N;s/\(.*\)\n\(.\)/\2\1 /'
	exit "${code}"
}
trap 'script_error_report "${BASH_SOURCE[0]}" ${LINENO}' ERR
set -e

realpath() {
	[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# setup env and location
current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $current
source bashrc.d/get-platform
source /etc/lsb-release
DIST=${DISTRIB_CODENAME/serena/xenial}
DIST=${DIST/sonya/xenial}

#######################
## install pips & powerline
#######################
# Remove deprecated pyenv version powerline
rm -rf ~/.pyenv/
if ! hash pip2.7 2>/dev/null; then
	curl https://bootstrap.pypa.io/get-pip.py | sudo -H python
fi

if hash powerline-daemon 2>/dev/null; then
	powerline-daemon -k || true
fi
sudo -H LANG=C pip2.7 install -U -r requirements_dotfiles.txt

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

CL_V=4.0
packages=(git dos2unix wget curl)

case $platform in
'linux')
	check_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
	# aptitude can solve depenency problem for clang-*
	install_pkg() { sudo aptitude install -y $@; }
	update_pkg_list() { sudo apt-get update; }

	# Add clang ${CL_V}
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
	packages+=(manpages-dev manpages-posix-dev)
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


# Clang config
if [ -f /usr/bin/clang-${CL_V} ]; then
	sudo ln -fs /usr/bin/clang-${CL_V} /usr/bin/clang
	sudo ln -fs /usr/bin/clang++-${CL_V} /usr/bin/clang++
fi

# auto cleanup old-kernels
if [[ -n "$(\which purge-old-kernels)" ]]; then
	sudo ln -fs $(\which purge-old-kernels) /etc/cron.daily/
	sudo purge-old-kernels
fi

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

