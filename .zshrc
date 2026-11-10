KEYTIMEOUT=20

setopt AUTO_CD
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP NO_FLOW_CONTROL
# Safety rail
setopt NO_CLOBBER       # '>' will not overwrite an existing file; use '>|'

# -------- History
HISTFILE=$HOME/.local/state/zsh_history
[[ -d ${HISTFILE:h} ]] || command mkdir -p -m 700 "${HISTFILE:h}"

# Never record lines that look like they carry secrets.
HISTORY_IGNORE='(*[Pp][Aa][Ss][Ss][Ww]*|*[Tt][Oo][Kk][Ee][Nn]*|*[Ss][Ee][Cc][Rr][Ee][Tt]*|*[Aa][Pp][Ii]_[Kk][Ee][Yy]*)'
HISTSIZE=50000
SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt SHARE_HISTORY

# -------- Production hosts
if (( _prod )); then
    [[ ${(t)TMOUT} == *readonly* ]] || typeset -r TMOUT=900   # idle auto-logout at the prompt; skipped if already read-only
    unsetopt SHARE_HISTORY HIST_IGNORE_SPACE   # the audit trail keeps space-prefixed commands
    setopt INC_APPEND_HISTORY
fi

# -------- Completion
ZPLUG=$HOME/.config/zsh/plugins

if (( ! _prod )) && [[ -d $ZPLUG/zsh-completions/src ]]; then
  fpath=("$ZPLUG/zsh-completions/src" $fpath)
fi

_zc=$HOME/.cache/zsh
[[ -d $_zc ]] || command mkdir -p -m 700 "$_zc"
autoload -Uz compinit
setopt EXTENDED_GLOB
_zd=$_zc/zcompdump

# full run (with the insecure-directory audit) always on prod, otherwise once a day
if (( _prod )) || [[ ! -e $_zd || -n $_zd(#qN.mh+24) ]]; then
  compinit -d "$_zd" && touch "$_zd"   # compinit leaves an unchanged dump alone
  (( _prod )) || zcompile "$_zd"   # a compiled dump loads faster
else
  compinit -C -d "$_zd"
fi

unset _zc _zd
unsetopt EXTENDED_GLOB

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

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
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
bindkey '^[[Z' reverse-menu-complete
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
alias ll='ls -lh'
alias la='ls -lAh'
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'
alias ge=emacs
alias nv=nvim

# -------- Prompt
_ps_prompt() {
  psvar[2]=${(V)${(%):-%~}}
  [[ $TERM == (xterm|rxvt|wezterm|foot|alacritty|screen)* ]] &&
    print -rn -- $'\e]0;'$psvar[2]$'\a'
}
precmd_functions=(${precmd_functions:#_ps_prompt} _ps_prompt)
(( _prod )) && _pc=red || _pc=green
_ph=
if (( _prod || EUID == 0 )) || [[ -n ${SSH_CONNECTION-} ]]; then
  _ph="%F{$_pc}%n@%m%f "
fi
PROMPT="%(?..%F{red}%?%f )${_ph}%F{blue}%2v%f%B%F{$_pc}%#%f%b "

# -------- Plugins
if (( ! _prod )); then
  if [[ -r $ZPLUG/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source "$ZPLUG/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  # Syntax highlighting must be loaded last.
  if [[ -r $ZPLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
    source "$ZPLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  fi
fi

unset _prod _pc _ph ZPLUG
