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
    tmp=$(mktemp)
    ag --hidden --ignore .git/ --ignore .tags --ignore "*~" --vimgrep "$@" > "$tmp"
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

#-------------------------------------------------------------
# customize PATH
#-------------------------------------------------------------
path=(
    "$HOME"/.local/bin
    "$HOME"/bin
    "$HOME"/.bin
    "$HOME"/.poetry/bin
    "$HOME"/.rbenv/bin
    "$HOME"/.pyenv/bin
    "$HOME"/.rbenv/shims
    "$HOME"/.pyenv/shims
    /usr/sbin
    /usr/local/bin
    node_modules/.bin
)
PATH="$(IFS=:; echo "${path[*]}"):$PATH"
unset path

if [[ -d $HOME/.pyenv/bin ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    eval "$(pyenv init -)"
fi


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
eval "$(dircolors -b "$HOME/.dircolors.ansi-universal")" || :

#-------------------------------------------------------------
# Prompt_command
#-------------------------------------------------------------
_bash_history_sync() {
    builtin history -a
    builtin history -r
}

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
    local ncolors
    ncolors=$(tput colors 2>/dev/null)
    if [[ $1 -eq 0 ]]; then
        local status=success
        local color_status="\e[0;32m"
        local color_cmd="\e[7m"
    else
        local color_status="\e[0;31m"
        local color_cmd="\e[00m\e[3;41m"
        local status="failed with code ${color_cmd}${1}${color_status}"
    fi
    local color_reset="\e[00m"
    if [[ ${ncolors:=0} -lt 8 ]]; then
        color_status=""
        color_cmd=""
        color_reset=""
    fi
    echo -e "${color_status}#### Command ${color_cmd}$_cmd${color_status} ${status} ${str_dur} #### ${color_reset}"
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
        SECONDS=0
        _bash_history_sync
        _cmd=
    else
        r=0
    fi
    _last_cmd=$_cmd
    _last_r=$r

    return $r
}

if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="POST_COMMAND"
elif [[ "$PROMPT_COMMAND" != *"POST_COMMAND"* ]]; then
    PROMPT_COMMAND=$'POST_COMMAND\n'"$PROMPT_COMMAND"
fi

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
list+=("$HOME"/.bashrc.d/!(*~))
list+=("$HOME"/.bashrc_local)
for file in "${list[@]}"; do
    if [ -f "$file" ]; then
        # shellcheck source=/dev/null
        source "$file"
    fi
done
unset list
[ "$e" = "e" ] && set -e && unset e # restore -e flag

__py_envs_cd_set() {
    if [[ -z "$PIPENV_ACTIVE" ]] && [[ -f "Pipfile" ]]; then
        echo Active pipenv
        export PIPENV_IGNORE_VIRTUALENVS=1
        # shellcheck source=/dev/null
        source "$(pipenv --venv)/bin/activate"
    elif [[ -f poetry.lock ]] && [[ -n "$(poetry env info -p)" ]]; then
        penv="$(poetry env info -p)"
        if [[ -n "$penv" ]]; then
            echo Active "$penv"
            # shellcheck source=/dev/null
            source "$penv/bin/activate"
        else
            echo Active poetry failed, empty 'poetry env info -p'
        fi
    fi
}

# shellcheck source=/dev/null
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
if [[ -f /usr/local/bin/cdhist ]] && type -t __zsh_like_cd > /dev/null 2>&1 ; then
    echo install cdhist, __py_envs_cd_set with rvm hooks
    if ! printf '%s\0' "${chpwd_functions[@]}" | grep -Fxqz -- '__py_envs_cd_set'; then
        chpwd_functions=( "${chpwd_functions[@]}" __py_envs_cd_set )
    fi
    # merge cdhist and rvm wraper
    cd() {
        local d
        if ! d=$(/usr/local/bin/cdhist "$@"); then
            return 0
        fi

        __zsh_like_cd cd "$d"
    }
fi

# Powerline prompt
# shellcheck disable=SC2154
if [[ $(who am i) =~ \([0-9a-z.\-]+\)$ \
        || "$platform" == "mac" \
        || "$platform" == "linux" \
        || "$TMUX" != "" \
        || "$SUDO_USER" != "" ]]; then
    PATH="$PATH:$(PYENV_VERSION=system python3 -c "import sysconfig; print(sysconfig.get_path('scripts'))")"
    for site in $(PYENV_VERSION=system python3 -c 'import site; print(" ".join(site.getsitepackages()))')
    do
        powerline="$site/powerline/bindings/bash/powerline.sh"
        if [ -f "$powerline" ]; then
            echo "$powerline"
            powerline-daemon -q || true
            # shellcheck disable=SC2034
            POWERLINE_BASH_CONTINUATION=1
            # shellcheck disable=SC2034
            POWERLINE_BASH_SELECT=1
            # shellcheck source=/dev/null
            source "$powerline"
            # update tmux config
            sed --follow-symlinks -i "s@source .*/powerline/bindings/tmux/powerline.conf@source $site/powerline/bindings/tmux/powerline.conf@" ~/.tmux.conf
            break
        fi
    done
fi
unset srcfiles powerline

#-------------------------------------------------------------
# dedup PATH
#-------------------------------------------------------------
PATH="$(echo -e "${PATH//:/\\n}" | awk '!x[$0]++' | paste -sd ":" -)"

# pnpm
export PNPM_HOME="/home/jethro/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
