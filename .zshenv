umask g-w,o-rwx

typeset -U path fpath   # no duplicates, even if ~/.zshrc is sourced again
path+=($HOME/bin(N-/) $HOME/.local/bin(N-/))

export EDITOR=${EDITOR:-vi} LESS=${LESS:-iMFRX}
