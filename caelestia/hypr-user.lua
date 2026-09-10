-- Caelestia Hyprland user config.
--
-- Caelestia installs its own ~/.config/hypr/hyprland.lua, and that file
-- requires this one last, after every hyprland/*.lua. It is the sanctioned
-- place for my own execs and binds: caelestia recreates it empty when missing
-- but never overwrites it, so what lives here survives a caelestia update.
-- See caelestia/hypr-vars.lua for variable overrides, which are merged earlier.

-- Rotate the wallpaper on a timer, out of ~/Pictures/Wallpapers.
--
-- This replaces variety, which rotated wallpapers but also downloaded new ones
-- unprompted. Caelestia has no rotation setting of its own -- the shell only
-- exposes Wallpapers.setRandom() behind the launcher -- so the timer lives in
-- a small script instead. 1800s matches the interval variety was set to.
--
-- `hyprland.start` fires once per session, so `hyprctl reload` will not stack a
-- second rotator; the script takes a lock as well.
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/dotfiles/scripts/caelestia-wallpaper-rotate.sh 1800")
end)
