#!/bin/sh
set -eu

SCRIPT_NAME="$(basename "$0")"
APT_PIN="/etc/apt/preferences.d/no-snapd"

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run $SCRIPT_NAME as root."
    echo "Run it as a normal user:"
    echo "    ./$SCRIPT_NAME"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is required."
    exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
    echo "ERROR: apt is required."
    exit 1
fi

if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
    echo "ERROR: This script is intended for Ubuntu."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

echo "==> Checking sudo access..."
sudo -v

echo " Snap removal"
echo "Ubuntu detected:"
echo "    ${PRETTY_NAME:-Ubuntu}"
echo
echo "This script will:"
echo
echo "  1. Remove all installed Snap packages"
echo "  2. Purge snapd"
echo "  3. Remove Snap data and cache"
echo "  4. Remove Snap-related systemd state"
echo "  5. Create an APT pin blocking snapd"
echo "  6. Verify that snapd cannot be installed"
echo
echo "Snap will be permanently disabled through APT."
echo

printf "Continue? [y/N] "
read -r answer

case "$answer" in
    y|Y)
        ;;
    *)
        echo "Aborted."
        exit 0
        ;;
esac

echo
echo "==> Stopping Snap services..."

for service in \
    snapd.service \
    snapd.socket \
    snapd.apparmor.service
do
    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        sudo systemctl stop "$service" 2>/dev/null || true
        sudo systemctl disable "$service" 2>/dev/null || true
    fi
done

echo
echo "==> Removing installed Snap packages..."

if command -v snap >/dev/null 2>&1; then
    SNAP_LIST="$(
        snap list 2>/dev/null |
        awk 'NR > 1 {print $1}' || true
    )"

    if [ -n "$SNAP_LIST" ]; then
        echo "$SNAP_LIST" |
        while IFS= read -r snap_name; do
            [ -n "$snap_name" ] || continue

            echo "    Removing: $snap_name"

            if ! sudo snap remove --purge "$snap_name"; then
                echo "    WARNING: failed to remove $snap_name"
            fi
        done
    else
        echo "    No installed Snap packages found."
    fi
else
    echo "    snap command not found."
fi

echo
echo "==> Purging snapd..."

sudo apt purge -y snapd

echo
echo "==> Removing unused dependencies..."

sudo apt autoremove --purge -y

echo
echo "==> Removing Snap directories..."

rm -rf "$HOME/snap"

sudo rm -rf \
    /snap \
    /var/snap \
    /var/lib/snapd \
    /var/cache/snapd \
    /var/log/snapd

echo
echo "==> Reloading systemd..."

sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

echo
echo "==> Blocking future installation of snapd..."

sudo tee "$APT_PIN" >/dev/null <<'EOF'
Package: snapd
Pin: release *
Pin-Priority: -1
EOF

echo
echo "==> Updating APT package lists..."

sudo apt update

echo
echo "============================================================"
echo " Verification"
echo "============================================================"

echo
echo "1. snap command:"

if command -v snap >/dev/null 2>&1; then
    echo "   ERROR: snap command still exists:"
    echo "   $(command -v snap)"
    exit 1
else
    echo "   OK: snap command not found."
fi

echo
echo "2. snapd package:"

if dpkg-query -W -f='${Status}' snapd 2>/dev/null |
    grep -q "install ok installed"; then
    echo "   ERROR: snapd is still installed."
    exit 1
else
    echo "   OK: snapd is not installed."
fi

echo
echo "3. Snap directories:"

for dir in \
    /snap \
    /var/snap \
    /var/lib/snapd \
    /var/cache/snapd \
    /var/log/snapd
do
    if [ -e "$dir" ]; then
        echo "   WARNING: $dir still exists."
    else
        echo "   OK: $dir removed."
    fi
done

echo
echo "4. systemd units:"

if systemctl list-unit-files 2>/dev/null |
    grep -q '^snapd'; then
    echo "   WARNING: Snap systemd units still exist."
else
    echo "   OK: no Snap systemd units found."
fi

echo
echo "5. APT pin:"

if [ -f "$APT_PIN" ]; then
    echo "   OK: $APT_PIN exists."
else
    echo "   ERROR: APT pin was not created."
    exit 1
fi

echo
echo "6. APT policy for snapd:"

apt-cache policy snapd || true

SNAP_CANDIDATE="$(
    apt-cache policy snapd 2>/dev/null |
    awk '/Candidate:/ {print $2}' || true
)"

SNAP_PRIORITY="$(
    apt-cache policy snapd 2>/dev/null |
    awk '
        /^[[:space:]]+-?[0-9]+ / {
            print $1
            exit
        }
    ' || true
)"

if [ "$SNAP_CANDIDATE" = "(none)" ] || [ -z "$SNAP_CANDIDATE" ]; then
    echo
    echo "   OK: snapd has no installation candidate."
fi

case "$SNAP_PRIORITY" in
    -*)
        echo "   OK: snapd is blocked by APT pin."
        ;;
    *)
        if [ -n "$SNAP_CANDIDATE" ] &&
           [ "$SNAP_CANDIDATE" != "(none)" ]; then
            echo "   ERROR: snapd is not blocked by APT."
            echo "   Priority: ${SNAP_PRIORITY:-unknown}"
            exit 1
        fi
        ;;
esac

echo
echo "7. Installed Snap packages:"

if command -v snap >/dev/null 2>&1; then
    echo "   ERROR: snap command still exists."
    exit 1
else
    echo "   OK: no Snap packages can be listed."
fi

echo " Snap removal completed successfully."
echo "snap command: not installed"
echo "snapd:        not installed"
echo "APT pin:      $APT_PIN"
echo "APT priority: ${SNAP_PRIORITY:-unknown}"
echo "Verify manually with:"
echo "    apt-cache policy snapd"


# chmod +x ./remove-snap.sh
# ./remove-snap.sh
