# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

HISTSIZE=1000 HISTFILESIZE=2000
shopt -s histappend histverify checkwinsize cdspell
shopt -s globstar dirspell 2>/dev/null
#set -o noclobber   # '>' will not overwrite an existing file; use '>|'

HISTCONTROL=ignoreboth HISTTIMEFORMAT='%F %T '
# make less more friendly for non-text input files (exports what lesspipe prints, without running it)
if [ -x /usr/bin/lesspipe ]; then
    export LESSOPEN='| /usr/bin/lesspipe %s' LESSCLOSE='/usr/bin/lesspipe %s %s'
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# colour only if the terminal supports it (dumb, vt100 and friends get a plain prompt)
if command -v tput >/dev/null 2>&1 && tput setaf 1 >&/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
# if this is an xterm set the title to user@host:dir
case $TERM in
    xterm*|rxvt*) PS1='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]'$PS1 ;;
esac

# enable color support of ls and grep, and set LS_COLORS (also read by other tools)
case $OSTYPE in
    linux*|*gnu*|cygwin*|msys*)
        if command -v dircolors >/dev/null 2>&1; then
            if [ -r ~/.dircolors ]; then eval "$(dircolors -b ~/.dircolors)"; else eval "$(dircolors -b)"; fi
        fi
        alias ls='ls --color=auto' grep='grep --color=auto'
        #alias fgrep='grep -F --color=auto' egrep='grep -E --color=auto'
        ;;
    *)
        alias ls='ls -G'
        ;;
esac

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

alias ll='ls -alF' la='ls -A' l='ls -CF'
alias ge=emacs
alias gen='emacs -nw'
alias nv=nvim
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

# programmable completion (skipped if /etc/bash.bashrc already loaded it: sourcing it twice costs ~6 ms)
if [ -z "${BASH_COMPLETION_VERSINFO-}" ] && ! shopt -oq posix; then
    for _f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        if [ -f "$_f" ]; then . "$_f"; break; fi
    done
fi

# opam
if [ -r "$HOME/.opam/opam-init/init.sh" ]; then
    . "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
fi

# WSLg GPU acceleration (WSL only; these break GPU drivers on native Linux)
if [[ -n ${WSL_DISTRO_NAME-} || $(</proc/sys/kernel/osrelease) == *[Mm]icrosoft* ]] 2>/dev/null; then
    export GALLIUM_DRIVER=d3d12 LIBVA_DRIVER_NAME=d3d12
fi

# plan9port
_p9=${PLAN9:-/usr/local/plan9}
if [ -d "$_p9/bin" ]; then
    export PLAN9=$_p9
    case :$PATH: in
        *:"$PLAN9/bin":*) ;;
        *) PATH=$PATH:$PLAN9/bin ;;
    esac
fi
unset _f _p9
