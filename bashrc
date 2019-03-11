# vim: set wrap tabstop=4 shiftwidth=4 softtabstop=0 expandtab :
# vim: set textwidth=0 filetype=sh foldmethod=manual nospell :
# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* && ${setupdotfile:-} == "" ]]; then
	# Shell is non-interactive.  Be done now!
	return
fi

#export LANGUAGE="zh_TW.UTF-8"
#export LANG="zh_TW.UTF-8"
export LC_TIME="en_US.utf8"
#export LC_CTYPE="zh_TW.UTF-8"
export LC_COLLATE=C
#-------------------------------------------------------------
# Show dotfile changes at login
#-------------------------------------------------------------
if hash greadlink 2>/dev/null; then readlink=greadlink; fi
if hash readlink 2>/dev/null; then readlink=readlink; fi

if ! [[ ${BASH_SOURCE[0]} == *"/dev/fd/"* ]]; then
    current="$(
        cd "$(dirname "$($readlink -f "${BASH_SOURCE[0]}")")"
        pwd
    )"
    (
        cd "$current"
        pwd
        git diff --stat
    )
fi

#-------------------------------------------------------------
# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
#-------------------------------------------------------------
shopt -s checkwinsize

#-------------------------------------------------------------
# Auto load ssh agent
#-------------------------------------------------------------
if [ ${#SSH_AGENT_PID} -eq 0 ] || ! kill -0 ${SSH_AGENT_PID:-0}; then
	export SSH_AUTH_SOCK=$HOME/.tmp/ssh-agent.sock
	mkdir -p "$HOME/.tmp"
	rm -f "$HOME/.tmp/ssh-agent.sock"
	eval $(ssh-agent -s -a $SSH_AUTH_SOCK) >/dev/null
	ssh-add >&/dev/null
fi

#-------------------------------------------------------------
# Set Default keybinding
#-------------------------------------------------------------
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ]; then
	export INPUTRC=/etc/inputrc
fi

#-------------------------------------------------------------
# tailoring 'less'
#-------------------------------------------------------------
alias more='less'
export EDITOR=vim
export PAGER='less'
export LESS='-i -z-4 -MFXRS -x4 --quit-if-one-screen'
export LESSCHARDEF="8bcccbcc18b95.."
export LESS_TERMCAP_mb='[1;31m' # begin blinking
export LESS_TERMCAP_md='[4;32m' # begin bold
export LESS_TERMCAP_me='[0m'    # end mode
export LESS_TERMCAP_so='[0;31m' # begin standout-mode - info box
export LESS_TERMCAP_se='[0m'    # end standout-mode
export LESS_TERMCAP_us='[0;33m' # begin underline
export LESS_TERMCAP_ue='[0m'    # end underline
export LSCOLORS=ExGxFxdxCxDxDxBxBxExEx

#-------------------------------------------------------------
# File & string-related functions:
#-------------------------------------------------------------

vag() {
	if [[ $1 == -rn ]]; then
		shift
	fi
	vim +cfile\ <(ag --hidden --ignore .git/ --ignore .tags --vimgrep "$@" | grep -v '~:')
}

# Find a file with a pattern in name:
ff() { find . -type f -iname '*'"$*"'*' -ls; }

# Find a file with pattern $1 in name and Execute $2 on it:
fe() { find . -type f -iname '*'"${1:-}"'*' -exec "${2:-file}" {} \;; }

swap() { # Swap 2 filenames around, if they exist
	#(from Uzi's bashrc).
	local TMPFILE=tmp.$$

	[ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
	[ ! -e "$1" ] && echo "swap: $1 does not exist" && return 1
	[ ! -e "$2" ] && echo "swap: $2 does not exist" && return 1

	mv "$1" $TMPFILE
	mv "$2" "$1"
	mv $TMPFILE "$2"
}

extract() { # Handy Extract Program.
	if [ -f "$1" ]; then
		case "$1" in
		*.tar.bz2) tar xvjf "$1" ;;
		*.tar.gz) tar xvzf "$1" ;;
		*.bz2) bunzip2 "$1" ;;
		*.rar) unrar x "$1" ;;
		*.gz) gunzip "$1" ;;
		*.tar) tar xvf "$1" ;;
		*.tbz2) tar xvjf "$1" ;;
		*.tgz) tar xvzf "$1" ;;
		*.zip) unzip "$1" ;;
		*.Z) uncompress "$1" ;;
		*.7z) 7z x "$1" ;;
		*) echo "'$1' cannot be extracted via >extract<" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

jcrm() {
	queue="."
	while [ -n "$queue" ]; do
		echo "$queue" | xargs -I'{}' find "{}" -mindepth 1 -maxdepth 1 -type f \
			\( -name "*~" -o -name "*.core" -o -name "*.gch" -o -name "*.swp" -o -name "*.orig" -o -regex ".*\.nfs.*$" \) -print -delete
		queue=$(echo "$queue" | xargs -I'{}' find {} -mindepth 1 -maxdepth 1 -type d)
	done
	unset queue
}

