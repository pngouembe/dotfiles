#!/bin/bash
# Replace cosmic-greeter with ReGreet, themed from the caelestia palette.
#
# CachyOS ships COSMIC's greeter as the display manager; it is a greetd front
# end, so only the greeter binary and its config change here -- greetd itself
# stays. cosmic-greeter is left installed and can be restored, see the bottom of
# docs/login-greeter.md.
#
# Idempotent: safe to re-run. Requires root.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "error: run as root (sudo $0)" >&2
    exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

say() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

for pkg in greetd-regreet cage; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "error: $pkg is not installed (pacman -S greetd-regreet cage)" >&2
        exit 1
    fi
done


say "1/4  greetd config"
# Backed up rather than overwritten: the stock file documents the agreety
# fallback, which is what you want on hand if the graphical greeter breaks.
if [[ -f /etc/greetd/config.toml ]] && ! cmp -s "$REPO/greetd/config.toml" /etc/greetd/config.toml; then
    cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.bak.$STAMP"
    echo "    backup at /etc/greetd/config.toml.bak.$STAMP"
fi
install -m 644 "$REPO/greetd/config.toml" /etc/greetd/config.toml


say "2/4  regreet config"
if [[ -f /etc/greetd/regreet.toml ]] && ! cmp -s "$REPO/greetd/regreet.toml" /etc/greetd/regreet.toml; then
    cp -a /etc/greetd/regreet.toml "/etc/greetd/regreet.toml.bak.$STAMP"
    echo "    backup at /etc/greetd/regreet.toml.bak.$STAMP"
fi
install -m 644 "$REPO/greetd/regreet.toml" /etc/greetd/regreet.toml


say "3/4  palette and wallpaper"
"$REPO/scripts/greeter-theme.sh"


say "4/4  display manager"
# display-manager.service is a symlink to whichever greeter unit is enabled;
# disabling cosmic-greeter and enabling greetd repoints it.
if [[ "$(readlink -f /etc/systemd/system/display-manager.service)" == *greetd.service ]]; then
    echo "    already greetd"
else
    systemctl disable cosmic-greeter.service
    systemctl enable greetd.service
    echo "    switched cosmic-greeter -> greetd"
fi

cat <<'EOF'

Done. The new greeter takes effect at the next boot.

To try it now WITHOUT rebooting, from a TTY (Ctrl+Alt+F2, log in there first so
you have a way back in):

    sudo systemctl restart greetd

That kills the running graphical session, so save your work first.
EOF
