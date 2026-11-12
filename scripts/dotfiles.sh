#!/bin/sh
# Symlink dotfiles from the repo into $HOME.
set -euf

REPO=${DOTFILES_REPO:-$HOME/dotfiles}

FILES='
.emacs.d/init.el
.emacs.d/site-lisp
.config/zsh
.config/nvim
.config/alacritty
.config/wezterm
.config/xmonad
.vimrc
.profile
.bash_profile
.shrc
.bashrc
.zshenv
.zshrc
.gitconfig
.tmux.conf
.screenrc
.Xresources
'

BAD=0

die()    { printf 'dotfiles: ERROR: %s\n' "$*" >&2; exit 1; }
say()    { printf '%-16s%s\n' "$1" "$2"; }
bad()    { say "$@" >&2; BAD=1; }
exists() { [ -e "$1" ] || [ -L "$1" ]; }   # -e is false for dangling symlinks

usage()
{
    printf '%s\n' "Usage: ${0##*/} install" \
                  "       ${0##*/} remove"
}

# Sets STATE (MISSING | NOT-LINKED | WRONG-LINK | OK) and CUR
classify()
{
    CUR=
    if ! exists "$target"; then
        STATE=MISSING
    elif [ ! -L "$target" ]; then
        STATE=NOT-LINKED
    else
        CUR=$(readlink "$target" || :)
        # Exact text first; then -ef (same file), so relative links and symlinked
        # $HOME/repo paths count as OK and dangling links do not. -ef is POSIX 2024
        # only: a shell lacking it just falls back to the text comparison.
        if [ "$CUR" = "$source" ] || [ "$target" -ef "$source" ] 2>/dev/null; then
            STATE=OK
        else
            STATE=WRONG-LINK
        fi
    fi
}

install_one()
{
    exists "$source" || { bad MISSING-SOURCE "$source"; return; }
    classify
    case $STATE in
        MISSING)
            if (umask 077 && mkdir -p "$(dirname "$target")") && ln -s "$source" "$target"; then
                say LINKED "$target -> $source"
            else
                bad FAILED "$target"
            fi ;;
        OK)         say OK "$target" ;;
        NOT-LINKED) bad CONFLICT "$target" ;;
        WRONG-LINK) bad WRONG-LINK "$target -> $CUR" ;;
    esac
}

remove_one()
{
    classify
    case $STATE in
        MISSING)    say MISSING "$target" ;;
        OK)         if rm "$target"; then say REMOVED "$target"; else bad FAILED "$target"; fi ;;
        NOT-LINKED) bad NOT-LINKED "$target" ;;
        WRONG-LINK) bad WRONG-LINK "$target -> $CUR" ;;
    esac
}

case ${1:-} in
    install|remove) action=$1 ;;
    -h|--help|help)        usage; exit 0 ;;
    *)                     usage >&2; exit 2 ;;
esac
[ $# -eq 1 ] || { usage >&2; exit 2; }

# Linking user-writable files into root's HOME would hand root's login to the repo owner.
[ "$action" != install ] || [ "$(id -u)" -ne 0 ] || die "refusing to install as root"
[ -d "$REPO" ] || die "repository does not exist: $REPO"
REPO=$(CDPATH='' cd -P -- "$REPO" && pwd) || die "cannot resolve repository path: $REPO"
[ -e "$REPO/.git" ] || die "not a Git repository: $REPO"
[ -d "$HOME" ] || die "home directory does not exist: $HOME"

for file in $FILES; do
    source=$REPO/$file target=$HOME/$file
    "${action}_one"
done

if [ "$action" = install ] && git -C "$REPO" submodule status 2>/dev/null | grep -q '^-'; then
    say HINT "git -C $REPO submodule update --init"
fi
if [ "$BAD" -ne 0 ]; then
    printf 'dotfiles: %s finished with problems\n' "$action" >&2
    exit 1
fi
printf 'dotfiles: %s complete\n' "$action"
