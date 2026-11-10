case $(umask) in 022) umask 027 ;; esac

_prod=0
[[ -e /etc/prod-host || ${HOST:l} =~ '(^|[-._])prod([-._0-9]|$)' ]] && _prod=1

typeset -U path
path=(${path:#(|.)} $HOME/bin(N-/) $HOME/.local/bin(N-/))   # no empty or "." entries; only existing dirs

export LESS=${LESS:-FRX}

if (( _prod )); then
  export LESSSECURE=1 LESSHISTFILE=- MYSQL_HISTFILE=/dev/null PSQL_HISTORY=/dev/null
  ulimit -c 0
fi
