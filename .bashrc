# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

HISTSIZE=5000 HISTFILESIZE=5000
shopt -s histappend histverify checkwinsize cdspell checkjobs
shopt -s globstar dirspell 2>/dev/null
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'
HISTCONTROL=ignoreboth HISTTIMEFORMAT='%F %T '
# make less more friendly for non-text input files (exports what lesspipe prints, without running it)
if [ -x /usr/bin/lesspipe ]; then
    export LESSOPEN='| /usr/bin/lesspipe %s' LESSCLOSE='/usr/bin/lesspipe %s %s'
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# colour only if the terminal supports it
if command -v tput >/dev/null 2>&1 && tput setaf 1 >&/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\H\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\H:\w\$ '
fi
# if this is an xterm set the title to user@host:dir
case $TERM in
    xterm*|rxvt*|tmux*) PS1='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]'$PS1 ;;
esac

# enable color support of ls and grep, and set LS_COLORS (also read by other tools)
case $OSTYPE in
    linux*|*gnu*|cygwin*|msys*)
        if [ -r ~/.dircolors ] && command -v dircolors >/dev/null 2>&1; then
            eval "$(dircolors -b ~/.dircolors)"
        fi
        alias ls='ls --color=auto' grep='grep --color=auto'
        #alias fgrep='grep -F --color=auto' egrep='grep -E --color=auto'
        ;;
    *)
        alias ls='ls -G'
        ;;
esac

alias ll='ls -alF' la='ls -A' l='ls -CF'
alias ge=emacs
alias gen='emacs -nw'
alias nv=nvim
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

# programmable completion (skipped if /etc/bash.bashrc already loaded it)
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
