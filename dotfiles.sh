#!/bin/sh

set -eu

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"

FILES='
.emacs.d/init.el
.emacs.d/site-lisp
.config/nvim
.config/helix
.vimrc
.bashrc
.tmux.conf
.screenrc
.Xresources
'

CONFLICTS=0
NOT_OK=0


# ---- Utilities

die()
{
    printf '%s\n' "dotfiles: $*" >&2
    exit 1
}


exists()
{
    # `test -e` is false for dangling symlinks.
    [ -e "$1" ] || [ -L "$1" ]
}


ensure_repo()
{
    if [ ! -d "$REPO" ]; then
        die "repository does not exist: $REPO"
    fi

    REPO=$(CDPATH= cd -- "$REPO" && pwd)

    if [ ! -e "$REPO/.git" ]; then
        die "not a git repository: $REPO"
    fi
}


# ------ Install

install_one()
{
    file=$1

    source="$REPO/$file"
    target="$HOME/$file"

    if ! exists "$source"; then
        printf '%s\n' "MISSING-SOURCE  $source" >&2
        CONFLICTS=1
        return
    fi

    mkdir -p "$(dirname "$target")"

    if ! exists "$target"; then
        ln -s "$source" "$target"
        printf '%s\n' "LINKED          $target -> $source"
        return
    fi

    if [ ! -L "$target" ]; then
        printf '%s\n' "CONFLICT        $target" >&2
        CONFLICTS=1
        return
    fi

    current=$(readlink "$target")

    if [ "$current" = "$source" ]; then
        printf '%s\n' "OK              $target"
        return
    fi

    printf '%s\n' "WRONG-LINK      $target -> $current" >&2
    CONFLICTS=1
}


install()
{
    ensure_repo

    for file in $FILES; do
        install_one "$file"
    done

    if [ "$CONFLICTS" -ne 0 ]; then
        printf '%s\n' \
            "dotfiles: install completed with conflicts" >&2
        return 1
    fi

    printf '%s\n' "dotfiles: install complete"
}


# -------------- Remove

remove_one()
{
    file=$1

    source="$REPO/$file"
    target="$HOME/$file"

    if ! exists "$target"; then
        printf '%s\n' "MISSING         $target"
        return
    fi

    if [ ! -L "$target" ]; then
        printf '%s\n' "NOT-LINKED      $target"
        NOT_OK=1
        return
    fi

    current=$(readlink "$target")

    if [ "$current" != "$source" ]; then
        printf '%s\n' \
            "WRONG-LINK      $target -> $current" >&2
        NOT_OK=1
        return
    fi

    rm "$target"

    printf '%s\n' "REMOVED         $target"
}


remove()
{
    ensure_repo

    for file in $FILES; do
        remove_one "$file"
    done

    if [ "$NOT_OK" -ne 0 ]; then
        printf '%s\n' \
            "dotfiles: remove completed with warnings" >&2
        return 1
    fi

    printf '%s\n' "dotfiles: remove complete"
}


# ---------------Status

status_one()
{
    file=$1

    source="$REPO/$file"
    target="$HOME/$file"

    if ! exists "$source"; then
        printf '%s\n' "MISSING-SOURCE  $source"
        NOT_OK=1
        return
    fi

    if ! exists "$target"; then
        printf '%s\n' "MISSING         $target"
        NOT_OK=1
        return
    fi

    if [ ! -L "$target" ]; then
        printf '%s\n' "NOT-LINKED      $target"
        NOT_OK=1
        return
    fi

    current=$(readlink "$target")

    if [ "$current" = "$source" ]; then
        printf '%s\n' "OK              $target"
        return
    fi

    printf '%s\n' "WRONG-LINK      $target -> $current"
    NOT_OK=1
}


status()
{
    ensure_repo

    printf '%s\n' "Repository: $REPO"
    printf '%s\n' ""

    for file in $FILES; do
        status_one "$file"
    done

    if [ "$NOT_OK" -ne 0 ]; then
        return 1
    fi

    return 0
}


# ----------------Main

case "${1:-}" in
    install)
        install
        ;;

    remove)
        remove
        ;;

    status)
        status
        ;;

    *)
        printf '%s\n' \
            "usage: dotfiles.sh install" \
            "       dotfiles.sh remove" \
            "       dotfiles.sh status"
        exit 1
        ;;
esac