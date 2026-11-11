umask g-w,o-rwx

typeset -U path fpath   # no duplicates, even if ~/.zshrc is sourced again
path+=($HOME/bin(N-/) $HOME/.local/bin(N-/))   # only existing dirs, appended so they never shadow system commands

export LESS=${LESS:-FRX}

# environment: prod, staging or dev; same rules as ~/.profile
_h=${HOST:l}
if [[ -f /etc/prod-host ]]; then
  _h=prod
elif [[ -f /etc/staging-host ]]; then
  _h=staging
fi
case $_h in
  prod|prod[-._0-9]*|*[-._]prod|*[-._]prod[-._0-9]*) DOTFILES_ENV=prod ;;
  stg|stg[-._0-9]*|*[-._]stg|*[-._]stg[-._0-9]*) DOTFILES_ENV=staging ;;
  staging|staging[-._0-9]*|*[-._]staging|*[-._]staging[-._0-9]*) DOTFILES_ENV=staging ;;
  *) DOTFILES_ENV=dev ;;
esac
export DOTFILES_ENV
# hardening applies to prod only; staging just gets its label
if [[ $DOTFILES_ENV == prod ]]; then
  export LESSSECURE=1 LESSHISTFILE=- MYSQL_HISTFILE=/dev/null PSQL_HISTORY=/dev/null
  ulimit -Sc 0   # no core dumps: soft limit only, so it can be raised for debugging
fi
unset _h
