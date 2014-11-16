#===============================================================
#
# ALIASES AND FUNCTIONS
#
# Arguably, some functions defined here are quite big.
# If you want to make this file smaller, these functions can
# be converted into scripts and removed from here.
#
# Many functions were taken (almost) straight from the bash-2.04
# examples.
#
#===============================================================

#-------------------
# Personnal Aliases
#-------------------

. get-platform

alias ssh='LC_ALL=en_US.UTF-8 ssh'
alias aa='vim ~/.bashrc && source ~/.bashrc'
alias as='vim ~/.bash_aliases && source ~/.bashrc'
alias an='source ~/.bashrc'
alias zz='vim ~/.vimrc'

alias rm='rm -ri'
alias cp='cp -ri'
alias mv='mv -i'
# -> Prevents accidentally clobbering files.
alias mkdir='mkdir -p'

alias h='history'
alias j='jobs -l'
alias which='type -a'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias path='echo -e ${PATH//:/\\n}'
alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'

alias du='du -kh'       # Makes a more readable output.
alias df='df -kTh'

#-------------------------------------------------------------
# The 'ls' family (this assumes you use a recent GNU ls)
#-------------------------------------------------------------
if [[ $platform == 'linux' ]]; then
    alias ls='ls -h -F --color=auto'
else
    alias ls='ls -AhG'
fi
alias l="ls -l"
alias ll="ls -l"
alias la='ls -a'          # show hidden files
alias lla='ls -la'          # show hidden files
alias lk='ls -lSr'         # sort by size, biggest last
alias lc='ls -ltcr'        # sort by and show change time, most recent last
alias lu='ls -ltur'        # sort by and show access time, most recent last
alias lt='ls -ltr'         # sort by date, most recent last
alias lm='ls -l |more'    # pipe through 'more'
alias lr='ls -lR'          # recursive ls
alias tree='tree -Csu'     # nice alternative to 'recursive ls'

#-------------------------------------------------------------
# Git alias
#-------------------------------------------------------------
alias add='git add'
alias br='git branch'
alias ci='git commit --verbose'
alias co='git checkout'
alias gd='git diff'
alias gr='git gr'
alias pull='git pull'
alias st='git status'

#-------------------------------------------------------------
# Admin assistant
#-------------------------------------------------------------
alias ai='sudo apt-get install'
