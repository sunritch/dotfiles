# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

case $(umask) in
    0022|022) umask 027 ;;
esac

_prod=0
case $(uname -n) in
    prod|prod[-._0-9]*|*[-._]prod|*[-._]prod[-._0-9]*) _prod=1 ;;
esac
[ -f /etc/prod-host ] && _prod=1

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
HISTIGNORE='*[Pp][Aa][Ss][Ss][Ww]*:*[Tt][Oo][Kk][Ee][Nn]*:*[Ss][Ee][Cc][Rr][Ee][Tt]*:*[Aa][Pp][Ii]_[Kk][Ee][Yy]*'

# append to the history file, don't overwrite it
shopt -s histappend histverify

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# '>' will not overwrite an existing file; use '>|'
set -o noclobber

if [ "$_prod" = 1 ]; then
    # idle auto-logout at the prompt; ignore the error if a system file already made it read-only
    { TMOUT=900; readonly TMOUT; } 2>/dev/null
    # audit trail: timestamps, keep space-prefixed commands, and write every command at once instead of at exit
    HISTTIMEFORMAT='%F %T ' HISTCONTROL=ignoredups
    PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
# (what lesspipe prints, without running it: that costs three processes)
[ "$_prod" = 0 ] && [ -x /usr/bin/lesspipe ] && export LESSOPEN='| /usr/bin/lesspipe %s' LESSCLOSE='/usr/bin/lesspipe %s %s'

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# cwd with control characters stripped: \w prints a raw directory name, which can carry terminal escapes
# shellcheck disable=SC2016 # expanded at prompt time, on purpose
_pwd() { _w=$PWD; [[ -n ${HOME%/} && $PWD/ == "${HOME%/}"/* ]] && _w=\~${PWD#"${HOME%/}"}; _w=${_w//[[:cntrl:]]/}; }
PROMPT_COMMAND="_pwd${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]${_w}\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:${_w}\$ '
fi
[ "$_prod" = 1 ] && PS1='\[\033[1;7m\]PROD\[\033[0m\] '$PS1

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: ${_w}\a\]'$PS1
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then eval "$(dircolors -b ~/.dircolors)"; else eval "$(dircolors -b)"; fi
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ge='emacs'
alias nv='nvim'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
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
fi
shopt -s cdspell
shopt -s dirspell 2>/dev/null

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
# opam (only if installed)
if [ -r "$HOME/.opam/opam-init/init.sh" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
fi

# WSLg GPU acceleration (WSL only; these break GPU drivers on native Linux)
{ read -r _r < /proc/sys/kernel/osrelease; } 2>/dev/null
if [ -n "${WSL_DISTRO_NAME-}" ] || [[ $_r == *[Mm]icrosoft* ]]; then
    export GALLIUM_DRIVER=d3d12
    export LIBVA_DRIVER_NAME=d3d12
fi

# plan9port: appended, so its commands never shadow the system ones
_p9=${PLAN9:-/usr/local/plan9}
if [ -d "$_p9/bin" ]; then
    PLAN9=$_p9
    export PLAN9
    case ":$PATH:" in
        *":$PLAN9/bin:"*) ;;
        *) PATH="$PATH:$PLAN9/bin"; export PATH ;;
    esac
fi
unset _p9 _prod _r
