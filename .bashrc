# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return ;;
esac

# environment normally comes from ~/.profile; detect it now if this shell never saw it
if [ -z "${DOTFILES_ENV+x}" ] && [ -r "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# never record lines that look like they carry secrets (assignments and --password flags)
HISTIGNORE='*[Pp][Aa][Ss][Ss][Ww]*=*:*[Tt][Oo][Kk][Ee][Nn]*=*:*[Ss][Ee][Cc][Rr][Ee][Tt]*=*:*[Aa][Pp][Ii]_[Kk][Ee][Yy]*=*:*--[Pp][Aa][Ss][Ss]*'
HISTSIZE=1000 HISTFILESIZE=2000
shopt -s histappend histverify checkwinsize cdspell
shopt -s globstar dirspell 2>/dev/null
#set -o noclobber   # '>' will not overwrite an existing file; use '>|'

if [ "$DOTFILES_ENV" = prod ]; then
    { TMOUT=900; } 2>/dev/null   # idle auto-logout at the prompt; ignore the error if a system file made it read-only
    # audit trail: timestamps, keep space-prefixed commands, write every command at once instead of at exit
    HISTTIMEFORMAT='%F %T ' HISTCONTROL=ignoredups
    case ${PROMPT_COMMAND-} in
        *'history -a'*) ;;   # already there: this file is being sourced again
        *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
    esac
else
    HISTCONTROL=ignoreboth
    # make less more friendly for non-text input files (exports what lesspipe prints, without running it)
    if [ -x /usr/bin/lesspipe ]; then
        export LESSOPEN='| /usr/bin/lesspipe %s' LESSCLOSE='/usr/bin/lesspipe %s %s'
    fi
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# environment label: red PROD, yellow STG, nothing for dev
case $DOTFILES_ENV in
    prod) _env=PROD _ec=31 ;;
    staging) _env=STG _ec=33 ;;
    *) _env='' _ec='' ;;
esac

# colour only if the terminal supports it (dumb, vt100 and friends get a plain prompt)
if command -v tput >/dev/null 2>&1 && tput setaf 1 >&/dev/null; then
    PS1='${debian_chroot:+($debian_chroot)}\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    _tag='\[\e[1;7;'$_ec'm\]'$_env'\[\e[0m\] '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    _tag=$_env' '
fi
if [ -n "$_env" ]; then PS1=$_tag$PS1; fi
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
alias ge=emacs nv=nvim
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

# programmable completion (skipped if /etc/bash.bashrc already loaded it: sourcing it twice costs ~6 ms)
if [ -z "${BASH_COMPLETION_VERSINFO-}" ] && ! shopt -oq posix; then
    for _f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        if [ -f "$_f" ]; then . "$_f"; break; fi
    done
fi

# BEGIN opam configuration
if [ -r "$HOME/.opam/opam-init/init.sh" ]; then
    . "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
fi
# END opam configuration

# WSLg GPU acceleration (WSL only; these break GPU drivers on native Linux)
if [[ -n ${WSL_DISTRO_NAME-} || $(</proc/sys/kernel/osrelease) == *[Mm]icrosoft* ]] 2>/dev/null; then
    export GALLIUM_DRIVER=d3d12 LIBVA_DRIVER_NAME=d3d12
fi

# plan9port: appended, so its commands never shadow the system ones
_p9=${PLAN9:-/usr/local/plan9}
if [ -d "$_p9/bin" ]; then
    export PLAN9=$_p9
    case :$PATH: in
        *:"$PLAN9/bin":*) ;;
        *) PATH=$PATH:$PLAN9/bin ;;
    esac
fi
unset _f _p9 _env _ec _tag
