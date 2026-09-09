#!/usr/bin/env bash
#
# Install the `catppuccin-true` scheme into caelestia-cli.
#
# caelestia-cli reads schemes from `<site-packages>/caelestia/data/schemes`
# (see caelestia/utils/paths.py: `scheme_data_dir`). There is no user-level
# override, so a custom scheme has to live inside the package directory -- and
# would be lost whenever the caelestia-cli package is reinstalled or the Python
# version bumps and site-packages moves.
#
# So this does two things:
#   1. stages the scheme somewhere root-owned and version independent, then
#      syncs it into the current site-packages
#   2. installs a pacman hook that re-runs the sync after caelestia-cli or
#      python is upgraded, so the scheme survives updates
#
# Run once with sudo:  sudo ./scripts/install-caelestia-schemes.sh
# Remove with:         sudo ./scripts/install-caelestia-schemes.sh --uninstall

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/caelestia-schemes" && pwd)"
STAGE_DIR=/usr/local/share/caelestia-schemes
SYNC_BIN=/usr/local/bin/caelestia-sync-schemes
HOOK=/etc/pacman.d/hooks/95-caelestia-schemes.hook

if [[ $EUID -ne 0 ]]; then
    echo "error: needs root to write into site-packages; re-run with sudo" >&2
    exit 1
fi

if [[ ${1:-} == --uninstall ]]; then
    echo ":: removing catppuccin-true"
    rm -f "$HOOK" "$SYNC_BIN"
    rm -rf "$STAGE_DIR"
    for d in /usr/lib/python3*/site-packages/caelestia/data/schemes/catppuccin-true; do
        [[ -d $d ]] && rm -rf "$d" && echo "   removed $d"
    done
    echo ":: done -- if catppuccin-true was the active scheme, pick another with"
    echo "   caelestia scheme set -n catppuccin -f mocha"
    exit 0
fi

# --- 1. stage the scheme ----------------------------------------------------

if [[ ! -d $SRC_DIR/catppuccin-true ]]; then
    echo "error: $SRC_DIR/catppuccin-true not found -- run scripts/caelestia-schemes/generate.py first" >&2
    exit 1
fi

echo ":: staging schemes in $STAGE_DIR"
install -d -m 755 "$STAGE_DIR"
rm -rf "${STAGE_DIR:?}/catppuccin-true"
cp -r "$SRC_DIR/catppuccin-true" "$STAGE_DIR/"
chown -R root:root "$STAGE_DIR"
chmod -R u=rwX,go=rX "$STAGE_DIR"

# --- 2. install the syncer --------------------------------------------------

echo ":: installing $SYNC_BIN"
cat > "$SYNC_BIN" <<'SYNC'
#!/usr/bin/env bash
# Copy staged caelestia schemes into every installed caelestia site-packages
# tree. Written by dotfiles/scripts/install-caelestia-schemes.sh; also run from
# a pacman hook after caelestia-cli or python upgrades.
set -euo pipefail

STAGE_DIR=/usr/local/share/caelestia-schemes
found=0

for target in /usr/lib/python3*/site-packages/caelestia/data/schemes; do
    [[ -d $target ]] || continue
    found=1
    for scheme in "$STAGE_DIR"/*/; do
        [[ -d $scheme ]] || continue
        name=$(basename "$scheme")
        rm -rf "${target:?}/$name"
        cp -r "$scheme" "$target/$name"
        echo "caelestia-sync-schemes: installed $name -> $target"
    done
done

if [[ $found -eq 0 ]]; then
    echo "caelestia-sync-schemes: no caelestia install found, nothing to do" >&2
fi
SYNC
chmod 755 "$SYNC_BIN"

# --- 3. install the pacman hook --------------------------------------------

echo ":: installing $HOOK"
install -d -m 755 /etc/pacman.d/hooks
cat > "$HOOK" <<'HOOKEOF'
# Reinstall custom caelestia colour schemes after an upgrade wipes or moves
# site-packages. Managed by dotfiles/scripts/install-caelestia-schemes.sh.
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = caelestia-cli
Target = python

[Action]
Description = Restoring custom caelestia colour schemes...
When = PostTransaction
Exec = /usr/local/bin/caelestia-sync-schemes
HOOKEOF
chmod 644 "$HOOK"

# --- 4. sync now ------------------------------------------------------------

echo ":: syncing"
"$SYNC_BIN"

echo
echo ":: done. Available flavours:"
echo "   caelestia scheme set -n catppuccin-true -f mocha      # or macchiato / frappe / latte"
