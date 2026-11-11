# minimal POSIX login configuration
umask g-w,o-rwx

# an empty PATH would make the uname lookup below fail, silently turning production protections off
PATH=${PATH:-/usr/bin:/bin}
for d in "$HOME/bin" "$HOME/.local/bin"; do
    if [ -d "$d" ]; then
        case :$PATH: in
            *:"$d":*) ;;
            *) PATH=$PATH:$d ;;
        esac
    fi
done
export PATH LESS="${LESS:-FRX}"

# environment: prod, staging or dev
_h=$(uname -n)
if [ -f /etc/prod-host ]; then
    _h=prod
elif [ -f /etc/staging-host ]; then
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
if [ "$DOTFILES_ENV" = prod ]; then
    # no pager/client history files
    export LESSSECURE=1 LESSHISTFILE=- MYSQL_HISTFILE=/dev/null PSQL_HISTORY=/dev/null
    # no core dumps: soft limit only, so it can be raised for debugging
    # shellcheck disable=SC3045
    ulimit -Sc 0 2>/dev/null
fi

# interactive shell configuration for POSIX sh
if [ -r "$HOME/.shrc" ] && { [ -z "${ENV-}" ] || [ ! -r "$ENV" ]; }; then
    export ENV="$HOME/.shrc"
fi

unset d _h
