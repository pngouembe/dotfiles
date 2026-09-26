#!/bin/bash
# Make SDDM the login screen, running sddm-astronaut-theme in caelestia colours.
#
# Replaces greetd + ReGreet (docs/login-greeter.md). greetd, ReGreet and their
# /etc/greetd config are left installed, so going back is two systemctl calls;
# see the bottom of docs/login-sddm.md.
#
# Install the packages first (sddm from the repos, the theme from the AUR):
#
#     paru -S --needed sddm sddm-astronaut-theme
#
# Idempotent: safe to re-run. Requires root.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "error: run as root (sudo $0)" >&2
    exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

for pkg in sddm sddm-astronaut-theme; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "error: $pkg is not installed (paru -S --needed sddm sddm-astronaut-theme)" >&2
        exit 1
    fi
done


say "1/3  sddm config"
install -D -m 644 "$REPO/sddm/sddm.conf.d/10-caelestia.conf" /etc/sddm.conf.d/10-caelestia.conf
echo "    /etc/sddm.conf.d/10-caelestia.conf"


say "2/3  palette and wallpaper"
"$REPO/scripts/sddm-theme.sh"


say "3/3  display manager"
# display-manager.service is a symlink to whichever login unit is enabled;
# disabling the current one and enabling sddm repoints it.
current="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
if [[ $current == *sddm.service ]]; then
    echo "    already sddm"
else
    if [[ -n $current ]]; then
        systemctl disable "$(basename "$current")"
    fi
    systemctl enable sddm.service
    echo "    switched ${current:+$(basename "$current") }-> sddm.service"
fi

cat <<'EOF2'

Done. SDDM takes over at the next boot.

To try it now WITHOUT rebooting, from a TTY (Ctrl+Alt+F2, log in there first so
you have a way back in):

    sudo systemctl stop greetd && sudo systemctl start sddm

That kills the running graphical session, so save your work first.
EOF2
