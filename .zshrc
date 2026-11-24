setopt INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL

# -------- History
HISTFILE=$HOME/.local/state/zsh_history
if [[ ! -d ${HISTFILE:h} ]]; then command mkdir -p -m 700 "${HISTFILE:h}"; fi

HISTSIZE=5000 SAVEHIST=5000
setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS HIST_VERIFY
setopt SHARE_HISTORY HIST_IGNORE_SPACE

# -------- Completion
ZPLUG=$HOME/.config/zsh/plugins

if [[ -d $ZPLUG/zsh-completions/src ]]; then
    fpath=("$ZPLUG/zsh-completions/src" $fpath)
fi

_zc=$HOME/.cache/zsh _zd=$HOME/.cache/zsh/zcompdump
if [[ ! -d $_zc ]]; then command mkdir -p -m 700 "$_zc"; fi
autoload -Uz compinit
_old=($_zd(N.mh+24))

# full run (with the insecure-directory audit) once a day
if [[ ! -e $_zd ]] || (( $#_old )); then
    compinit -d "$_zd" && touch "$_zd"   # compinit leaves an unchanged dump alone
    zcompile "$_zd"   # a compiled dump loads faster
else
    compinit -C -d "$_zd"
fi

unset _zc _zd _old

zmodload zsh/complist

setopt COMPLETE_IN_WORD ALWAYS_TO_END

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
       'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
       'r:|=*' \
       'l:|=* r:|=*'

# -------- Key bindings
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
autoload -Uz edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^X^E' edit-command-line
bindkey ' ' magic-space

# -------- Aliases
case $OSTYPE in
    linux*|*gnu*|cygwin*|msys*)
        alias ls='ls --color=auto'
        alias grep='grep --color=auto'
        ;;
    *)
        alias ls='ls -G'
        ;;
esac
alias ll='ls -lAh'
alias la='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'
alias ge=emacs
alias gen='emacs -nw'
alias nv=nvim

# -------- Prompt
_ps_prompt() {
    psvar[2]=${(V)${(%):-%~}}
    if [[ $TERM == (xterm|rxvt|wezterm|kitty|foot|alacritty|screen)* ]]; then
        print -rn -- $'\e]0;'$psvar[2]$'\a'
    fi
}
precmd_functions=(${precmd_functions:#_ps_prompt} _ps_prompt)

PROMPT="%(?..%F{red}%?%f )%(1j.[%j] .)%F{green}%n@%M%f:%F{blue}%~%f%# "
REPORTTIME=10 TIMEFMT='%J %E elapsed %U user'
# -------- Opam
if [[ -r $HOME/.opam/opam-init/init.zsh ]]; then
    source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1;
fi

# -------- Plugins
if [[ -r $ZPLUG/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source "$ZPLUG/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
# Syntax highlighting must be loaded last.
if [[ -r $ZPLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source "$ZPLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

unset _ph ZPLUG
