-- Caelestia Hyprland variable overrides.
--
-- Caelestia installs its own ~/.config/hypr/hyprland.lua and hyprland/*.lua,
-- and that is what Hyprland actually loads -- hypr/hyprland.lua in this repo is
-- no longer read. That config requires this file and merges what it returns
-- over ~/.config/hypr/variables.lua before building any keybinds, so it is the
-- one place where an override survives a caelestia update.

return {
    -- Launcher on SUPER + SPACE. kbLauncher accepts a list, and caelestia's
    -- keybinds.lua applies the `release` flag only to the bare-Super default,
    -- so the tap keeps firing on release while SUPER + SPACE binds on press.
    -- Drop the first entry to free the bare Super tap.
    kbLauncher = { "SUPER + SUPER_L", "SUPER + SPACE" },
}
