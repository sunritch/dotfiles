KEYTIMEOUT=20

# environment (from ~/.zshenv): hardening applies to prod only; prompt colour tells them apart
case $DOTFILES_ENV in
  prod) _prod=1 _pc=red ;;
  staging) _prod=0 _pc=yellow ;;
  *) _prod=0 _pc=green ;;
esac

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL
#setopt NO_CLOBBER   # '>' will not overwrite an existing file; use '>|'

# -------- History
HISTFILE=$HOME/.local/state/zsh_history
if [[ ! -d ${HISTFILE:h} ]]; then command mkdir -p -m 700 "${HISTFILE:h}"; fi

# Never record lines that look like they carry secrets (assignments and --password flags).
HISTORY_IGNORE='(*[Pp][Aa][Ss][Ss][Ww]*=*|*[Tt][Oo][Kk][Ee][Nn]*=*|*[Ss][Ee][Cc][Rr][Ee][Tt]*=*|*[Aa][Pp][Ii]_[Kk][Ee][Yy]*=*|*--[Pp][Aa][Ss][Ss]*)'
HISTSIZE=50000 SAVEHIST=10000
setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS HIST_VERIFY
if (( _prod )); then
  setopt INC_APPEND_HISTORY   # audit trail: every command written at once, space-prefixed ones kept
  if [[ ${(t)TMOUT} != *readonly* ]]; then TMOUT=900; fi   # idle auto-logout at the prompt; skipped if already read-only
else
  setopt SHARE_HISTORY HIST_IGNORE_SPACE
fi

# -------- Completion
ZPLUG=$HOME/.config/zsh/plugins

if (( ! _prod )) && [[ -d $ZPLUG/zsh-completions/src ]]; then
  fpath=("$ZPLUG/zsh-completions/src" $fpath)
fi

_zc=$HOME/.cache/zsh _zd=$HOME/.cache/zsh/zcompdump
if (( _prod )); then _zd=$_zd-prod; fi   # prod has no plugin completions in fpath: keep its dump apart when HOME is shared
if [[ ! -d $_zc ]]; then command mkdir -p -m 700 "$_zc"; fi
autoload -Uz compinit
_old=($_zd(N.mh+24))

# full run (with the insecure-directory audit) always on prod, otherwise once a day
if [[ ! -e $_zd ]] || (( $#_old || _prod )); then
  compinit -d "$_zd" && touch "$_zd"   # compinit leaves an unchanged dump alone
  if (( ! _prod )); then
    zcompile "$_zd"   # a compiled dump loads faster; pointless when prod re-runs compinit every shell
  fi
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
alias ll='ls -lAh'
alias la='ls -lh'
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'
alias ge=emacs
alias nv=nvim

# -------- Prompt
_ps_prompt() {
  psvar[2]=${(V)${(%):-%~}}
  if [[ $TERM == (xterm|rxvt|wezterm|foot|alacritty|screen)* ]]; then
    print -rn -- $'\e]0;'$psvar[2]$'\a'
  fi
}
precmd_functions=(${precmd_functions:#_ps_prompt} _ps_prompt)
_ph=
if [[ $DOTFILES_ENV == (prod|staging) ]] || (( EUID == 0 )) || [[ -n ${SSH_CONNECTION-} ]]; then
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
