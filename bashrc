# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* && $setupdotfile = "" ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

#-------------------------------------------------------------
# Show dotfile changes at login
#-------------------------------------------------------------
current="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"
(cd "$current"; pwd ; git status -uno)

#-------------------------------------------------------------
# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
#-------------------------------------------------------------
shopt -s checkwinsize

#-------------------------------------------------------------
# import other scripts
# ~/.zer0prompt         : preload color prompt
# ~/.rvm/scripts/rvm    : Load RVM into a shell session *as a function*
#-------------------------------------------------------------
for file in /etc/bashrc ~/.bash_aliases ~/.git-prompt.sh ~/.rvm/scripts/rvm ~/.get-platform
do
    [ -f $file ] && . $file
done

#-------------------------------------------------------------
# Change language by terminal (local console OR ssh ?)
#-------------------------------------------------------------
#export LC_ALL=zh_TW.UTF-8 LANG=zh_TW LANGUAGE=zh_TW

#-------------------------------------------------------------
# Change the window title of X terminals 
#-------------------------------------------------------------
#case ${TERM} in
#	xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
#		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
#		;;
#	screen)
#		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\033\\"'
#		;;
#esac


#-------------------------------------------------------------
# Set Default keybinding
#-------------------------------------------------------------
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
    export INPUTRC=/etc/inputrc
fi

#-------------------------------------------------------------
# tailoring 'less'
#-------------------------------------------------------------
alias more='less'
export EDITOR=vim
export PAGER='less'
export LESS='-i -z -4 -M -X -R'
export  LESSCHARDEF="8bcccbcc18b95.."
export  LESS_TERMCAP_mb='[1;31m'      # begin blinking
export  LESS_TERMCAP_md='[4;32m'      # begin bold
export  LESS_TERMCAP_me='[0m'         # end mode
export  LESS_TERMCAP_so='[0;31m'      # begin standout-mode - info box
export  LESS_TERMCAP_se='[0m'         # end standout-mode
export  LESS_TERMCAP_us='[0;33m'      # begin underline
export  LESS_TERMCAP_ue='[0m'         # end underline
export  LSCOLORS=ExGxFxdxCxDxDxBxBxExEx

#-------------------------------------------------------------
# File & string-related functions:
#-------------------------------------------------------------

# Find a file with a pattern in name:
function ff() { find . -type f -iname '*'$*'*' -ls ; }

# Find a file with pattern $1 in name and Execute $2 on it:
function fe()
{ find . -type f -iname '*'${1:-}'*' -exec ${2:-file} {} \;  ; }

# Find a pattern in a set of files and highlight them:
# (needs a recent version of egrep)
function fstr()
{
    OPTIND=1
    local case=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    find . -type f -name "${2:-*}" -print0 | \
    xargs -0 egrep --color=always -sn ${case} "$1" 2>&- | more

}

function cuttail() # cut last n lines in file, 10 by default
{
    nlines=${2:-10}
    sed -n -e :a -e "1,${nlines}!{P;N;D;};N;ba" $1
}

