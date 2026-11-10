# minimal POSIX login fallback
case $(umask) in
    0022|022) umask 027 ;;
esac

# Drop empty and "." PATH entries
_o=$IFS
IFS=:
set -f
_p=
for d in ${PATH:-/usr/bin:/bin}; do
    case $d in
        ''|.) ;;
        *) _p=${_p:+$_p:}$d ;;
    esac
done
set +f
IFS=$_o
PATH=${_p:-/usr/bin:/bin}

for d in "$HOME/bin" "$HOME/.local/bin"; do
    [ -d "$d" ] || continue
    case ":$PATH:" in
        *":$d:"*) ;;
        *) PATH=$PATH:$d ;;
    esac
done
export PATH

LESS=${LESS:-FRX}
export LESS

# Production host
_h=$(uname -n)
[ -f /etc/prod-host ] && _h=prod
case $_h in
    prod|prod[-._0-9]*|*[-._]prod|*[-._]prod[-._0-9]*)
        # no pager/client history files: they keep typed searches and SQL in plaintext
        LESSSECURE=1 LESSHISTFILE=- MYSQL_HISTFILE=/dev/null PSQL_HISTORY=/dev/null
        export LESSSECURE LESSHISTFILE MYSQL_HISTFILE PSQL_HISTORY
        # no core dumps: they contain secrets from memory
        # shellcheck disable=SC3045
        ulimit -c 0 2>/dev/null
        ;;
esac

# Interactive shell configuration
if [ -r "$HOME/.shrc" ] &&
   { [ -z "${ENV-}" ] || [ ! -r "$ENV" ]; }; then
    ENV=$HOME/.shrc
    export ENV
fi

unset d _h _o _p
