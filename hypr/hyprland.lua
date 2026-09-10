-- Hyprland configuration (Lua format).
--
-- Hyprland 0.55 deprecated hyprlang and 0.56 stopped falling back to
-- hyprland.conf entirely: if ~/.config/hypr/hyprland.lua is absent it logs
-- "No config file found" and generates a fresh default instead of reading the
-- old .conf. This file is the converted equivalent of the previous
-- hyprland.conf; see https://wiki.hypr.land/Configuring/Start/
--
-- The full API surface is stubbed at
-- $(hyprland)/share/hypr/stubs/hl.meta.lua


------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "hyprlauncher"


-------------------
---- AUTOSTART ----
-------------------

-- ---------------------------------------------------------------------------
-- ACTIVE SHELL: caelestia
--
-- Caelestia and Noctalia are mutually exclusive -- both draw a bar, a launcher
-- and OSDs, so exactly one may run at a time. To fall back to Noctalia, swap
-- the commented/uncommented lines in the four blocks tagged `SHELL SWITCH`
-- below (autostart, polkit, launcher bind, screenshot binds) and reload with
-- `hyprctl reload`.
--
-- Noctalia 5.x bundles its own Quickshell, while caelestia-shell links against
-- the system quickshell-git, so both packages can stay installed side by side.
-- ---------------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Brings up graphical-session.target (see nix/modules/home/_desktop.nix on
    -- NixOS, systemd/user/hyprland-session.target on Arch/CachyOS), without
    -- which xdg-desktop-portal refuses to start and GTK4 apps render in light
    -- mode. Importing the environment first is what lets the portal and the
    -- shell find the compositor.
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    -- SHELL SWITCH (autostart)
    hl.exec_cmd("caelestia shell -d")
    -- hl.exec_cmd("noctalia -d")

    -- SHELL SWITCH (polkit)
    -- Caelestia ships no polkit agent, so one is started here. Noctalia has a
    -- built-in agent (shell.polkit_agent in ~/.config/noctalia/config.toml);
    -- when falling back, comment this line out rather than running two agents.
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")

    hl.exec_cmd("syncthing --no-browser")

    -- Wallpaper rotation. Variety writes ~/.config/autostart/variety.desktop
    -- when "run at startup" is ticked, and systemd's xdg-autostart generator
    -- does turn that into app-variety@autostart.service -- but nothing here
    -- ever activates xdg-desktop-autostart.target (it sits inactive with an
    -- empty WantedBy), because Hyprland started from a greeter, without uwsm,
    -- does not pull it in. So the generated unit never runs and variety never
    -- came up. Starting it explicitly is also more selective than activating
    -- that target, which would drag in every other autostart entry on the
    -- system (Cosmic's initial setup, the geoclue demo agent, and so on).
    --
    -- The delay mirrors the one variety puts in its own .desktop file: with
    -- change_on_start it sets a wallpaper the moment it comes up, and that
    -- goes through `caelestia wallpaper -f`, so it wants the shell up first.
    hl.exec_cmd([[sh -c "sleep 15 && exec variety"]])
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        -- Fallback only. apply_scheme_borders() below overwrites these with
        -- the current caelestia palette immediately after this config call,
        -- and again on every scheme/wallpaper change.
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- ---------------------------------------------------------------------------
-- DYNAMIC BORDER COLOURS
--
-- Caelestia rewrites ~/.config/hypr/scheme/current.lua -- a plain Lua table of
-- the active palette -- every time the scheme or the wallpaper changes. It only
-- writes that file though; nothing pushes the colours into Hyprland, and
-- `hyprctl keyword` is rejected outright under the Lua config provider
-- ("keyword can't work with non-legacy parsers. Use eval."). So the mapping
-- from palette to borders lives here.
--
-- This is a global on purpose: Lua state persists between `hyprctl eval` calls,
-- so the whole thing can be re-applied without a config reload via
--
--     hyprctl eval 'apply_scheme_borders()'
--
-- which is what the caelestia `theme.postHook` in ~/.config/caelestia/cli.json
-- runs on every scheme and wallpaper change. Keeping the role mapping in one
-- place means the hook never has to know which colours are used.
-- ---------------------------------------------------------------------------

function apply_scheme_borders()
    local path = os.getenv("HOME") .. "/.config/hypr/scheme/current.lua"

    -- Missing or half-written file: leave whatever is already set alone rather
    -- than blanking the borders.
    local ok, scheme = pcall(dofile, path)
    if not ok or type(scheme) ~= "table" then
        return false
    end

    local function rgba(role, alpha)
        local hex = scheme[role]
        if type(hex) ~= "string" then
            return nil
        end
        return "rgba(" .. hex .. alpha .. ")"
    end

    -- primary -> tertiary keeps the two-tone gradient of the original static
    -- colours; outlineVariant is the palette's own subtle divider tone.
    local active_from = rgba("primary", "ee")
    local active_to   = rgba("tertiary", "ee")
    local inactive    = rgba("outlineVariant", "aa")

    if not (active_from and active_to and inactive) then
        return false
    end

    hl.config({
        general = {
            col = {
                active_border   = { colors = { active_from, active_to }, angle = 45 },
                inactive_border = inactive,
            },
        },
    })

    return true
end

apply_scheme_borders()

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,us",
        kb_variant = ",intl",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Focus the first window whose class matches `pattern` (a Lua pattern, matched
-- against the lowercased class), or run `cmd` when no such window exists.
-- Hyprland 0.56 made `hyprctl dispatch` take Lua, so the old shell one-liners
-- (`hyprctl dispatch focuswindow class:zen`) no longer parse and silently fail.
local function focus_or_launch(pattern, cmd)
    return function()
        for _, w in ipairs(hl.get_windows()) do
            if w.class:lower():match(pattern) then
                hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
                return
            end
        end
        hl.exec_cmd(cmd)
    end
end

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
-- SHELL SWITCH (launcher). Caelestia exposes its panels as Hyprland global
-- shortcuts (`caelestia shell -s` lists them all) rather than as CLI messages,
-- so this is a `global` dispatch, not an exec. The submap dance upstream
-- documents is only needed to open the launcher on a bare Super tap; a plain
-- modifier+key bind like this one needs none of it.
hl.bind(mainMod .. " + SPACE", hl.dsp.global("caelestia:launcher"))
-- hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("zeditor"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd([[command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch "hl.dsp.exit()"]]))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
-- Zen ships under different binary names per distro: the zen-browser flake on
-- NixOS provides `zen`, while Arch's zen-browser-bin installs only
-- `zen-browser`. Both set StartupWMClass=zen, so the focus half is portable and
-- only the launch command has to be resolved at runtime.
hl.bind(mainMod .. " + B", focus_or_launch("^zen$", "command -v zen-browser >/dev/null 2>&1 && zen-browser || zen"))
hl.bind(mainMod .. " + G", focus_or_launch("^steam$", "steam"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- SHELL SWITCH (screenshots). Caelestia's built-in capture; annotation is
-- handled by swappy, which caelestia-cli depends on, rather than by satty.
-- `screenshotFreeze` freezes the screen before letting you draw the region,
-- matching the freeze_screen = true that Noctalia was configured with.
--
-- Caelestia has no equivalent of Noctalia's "fullscreen pick" (pick a monitor),
-- so SUPER+ALT+P is left on `caelestia record -r` -- region screen recording --
-- which is the nearest useful thing Caelestia offers on a spare bind. Drop the
-- line if you would rather keep the chord free.
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.global("caelestia:screenshotFreeze"))
hl.bind(mainMod .. " + CTRL + P",  hl.dsp.global("caelestia:screenshot"))
hl.bind(mainMod .. " + ALT + P",   hl.dsp.exec_cmd("caelestia record -r"))
-- hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
-- hl.bind(mainMod .. " + CTRL + P",  hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
-- hl.bind(mainMod .. " + ALT + P",   hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"))

-- Caelestia extras with no Noctalia counterpart. These are additive, so they
-- are left bound in both configurations -- under Noctalia they are simply
-- global shortcuts nothing has registered, and do nothing.
hl.bind(mainMod .. " + N",         hl.dsp.global("caelestia:sidebar"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.global("caelestia:clearNotifs"))
hl.bind(mainMod .. " + L",         hl.dsp.global("caelestia:lock"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9], move active window with + SHIFT
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    -- Ignore maximize requests from all apps.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "workspace-steam",
    match = { class = "^([Ss]team)$" },

    workspace = "9",
})

hl.window_rule({
    name  = "workspace-zen",
    match = { class = "^(zen)$" },

    workspace = "2",
})


-----------------------
---- SHELL THEMING ----
-----------------------

-- Caelestia applies its scheme to Hyprland over IPC at runtime (see
-- `caelestia scheme set -n <name>`), so it needs nothing sourced from here.
--
-- The Noctalia block below stays regardless of which shell is active: it is a
-- guarded no-op while ~/.config/hypr/noctalia.lua is absent or stale, and it is
-- what restores the border colours on a fallback to Noctalia.

-- Noctalia renders its palette to ~/.config/hypr/noctalia.lua. Loading it is
-- guarded so that a missing/not-yet-generated file degrades to default colours
-- instead of failing the whole config. Noctalia's apply.sh greps this file for
-- the literal require("noctalia") to decide whether to append its own include,
-- so the string above must stay in this comment.
local ok, noctalia = pcall(require, "noctalia")
if ok then
    noctalia.apply_theme()
end
