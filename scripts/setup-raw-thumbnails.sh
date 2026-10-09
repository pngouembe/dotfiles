#!/bin/bash
# Give Nautilus (and anything else using the freedesktop thumbnailer spec)
# thumbnails for camera RAW files, from the JPEG preview embedded in each one.
#
# Install exiftool (extracts the preview) and libvips (scales it) first:
#
#     sudo pacman -S --needed perl-image-exiftool libvips
#
# Idempotent: safe to re-run. Requires root.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "error: run as root (sudo $0)" >&2
    exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for pkg in perl-image-exiftool libvips; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "error: $pkg is not installed (pacman -S --needed perl-image-exiftool libvips)" >&2
        exit 1
    fi
done

# Copied, not symlinked: the thumbnailer sandbox can't follow links into $HOME
install -D -m 755 "$REPO/thumbnailers/raw-thumbnailer" /usr/local/bin/raw-thumbnailer
install -D -m 644 "$REPO/thumbnailers/raw.thumbnailer" /usr/local/share/thumbnailers/raw.thumbnailer
echo "    /usr/local/bin/raw-thumbnailer"
echo "    /usr/local/share/thumbnailers/raw.thumbnailer"

cat <<'EOF2'

Done. As your user, drop cached failures and restart Nautilus:

    rm -rf ~/.cache/thumbnails/fail && nautilus -q
EOF2
