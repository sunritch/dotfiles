# minimal POSIX login configuration
umask g-w,o-rwx

# fall back to a sane PATH if the environment has none
PATH=${PATH:-/usr/bin:/bin}
for d in "$HOME/bin" "$HOME/.local/bin"; do
    if [ -d "$d" ]; then
        case :$PATH: in
            *:"$d":*) ;;
            *) PATH=$PATH:$d ;;
        esac
    fi
done

export PATH EDITOR="${EDITOR:-vi}" LESS="${LESS:-iMFRX}"

# interactive shell configuration for POSIX sh
if [ -r "$HOME/.shrc" ] && { [ -z "${ENV-}" ] || [ ! -r "$ENV" ]; }; then
    export ENV="$HOME/.shrc"
fi

unset d

# bash login
if [ -n "${BASH_VERSION-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc";
fi