#-------------------------------------------------------------
# import scripts
#-------------------------------------------------------------
[[ "$-" == *e* ]] && set +e && e=e # store -e flag when sourcing external resource
shopt -s extglob
list=()
list+=(/etc/bashrc)
# /etc/bashrc need to run after bashrc.d
list+=($HOME/.bashrc.d/!(*~))
list+=($HOME/.bashrc_local)
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
for file in "${list[@]}"; do
	if [ -f "$file" ]; then
		source "$file"
	fi
done
unset list
[ "$e" = "e" ] && set -e && unset e # restore -e flag

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

#-------------------------------------------------------------
# customize PATH
#-------------------------------------------------------------
path="$path $HOME/bin"
path="$path $HOME/.bin"
path="$path $HOME/.local/bin"
path="$path /usr/local/bin"
path="$path /usr/sbin"
for a in $path; do
	if [[ -d "$a" && ! ":$PATH:" == *":$a:"* ]]; then
		export PATH="$a:$PATH"
	fi
done
unset path

#-------------------------------------------------------------
# Set colorful PS1 only on colorful terminals.
#-------------------------------------------------------------
eval "$(dircolors -b "$HOME/.dircolors.ansi-universal")" || :

#-------------------------------------------------------------
# Prompt_command
#-------------------------------------------------------------
_bash_history_sync() {
	builtin history -a
	builtin history -n
}

# Powerline prompt

srcfiles=(
	/home/$SUDO_USER/.local/lib/python*/site-packages/powerline/bindings/bash/powerline.sh
	$HOME/.local/lib/python*/site-packages/powerline/bindings/bash/powerline.sh
	/usr/local/lib/python*/dist-packages/powerline/bindings/bash/powerline.sh
	/Library/Python/*/site-packages/powerline/bindings/bash/powerline.sh
)
for powerline in "${srcfiles[@]}"; do
	if [ -f "$powerline" ]; then
		powerline-daemon -q || true
		export POWERLINE_CONFIG_COMMAND="powerline-config"
		export POWERLINE_BASH_CONTINUATION=1
		export POWERLINE_BASH_SELECT=1
		source "$powerline"
		break
	fi
done
unset srcfiles powerline

#-------------------------------------------------------------
# History
#-------------------------------------------------------------
shopt -s cmdhist
export TIMEFORMAT=$'\nreal %3R\tuser %3U\tsys %3S\tpcpu %P\n'
export HOSTFILE=$HOME/.hosts   # Put list of remote hosts in ~/.hosts ...

# HSTR configuration - add this to ~/.bashrc
alias hh=hstr                  # hh to be alias for hstr
export HSTR_CONFIG=hicolor     # get more colors
shopt -s histappend            # append new history items to .bash_history
export HISTCONTROL=ignorespace # leading space hides commands from history
export HISTIGNORE='&:ls:[bf]g:exit:printf "\\033*'
export HISTFILESIZE=10000       # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE} # increase history size (default is 500)
# ensure synchronization between Bash memory and history file
# if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind '"\C-r": "\C-a hstr -- \C-j"'; fi
# if this is interactive shell, then bind 'kill last command' to Ctrl-x k
if [[ $- =~ .*i.* ]]; then bind '"\C-xk": "\C-a hstr -k \C-j"'; fi

#-------------------------------------------------------------
# mintty-colors-solarized (for windows::mintty)
#-------------------------------------------------------------
if type -P mintty &>/dev/null; then
	echo -ne '\e]10;#839496\a'   # Foreground   -> base0
	echo -ne '\e]11;#002B36\a'   # Background   -> base03
	echo -ne '\e]12;#93A1A1\a'   # Cursor       -> base1
	echo -ne '\e]4;0;#073642\a'  # black        -> Base02
	echo -ne '\e]4;8;#002B36\a'  # bold black   -> Base03
	echo -ne '\e]4;1;#DC322F\a'  # red          -> red
	echo -ne '\e]4;9;#CB4B16\a'  # bold red     -> orange
	echo -ne '\e]4;2;#859900\a'  # green        -> green
	echo -ne '\e]4;10;#586E75\a' # bold green   -> base01 *
	echo -ne '\e]4;3;#B58900\a'  # yellow       -> yellow
	echo -ne '\e]4;11;#657B83\a' # bold yellow  -> base00 *
	echo -ne '\e]4;4;#268BD2\a'  # blue         -> blue
	echo -ne '\e]4;12;#839496\a' # bold blue    -> base0 *
	echo -ne '\e]4;5;#D33682\a'  # magenta      -> magenta
	echo -ne '\e]4;13;#6C71C4\a' # bold magenta -> violet
	echo -ne '\e]4;6;#2AA198\a'  # cyan         -> cyan
	echo -ne '\e]4;14;#93A1A1\a' # bold cyan    -> base1 *
	echo -ne '\e]4;7;#EEE8D5\a'  # white        -> Base2
	echo -ne '\e]4;15;#FDFDE3\a' # bold white   -> Base3
fi

#-------------------------------------------------------------
# tmux
#-------------------------------------------------------------
if [ -z "$TMUX" ]; then
	[ -f /var/run/motd ] && cat /var/run/motd
fi
true

#-------------------------------------------------------------
# thefuck
#-------------------------------------------------------------
if hash thefuck 2>/dev/null; then
	eval "$(thefuck --alias)"
fi

#-------------------------------------------------------------
# kitty intergration
#-------------------------------------------------------------
get() {
	echo -ne "\033];__pw:${PWD}\007"
	for file in $*; do echo -ne "\033];__rv:${file}\007"; done
	echo -ne "\033];__ti\007"
}
winscp() { echo -ne "\033];__ws:${PWD}\007"; }

#-------------------------------------------------------------
# Report command takes long time
#-------------------------------------------------------------
timer_start() {
	timer=${timer:-$SECONDS}
}
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
	SESSION_TYPE=remote/ssh
else
	case $(ps -o comm= -p $PPID) in
	sshd | */sshd)
		SESSION_TYPE=remote/ssh
		;;
	esac
