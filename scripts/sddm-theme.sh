#!/bin/bash
# Theme sddm-astronaut-theme from the live caelestia palette and wallpaper.
#
# The astronaut theme reads Themes/astronaut.conf (named by its metadata.desktop)
# and SDDM layers Themes/astronaut.conf.user on top of it, key by key. Only that
# .user file and a copy of the wallpaper are written here: neither is owned by
# the package, so `paru -Syu` updates the theme without touching them, and
# nothing that pacman tracks is modified.
#
# The sddm user cannot read /home/png (0700), hence the wallpaper copy. Because
# of that copy, the login screen only follows the desktop when this is re-run:
#
#     sudo scripts/sddm-theme.sh
#
# Pass a directory to build a themed copy there instead, which needs no root
# and is how to preview a change before installing it:
#
#     scripts/sddm-theme.sh ~/.cache/sddm-preview
#     sddm-greeter-qt6 --test-mode --theme ~/.cache/sddm-preview
#
# Idempotent. See docs/login-sddm.md.

set -euo pipefail

INSTALLED=/usr/share/sddm/themes/sddm-astronaut-theme
THEME_DIR="${1:-$INSTALLED}"

if [[ ! -f $INSTALLED/metadata.desktop ]]; then
    echo "error: sddm-astronaut-theme is not installed (paru -S sddm-astronaut-theme)" >&2
    exit 1
fi

if [[ $THEME_DIR == "$INSTALLED" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "error: writing to $INSTALLED needs root (sudo $0)" >&2
        exit 1
    fi
else
    # Preview: a private copy of the installed theme to write into.
    mkdir -p "$THEME_DIR"
    cp -rT "$INSTALLED" "$THEME_DIR"
fi

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
SCHEME="$USER_HOME/.local/state/caelestia/scheme.json"
WALLPAPER="$USER_HOME/.local/state/caelestia/wallpaper/current"

if [[ ! -f $SCHEME ]]; then
    echo "error: no caelestia scheme at $SCHEME" >&2
    exit 1
fi

# The config file the theme is set to, e.g. Themes/astronaut.conf.
CONFIG="$(sed -n 's/^ConfigFile=//p' "$THEME_DIR/metadata.desktop")"
OVERRIDES="$THEME_DIR/$CONFIG.user"

# --- wallpaper ---------------------------------------------------------------
# `current` is a symlink into ~/Pictures; resolve it and copy the bytes out, so
# the greeter neither traverses the home directory nor breaks when variety
# rotates the file away.
background=""
if [[ -e $WALLPAPER ]]; then
    src="$(readlink -f "$WALLPAPER")"
    ext="${src##*.}"
    rm -f "$THEME_DIR"/Backgrounds/caelestia.*
    install -D -m 644 "$src" "$THEME_DIR/Backgrounds/caelestia.$ext"
    background="Backgrounds/caelestia.$ext"
    echo "    wallpaper: $(basename "$src") -> $THEME_DIR/$background"
else
    echo "    no current wallpaper; keeping the theme's own background"
fi

# --- overrides ---------------------------------------------------------------
python3 - "$SCHEME" "$OVERRIDES" "$background" <<'PY'
import json
import sys

scheme, out, background = sys.argv[1:]
colours = json.load(open(scheme))["colours"]
c = lambda name: '"#' + colours[name] + '"'

# astronaut key -> caelestia Material role. Roles follow the lock screen:
# primary for the clock and accents, surface tones for the form, and the
# accent-filled button caelestia uses for its own submit action.
roles = {
    "TimeTextColor": "primary",
    "DateTextColor": "onSurface",
    "HeaderTextColor": "secondary",
    "FormBackgroundColor": "surface",
    "BackgroundColor": "surface",
    "DimBackgroundColor": "background",
    "LoginFieldBackgroundColor": "surfaceContainer",
    "PasswordFieldBackgroundColor": "surfaceContainer",
    "LoginFieldTextColor": "onSurface",
    "PasswordFieldTextColor": "onSurface",
    "UserIconColor": "primary",
    "PasswordIconColor": "primary",
    "PlaceholderTextColor": "outline",
    "WarningColor": "error",
    "LoginButtonTextColor": "onPrimary",
    "LoginButtonBackgroundColor": "primary",
    "SystemButtonsIconsColor": "onSurfaceVariant",
    "SessionButtonTextColor": "onSurfaceVariant",
    "VirtualKeyboardButtonTextColor": "onSurfaceVariant",
    "DropdownTextColor": "onSurface",
    "DropdownSelectedBackgroundColor": "secondaryContainer",
    "DropdownBackgroundColor": "surfaceContainer",
    "HighlightTextColor": "onSurface",
    "HighlightBackgroundColor": "surfaceContainerHigh",
    "HighlightBorderColor": "primary",
    "HoverUserIconColor": "tertiary",
    "HoverPasswordIconColor": "tertiary",
    "HoverSystemButtonsIconsColor": "primary",
    "HoverSessionButtonTextColor": "primary",
    "HoverVirtualKeyboardButtonTextColor": "primary",
}

settings = {
    # Rubik is caelestia's UI font and is installed system-wide. The shell's
    # Google Sans Flex is a QML asset under /etc/xdg/quickshell, not a
    # fontconfig font, so SDDM cannot resolve it by name.
    "Font": '"Rubik"',
    # caelestia's large rounding.
    "RoundCorners": '"25"',
    # 24-hour, matching services.useTwelveHourClock = false; the date line is
    # the one caelestia's lock screen shows.
    "HourFormat": '"HH:mm"',
    "DateFormat": '"dddd • d MMMM"',
    "HeaderText": '""',
    "DimBackground": '"0.2"',
    "CropBackground": '"true"',
    # A frosted panel under a centred form, like caelestia's lock card.
    "FormPosition": '"center"',
    "HaveFormBackground": '"true"',
    "PartialBlur": '"true"',
    "FullBlur": '"false"',
    "BlurMax": '"64"',
    "Blur": '"1.5"',
    # Desktop with a physical keyboard.
    "HideVirtualKeyboard": '"true"',
    "PasswordFocus": '"true"',
    "ForceLastUser": '"true"',
}
if background:
    settings["Background"] = f'"{background}"'
    # An image, not a video: nothing to show while it loads.
    settings["BackgroundPlaceholder"] = '""'

lines = [
    "# Generated by scripts/sddm-theme.sh from the caelestia palette.",
    "# Do not edit: re-run `sudo scripts/sddm-theme.sh` instead.",
    "# SDDM layers this over the theme's own config, key by key.",
    "[General]",
]
lines += [f"{k}={v}" for k, v in settings.items()]
lines += [f"{k}={c(v)}" for k, v in roles.items()]
open(out, "w").write("\n".join(lines) + "\n")
PY

chmod 644 "$OVERRIDES"
echo "    overrides: $OVERRIDES"
[[ $THEME_DIR == "$INSTALLED" ]] && echo "done. The login screen picks this up at its next start."
exit 0
