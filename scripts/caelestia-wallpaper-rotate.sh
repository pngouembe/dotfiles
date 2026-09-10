#!/usr/bin/env bash
#
# Rotate the caelestia wallpaper on a timer, from local files only.
#
# `caelestia wallpaper -r` picks a random image out of caelestia's wallpaper
# directory (~/Pictures/Wallpapers unless CAELESTIA_WALLPAPERS_DIR or
# paths.wallpaperDir says otherwise), skips whichever one is already set, and --
# because the active scheme is `dynamic` -- re-derives the whole palette from
# it, picking light/dark and the Material variant to match. Nothing is ever
# fetched from the network: that is the entire point, and why variety is gone.
#
# This has to run under Hyprland rather than as a systemd user timer. The CLI
# filters candidates by monitor size, and reads the monitor list over the
# Hyprland IPC socket at $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE.
# Caelestia never runs `systemctl --user import-environment`, so a user unit
# would not see that signature and every rotation would fail.
#
# Started from caelestia/hypr-user.lua, which is where the interval lives.
#
# Usage: caelestia-wallpaper-rotate.sh [INTERVAL_SECONDS] [DIR]
#
# Note that the CLI searches DIR recursively and offers no way to exclude a
# subfolder, so anything nested under the wallpaper directory joins the
# rotation. Pass DIR to rotate over a subfolder instead of the whole tree.

set -uo pipefail

readonly interval="${1:-1800}"
readonly dir="${2:-}"
readonly lock="${XDG_RUNTIME_DIR:-/tmp}/caelestia-wallpaper-rotate.lock"

# Bare `-r` falls back to caelestia's own wallpaper directory.
if [ -n "$dir" ]; then
    readonly -a random_arg=(-r "$dir")
else
    readonly -a random_arg=(-r)
fi

# One rotator per session at most. `hyprland.start` already fires only once,
# but this also covers a stray manual run racing the session's own loop.
exec 9>"$lock"
if ! flock -n 9; then
    echo "caelestia-wallpaper-rotate: already running, exiting" >&2
    exit 0
fi

while true; do
    # Sleep first, so the wallpaper chosen at login survives a full interval
    # and the shell has time to come up before the first switch.
    sleep "$interval"

    # A single unreadable image, or a shell that is still starting, must not
    # end the loop -- it would stay dead until the next login.
    caelestia wallpaper "${random_arg[@]}" ||
        echo "caelestia-wallpaper-rotate: switch failed, retrying in ${interval}s" >&2
done
