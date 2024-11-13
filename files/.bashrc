#!/bin/bash
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
export -a chpwd_functions

_add_prompt_command() {
    local action="$1"
    shift
    local cmd="$1"
    shift
    # skip the command if it already exists
    if echo -e "$PROMPT_COMMAND" | grep -q "$cmd"; then
        return
    fi
    if test "$action" = "append"; then
        PROMPT_COMMAND="$PROMPT_COMMAND"$'\n'"$cmd"
    else
        PROMPT_COMMAND="$cmd"$'\n'"$PROMPT_COMMAND"
    fi
}
#-------------------------------------------------------------
# Show dotfile changes at login
#-------------------------------------------------------------
if hash greadlink 2>/dev/null; then readlink=greadlink; fi
if hash readlink 2>/dev/null; then readlink=readlink; fi

if ! [[ ${BASH_SOURCE[0]} == *"/dev/fd/"* ]]; then
    d=$(dirname "$($readlink -f "${BASH_SOURCE[0]}")")
    if [[ -d $d/../.git ]]; then
        (
            cd "$d/.."
            git diff --stat
        )
    fi
fi

function stacktrace {
    local size=${#BASH_SOURCE[@]}
    i=0
    for (( ; i < size - 1; i++)); do ## -1 to exclude main()
        read -r line func file < <(caller $i)
        echo >&2 "[$i] $file +$line $func(): $(sed -n "${line}p" "$file")"
    done
}
#-------------------------------------------------------------
# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
#-------------------------------------------------------------
shopt -s checkwinsize

#-------------------------------------------------------------
# Set Default keybinding
#------------------------------------------------
if [[ -z "$INPUTRC" ]] && [[ ! -f "$HOME/.inputrc" ]]; then
    export INPUTRC=/etc/inputrc
fi

#-------------------------------------------------------------
# tailoring 'less'
#-------------------------------------------------------------
alias more='less'
export EDITOR=vim
export PAGER='less'
export LESS='-i -z-4 -MFXRS -x4'
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
    tmp=$(mktemp)
    ag --hidden --ignore .git/ --ignore .tags --ignore "*~" --vimgrep "$@" >"$tmp"
    vim -c "cfile $tmp" -c "1bd"
    rm -f "$tmp"
}

