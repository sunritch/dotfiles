# ~/.tcshrc or .cshrc

# -------- Environment
#umask 022
set add = ()
foreach d ($HOME/bin $HOME/.local/bin)
    if (-d $d) set add = ($add $d)
end
if ($#add) set -f path = ($path $add)
unset add d

if (! $?EDITOR) setenv EDITOR vi
if (! $?LESS)   setenv LESS iMFRX

# -------- HPC: Environment Modules / Lmod
if ("`alias module`" == "") then
    foreach f ( \
        /etc/profile.d/modules.csh \
        /etc/profile.d/z00_lmod.csh \
        /usr/share/Modules/init/tcsh \
        /usr/share/lmod/lmod/init/tcsh \
        /usr/local/Modules/init/tcsh \
        /usr/local/lmod/lmod/init/tcsh \
    )
        if (-r $f) then
            source $f
            break
        endif
    end
    unset f
endif
# -------- Interactive configuration
if ($?prompt) then

    # Shell options
    set nobeep printexitvalue rmstar autorehash notify
    set autolist = ambiguous complete = enhance listjobs = long correct = cmd
    set symlink = ignore listmax = 100 time = (10 '%E elapsed %U user')

    # History
    set history = 5000 savehist = (5000 merge) histdup = erase

    # Key bindings
    bindkey '^[[A' history-search-backward
    bindkey '^[OA' history-search-backward
    bindkey '^[[B' history-search-forward
    bindkey '^[OB' history-search-forward
    bindkey '^[[7~' beginning-of-line
    bindkey '^[[1~' beginning-of-line
    bindkey '^[[4~' end-of-line
    bindkey '^[[8~' end-of-line
    bindkey '^[[3~' delete-char
    bindkey '^[[1;5C' forward-word
    bindkey '^[[1;5D' backward-word
    bindkey '^[[Z' complete-word-back
    bindkey ' ' magic-space

    # Aliases
    switch ("$OSTYPE")
        case linux:
            alias ls 'ls --color=auto'
            alias grep 'grep --color=auto'
            breaksw
        case FreeBSD:
        case darwin:
            alias ls 'ls -G'
            breaksw
    endsw
    alias ll 'ls -alF'
    alias la 'ls -A'
    alias l 'ls -CF'
    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias ge emacs
    alias gen 'emacs -nw'

    # Prompt
    set prompt = "%n@%M:%~[%h]%# "
    
    # opam
    # if (-r $HOME/.opam/opam-init/init.csh) then
    #     source $HOME/.opam/opam-init/init.csh >& /dev/null
    #endif

endif