function lowercase()  # move filenames to lowercase
{
    for file ; do
        filename=${file##*/}
        case "$filename" in
        */*) dirname==${file%/*} ;;
        *) dirname=.;;
        esac
        nf=$(echo $filename | tr A-Z a-z)
        newname="${dirname}/${nf}"
        if [ "$nf" != "$filename" ]; then
            mv "$file" "$newname"
            echo "lowercase: $file --> $newname"
        else
            echo "lowercase: $file not changed."
        fi
    done
}


function swap()  # Swap 2 filenames around, if they exist
{                #(from Uzi's bashrc).
    local TMPFILE=tmp.$$

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e $1 ] && echo "swap: $1 does not exist" && return 1
    [ ! -e $2 ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

function extract()      # Handy Extract Program.
{
     if [ -f "$1" ] ; then
         case "$1" in
             *.tar.bz2)   tar xvjf "$1"     ;;
             *.tar.gz)    tar xvzf "$1"     ;;
             *.bz2)       bunzip2 "$1"      ;;
             *.rar)       unrar x "$1"      ;;
             *.gz)        gunzip "$1"       ;;
             *.tar)       tar xvf "$1"      ;;
             *.tbz2)      tar xvjf "$1"     ;;
             *.tgz)       tar xvzf "$1"     ;;
             *.zip)       unzip "$1"        ;;
             *.Z)         uncompress "$1"   ;;
             *.7z)        7z x "$1"         ;;
             *)           echo "'$1' cannot be extracted via >extract<" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

function jcrm ()
{
    queue="."
    while [ -n "$queue" ]
    do
	echo "$queue" | xargs -I'{}' find "{}" -mindepth 1 -maxdepth 1 -type f \
            \( -name "*~" -o -name "*.core" -o -name "*.gch" -o -name "*.swp" -o -name "*.orig" -o -regex ".*\.nfs.*$" \) -print -delete
	queue=`echo "$queue" | xargs -I'{}' find {} -mindepth 1 -maxdepth 1 -type d`
    done
    unset queue
}
#-------------------------------------------------------------
# Process/system related functions:
#-------------------------------------------------------------


function my_ps() { ps $@ -u $USER -o "pid,%cpu,%mem,bsdtime,command" ; }
function pp() { my_ps f | awk '!/awk/ && $0~var' var=${1:-".*"} ; }


function killps()                 # Kill by process name.
{
    local pid pname sig="-TERM"   # Default signal.
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: killps [-SIGNAL] pattern"
        return;
    fi
    if [ $# = 2 ]; then sig=$1 ; fi
    for pid in $(my_ps| awk '!/awk/ && $0~pat { print $1 }' pat=${!#} ) ; do
        pname=$(my_ps | awk '$1~var { print $5 }' var=$pid )
        if ask "Kill process $pid <$pname> with signal $sig?"
            then kill $sig $pid
        fi
    done
}

#-------------------------------------------------------------
# import completions
#-------------------------------------------------------------
[[ "$-" = *x* ]] && set +x && x=x # store -x flag when sourcing external resource
[[ "$-" = *e* ]] && set +e && e=e # store -e flag when sourcing external resource
for file in \
    /etc/bash_completion \
    ~/.git-completion.bash
do
    if [ -f $file ]; then
        . $file
    fi
done
[ "$x" = "x" ] && set -x && unset x # restore -x flag
[ "$e" = "e" ] && set -e && unset e # restore -e flag
## my addition
__expand_tilde_by_ref()
{
    return 0;
}

#-------------------------------------------------------------
# Add CDPATH for local trunk
#-------------------------------------------------------------
if [ -d ~/trunk ] && [[ ":$CDPATH:" != *":~/trunk:"* ]]; then
    export CDPATH="$CDPATH:~/trunk"
fi
# remove posfix ':'
[[ "$CDPATH" = :* ]] && export CDPATH="${CDPATH#:}"

#-------------------------------------------------------------
# customize PATH
#-------------------------------------------------------------
path="$path $HOME/bin"
path="$path $HOME/.bin"
path="$path $HOME/.local/bin"
path="$path /android-cts/tools"
path="$path /android-sdk-linux_x86/tools"
for a in $path
do
    [ -d "$a" ] && [ ":$PATH:" = ":${PATH/:$a:/}:" ] &&
    export PATH="$PATH:$a"
done
unset path

#-------------------------------------------------------------
# Insert pyenv PATH
#-------------------------------------------------------------
export PYENV_ROOT="${HOME}/.pyenv"

if [ -d "${PYENV_ROOT}" ]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init -)"
fi


#-------------------------------------------------------------
# Try to keep environment pollution down, EPA loves us.
#-------------------------------------------------------------
unset use_color safe_term match_lhs 

#-------------------------------------------------------------
# import local setting
#-------------------------------------------------------------
[ -e ~/.bashrc_local ] && . ~/.bashrc_local

#-------------------------------------------------------------
# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
#-------------------------------------------------------------
use_color=false

safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dircolors.256dark   ]] && match_lhs="$(<~/.dircolors.256dark)"
[[ -z ${match_lhs}    ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
	# Enable colors for ls, etc.  Prefer ~/.dircolors.256dark #64489
	if type -P dircolors >/dev/null ; then
		if [[ -f ~/.dircolors.256dark ]] ; then
			eval $(dircolors -b ~/.dircolors.256dark)
		fi
	fi
	#alias ls='ls --color=auto'
	#alias grep='grep --colour=auto'
else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \# '
	else
		PS1='\u@\h \w \$ '
	fi
fi

#-------------------------------------------------------------
# Prompt_command
#-------------------------------------------------------------
_bash_history_sync() {
    builtin history -a
    HISTFILESIZE=$HISTSIZE
    builtin history -c
    builtin history -r
}
PROMPT_COMMAND=_bash_history_sync

for file in \
    /usr/local/lib/python2.?/site-packages/powerline/bindings/bash/powerline.sh \
    ~/.local/lib/python2.?/site-packages/powerline/bindings/bash/powerline.sh
do
    if [[ $(who am i) =~ \([0-9a-z.\-]+\)$ || "$platform" = "mac" ]]; then
        # Powerline prompt
        [ -e $file ] && powerline=$(find $file -path '*/bash/powerline.sh')
        if [ -f "$powerline" ]; then
            powerline-daemon -q
            POWERLINE_BASH_CONTINUATION=1
            POWERLINE_BASH_SELECT=1
            source "$powerline"
        fi
    fi
done

#-------------------------------------------------------------
# History
#-------------------------------------------------------------
# Enable history appending instead of overwriting.  #139609
shopt -s histappend

shopt -s cmdhist

export TIMEFORMAT=$'\nreal %3R\tuser %3U\tsys %3S\tpcpu %P\n'
export HISTIGNORE="&:ls:[bf]g:exit"
export HOSTFILE=$HOME/.hosts    # Put list of remote hosts in ~/.hosts ...
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries


# mintty-colors-solarized
if type -P mintty &>/dev/null;then
    echo -ne   '\e]10;#839496\a'  # Foreground   -> base0
    echo -ne   '\e]11;#002B36\a'  # Background   -> base03

    echo -ne   '\e]12;#93A1A1\a'  # Cursor       -> base1

    echo -ne  '\e]4;0;#073642\a'  # black        -> Base02
    echo -ne  '\e]4;8;#002B36\a'  # bold black   -> Base03
    echo -ne  '\e]4;1;#DC322F\a'  # red          -> red
    echo -ne  '\e]4;9;#CB4B16\a'  # bold red     -> orange
    echo -ne  '\e]4;2;#859900\a'  # green        -> green
    echo -ne '\e]4;10;#586E75\a'  # bold green   -> base01 *
    echo -ne  '\e]4;3;#B58900\a'  # yellow       -> yellow
    echo -ne '\e]4;11;#657B83\a'  # bold yellow  -> base00 *
    echo -ne  '\e]4;4;#268BD2\a'  # blue         -> blue
    echo -ne '\e]4;12;#839496\a'  # bold blue    -> base0 *
    echo -ne  '\e]4;5;#D33682\a'  # magenta      -> magenta
    echo -ne '\e]4;13;#6C71C4\a'  # bold magenta -> violet
    echo -ne  '\e]4;6;#2AA198\a'  # cyan         -> cyan
    echo -ne '\e]4;14;#93A1A1\a'  # bold cyan    -> base1 *
    echo -ne  '\e]4;7;#EEE8D5\a'  # white        -> Base2
    echo -ne '\e]4;15;#FDFDE3\a'  # bold white   -> Base3
fi

# TMUX
if [ -z "$TMUX" ]; then 
    [ -f /var/run/motd ] && cat /var/run/motd
fi
true