dswap() {
    # Swap 2 filenames around, if they exist
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

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
    # auto complete ssh-multi.sh as same as ssh
    if [[ -f /usr/share/bash-completion/completions/ssh ]]; then
        . /usr/share/bash-completion/completions/ssh
    fi
    if command -v ssh-multi.sh >/dev/null; then
        shopt -u hostcomplete && complete -F _ssh ssh-multi.sh
    fi
fi

#-------------------------------------------------------------
# Set colorful PS1 only on colorful terminals.
#-------------------------------------------------------------
eval "$(dircolors -b "$HOME/.config/gruvbox.dircolors")" || :

#-------------------------------------------------------------
# History
#-------------------------------------------------------------
shopt -s cmdhist
export TIMEFORMAT=$'\nreal %3R\tuser %3U\tsys %3S\tpcpu %P\n'
export HOSTFILE=$HOME/.hosts # Put list of remote hosts in ~/.hosts ...

# HSTR configuration - add this to ~/.bashrc
alias hh=hstr                   # hh to be alias for hstr
export HSTR_CONFIG=hicolor      # get more colors
shopt -s histappend             # append new history items to .bash_history
export HISTCONTROL=ignorespace  # leading space hides commands from history
export HISTFILESIZE=10000       # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE} # increase history size (default is 500)
# ensure synchronization between bash memory and history file
_add_prompt_command append 'history -a;history -n'

function hstrnotiocsti {
    { READLINE_LINE="$({ hstr </dev/tty "${READLINE_LINE}"; } 2>&1 1>&3 3>&-)"; } 3>&1
    READLINE_POINT=${#READLINE_LINE}
}
# if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
if [[ $- =~ .*i.* ]]; then bind -x '"\C-r": "hstrnotiocsti"'; fi
export HSTR_TIOCSTI=n

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
else
    export DISPLAY
    DISPLAY="$(tmux show-env | sed -n 's/^DISPLAY=//p')"
fi

#-------------------------------------------------------------
# thefuck
#-------------------------------------------------------------
if hash thefuck 2>/dev/null; then
    eval "$(thefuck --alias)"
fi

#-------------------------------------------------------------
# direnv https://direnv.net/docs/hook.html
#-------------------------------------------------------------
eval "$(direnv hook bash)"

#-------------------------------------------------------------
# kitty intergration
#-------------------------------------------------------------
get() {
    echo -ne "\033];__pw:${PWD}\007"
    for file in "$@"; do echo -ne "\033];__rv:${file}\007"; done
    echo -ne "\033];__ti\007"
}
winscp() { echo -ne "\033];__ws:${PWD}\007"; }

#-------------------------------------------------------------
# Report command takes long time
#-------------------------------------------------------------
_beep() {
    paplay /usr/share/sounds/sound-icons/finish --volume=60000
}

timer_start() {
    timer=${timer:-$SECONDS}
}

command_timer_stop() {
    local show_timer_after=30
    local duration=$((SECONDS - ${command_timer:-$SECONDS}))
    local str_dur=""
    if [[ $duration -gt $show_timer_after ]]; then
        local hours=$((duration / 3600))
        local mins=$(((duration % 3600) / 60))
        local secs=$((duration % 60))
        if ((duration >= 3600)); then
            str_dur=$(printf "(%02g:%02g:%02g)" $hours $mins $secs)
        elif ((duration >= 60)); then
            str_dur=$(printf "(%02g:%02g)" $mins $secs)
        else
            str_dur=$(printf "(%s sec)" $secs)
        fi
    fi
    if [[ -z "$str_dur" ]] && [[ $1 -eq 0 ]]; then
        return "$1"
    fi
    # Print on error or wainting too long
    # Get the number of colors supported by the terminal
    local ncolors
    ncolors=$(tput colors 2>/dev/null)

    # Define color codes and status based on the first argument
    if [[ $1 -eq 0 ]]; then
        local color_status="\e[0;32m" # Green for success
        local color_cmd="\e[7m"       # Reversed colors for command
        local status="success"
    else
        local color_status="\e[0;31m" # Red for failure
        local color_cmd="\e[1;33m"    # Normal text on red background for command
        local status="failed with code [${color_cmd}${1}${color_status}]"
    fi

    # Reset color code
    local color_reset="\e[00m"

    # If the terminal supports less than 8 colors, don't use color codes
    if [[ ${ncolors:=0} -lt 8 ]]; then
        color_status=""
        color_cmd=""
        color_reset=""
    fi

    # Display the command status
    echo -e "${color_status}▶ Command [${color_cmd}$_cmd${color_status}] ${status} ${str_dur}${color_reset}"

    if [[ "$_cmd" == vim* ]] || [[ "$_cmd" == ssh* ]]; then
        return
    fi
    if [[ $duration -gt $show_timer_after ]]; then
        if [[ "$1" == "0" ]]; then
            (_beep "Done" "$_cmd" "$str_dur" &)
        else
            (_beep "E($1)" "$_cmd" "$str_dur" &)
        fi
    fi
}

set_screen_title() {
    echo -ne "\ek$1\e\\"
}

command_tracking_start() {
    if [[ "$PROMPT_COMMAND" == *"$BASH_COMMAND"* || "$BASH_SUBSHELL" != 0 ]]; then
        return
    fi
    command_timer=$SECONDS
    _cmd="$BASH_COMMAND"
    echo -ne "\033]0;${_cmd::20}\007"
}
while trap -p | grep -q command_tracking_start; do trap - DEBUG; done
trap 'command_tracking_start' DEBUG

command_tracking_end() {
    local r=$?

    if [[ -n "$_cmd" ]]; then
        command_timer_stop $r
        SECONDS=0
        _cmd=
    else
        r=0
    fi
    _last_cmd=$_cmd
    _last_r=$r

    return $r
}

_add_prompt_command append "command_tracking_end"

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

export DOCKER_BUILDKIT=1

if [ -f ~/bin/vault ]; then
    complete -C ~/bin/vault vault
fi
if [ -f /usr/local/bin/mc ]; then
    complete -C /usr/local/bin/mc mc
fi

#-------------------------------------------------------------
# import scripts
#-------------------------------------------------------------
[[ "$-" == *e* ]] && set +e && e=e # store -e flag when sourcing external resource
shopt -s extglob
list=()
list+=(/etc/bashrc)
# /etc/bashrc need to run after bashrc.d
rm -f "$HOME"/.bashrc.d/*~
list+=("$HOME"/.bashrc.d/*)
list+=("$HOME"/.bashrc_local)
touch "$HOME"/.bashrc_local
# sort the list
readarray -t list < <(printf "%s\n" "${list[@]}" | sort)
for file in "${list[@]}"; do
    if [ -f "$file" ]; then
        echo "source $file"
        # shellcheck source=/dev/null
        source "$file"
    fi
done
unset list

[[ "$e" == "e" ]] && set -e && unset e # restore -e flag

export cdhist_file="$HOME/.cd_history"

touch "$cdhist_file"
cdhist() {
    local path="$1"
    echo "$path" >>"$cdhist_file"
}

_log_cd_path() {
    cdhist "$PWD"
}

[[ " ${chpwd_functions[*]} " == *" _log_cd_path "* ]] || chpwd_functions+=(_log_cd_path)

cd_widget() {
    tac "$cdhist_file" \
        | awk '!x[$0]++' \
        | while read -r line; do
            timeout 0.5 test -d "$line" && echo "$line"
        done \
        | head -n 300 \
        | tac \
        | sponge "$cdhist_file"
    cd_target="$(percol --prompt-bottom --result-bottom-up --reverse "$cdhist_file")"
    if ((${#cd_target} != 0)); then
        cd "$cd_target"
    fi
}

bind '"\M-c": "cd_widget\C-m"'

# Powerline prompt
# shellcheck disable=SC2154
init_powerline() {
    if [[ $(who am i) =~ \([0-9a-z.\-]+\)$ || "$platform" == "mac" || "$platform" == "linux" || "$TMUX" != "" || "$SUDO_USER" != "" ]]; then
        PATH="$PATH:$(PYENV_VERSION=system python3 -c "import sysconfig; print(sysconfig.get_path('scripts'))")"
        mapfile -t sites < <(PYENV_VERSION=system python3 -c 'import site; print(" ".join(site.getsitepackages()))')
        sites=(/usr/share "${sites[@]}")
        for site in "${sites[@]}"; do
            powerline="$site/powerline/bindings/bash/powerline.sh"
            if [ -f "$powerline" ]; then
                echo "Powerline found at $powerline"
                powerline-daemon -q || true
                # shellcheck disable=SC2034
                POWERLINE_BASH_CONTINUATION=1
                # shellcheck disable=SC2034
                POWERLINE_BASH_SELECT=1
                # shellcheck source=/dev/null
                source "$powerline"
                break
            else
                echo "No powerline at $powerline"
            fi
        done
    fi
    unset srcfiles powerline
}

export PYTHONSTARTUP=~/.pythonrc

if [ -n "$TMUX" ]; then

    # render /etc/issue or else fall back to kernel/system info
    agetty --show-issue 2>/dev/null || uname -a

    # message of the day
    for motd in /run/motd.dynamic /etc/motd; do
        if [ -s "$motd" ]; then
            cat "$motd"
            break
        fi
    done

    # last login
    last "$USER" | awk 'NR==2 {
    if (NF==10) { i=1; if ($3!~/^:/) from = " from " $3 }
    printf("Last login: %s %s %s %s%s on %s\n",
      $(3+i), $(4+i), $(5+i), $(6+i), from, $2);
    exit
  }'

    # mail check
    if [ -s "/var/mail/$USER" ]; then # may need to change to /var/spool/mail/$USER
        echo "You have $(grep -c '^From ' "/var/mail/$USER") mails."
    else
        echo "You have no mail."
    fi
fi

init_powerline

# append a command at the last line, inside curly brackets  of function _powerline_prompt
original_function=$(declare -f _powerline_prompt)
APPEND_LINE='echo -n " "'
if [[ $original_function != *"$APPEND_LINE"* ]]; then
    eval "$(echo "$original_function" | sed -e "/^}$/i$APPEND_LINE")"
fi

#-------------------------------------------------------------
# customize PATH
#-------------------------------------------------------------

# the latter path will be added to the front of PATH
prepend_custom_path() {
    local custom_paths
    custom_paths=(
        /usr/sbin
        /usr/local/go/bin
        /usr/local/bin
        /home/linuxbrew/.linuxbrew/bin
        "${KREW_ROOT:-$HOME/.krew}/bin"
        "$HOME"/.bin
        "$HOME"/.local/bin
        "$HOME"/.cargo/bin
        "$HOME"/.local/share/JetBrains/Toolbox/apps
    )
    # filter out non-exist path
    for p in "${custom_paths[@]}"; do
        if [[ -d $p ]]; then
            PATH="$p:$PATH"
        fi
    done
}
prepend_custom_path

# Created by `pipx` on 2024-10-18 04:15:36
export PATH="$PATH:$HOME/.local/bin"

#-------------------------------------------------------------
# *env Setup
#-------------------------------------------------------------
eval "$("$HOME/.local/bin/mise" activate bash)"
export MISE_POETRY_AUTO_INSTALL=1 # Automatically run poetry install to create the virtualenv

#-------------------------------------------------------------
# dedup PATH
#-------------------------------------------------------------
PATH="$(echo -e "${PATH//:/\\n}" | awk '!x[$0]++' | paste -sd ":" -)"
export PATH="$HOME/.local/bin:$PATH"
removepath() {
    local path="$1"
    PATH="$(echo -e "${PATH//:/\\n}" | grep -v "$path" | paste -sd ":" -)"
    export PATH
}