fi
command_timer_stop() {
	local show_timer_after=30
	local duration=$(($SECONDS - ${command_timer:-$SECONDS}))
	local str_dur=""
	if [ $duration -gt $show_timer_after ]; then
		# Sound after slow command
		if hash play 2>/dev/null; then
			(for i in {1..8}; do
				play -q -n synth 0.2 sine 800 vol 0.8
				sleep 0.2
			done 2>/dev/null &)
		fi
		local hours=$(($duration / 3600))
		local mins=$((($duration % 3600) / 60))
		local secs=$(($duration % 60))
		if (($duration >= 3600)); then
			str_dur=$(printf "(%02g:%02g:%02g (hh:mm:ss)) " $hours $mins $secs)
		elif (($duration >= 60)); then
			str_dur=$(printf "(%02g:%02g (mm:ss)) " $mins $secs)
		else
			str_dur=$(printf "(%s seconds) " $secs)
		fi
	fi
	if [ -z "$str_dur" -a $1 -eq 0 ]; then
		return $1
	fi
	# Print on error or wainting too long
	local ncolors=$(tput colors 2>/dev/null)
	if [ $1 -eq 0 ]; then
		local status=success
		local color_status="\e[0;32m"
		local color_cmd="\e[7m"
	else
		local color_status="\e[0;31m"
		local color_cmd="\e[00m\e[3;41m"
		local status="failed with code ${color_cmd}${1}${color_status}"
	fi
	local color_reset="\e[00m"
	if [ ${ncolors:=0} -lt 8 ]; then
		color_status=""
		color_cmd=""
		color_reset=""
	fi
	echo -e "${color_status}#### Command ${color_cmd}$_cmd${color_status} ${status} $str_dur#### ${color_reset}"
}

set_screen_title() {
	echo -ne "\ek$1\e\\"
}

BEBUG_TRAP() {
	if [[ "$PROMPT_COMMAND" == *"$BASH_COMMAND"* || "$BASH_SUBSHELL" != 0 ]]; then
		return
	fi
	command_timer=$SECONDS
	_cmd="$BASH_COMMAND"
	echo -ne "\033]0;${_cmd::20}\007"
}
while trap -p | grep -q BEBUG_TRAP; do trap - DEBUG; done
trap 'BEBUG_TRAP' DEBUG

POST_COMMAND() {
	local r=$?

	if [[ -n "$_cmd" ]]; then
		command_timer_stop $r
		_bash_history_sync
		_cmd=
	else
		r=0
	fi
	echo -ne "\033]0;${HOSTNAME}\007"
	_last_cmd=$_cmd
	_last_r=$r

	return $r
}

if [[ -z "$PROMPT_COMMAND" ]]; then
	PROMPT_COMMAND="POST_COMMAND"
elif [[ "$PROMPT_COMMAND" != *"POST_COMMAND"* ]]; then
	PROMPT_COMMAND="POST_COMMAND;$PROMPT_COMMAND"
fi

function path_unique() {
	export PATH="$(echo -e ${PATH//:/\\n} | awk '!x[$0]++' | paste -sd ":" -)"
}

# ensure X forwarding is setup correctly, even for screen
XAUTH=~/.Xauthority
if [[ ! -e "${XAUTH}" ]]; then
	# create new ~/.Xauthority file
	xauth q
fi
if [[ -z "${XAUTHORITY}" ]]; then
	# export env var if not already available.
	export XAUTHORITY="${XAUTH}"
fi
export DISPLAY=:0.0

function cd() {
	builtin \cd "$@"
	if [[ $? -eq 0 && -z "$PIPENV_ACTIVE" && -f "Pipfile" ]]; then
		source $(pipenv --venv)/bin/activate
	fi
}

export DOCKER_BUILDKIT=1
