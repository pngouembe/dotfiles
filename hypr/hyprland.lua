-- Hyprland configuration (Lua format).
--
-- Hyprland 0.55 deprecated hyprlang and 0.56 stopped falling back to
-- hyprland.conf entirely: if ~/.config/hypr/hyprland.lua is absent it logs
-- "No config file found" and generates a fresh default instead of reading the
-- old .conf. This file is the converted equivalent of the previous
-- hyprland.conf; see https://wiki.hypr.land/Configuring/Start/
--
-- Caelestia's installer drops its OWN ~/.config/hypr/hyprland.lua, plus a
-- hyprland/ module tree, variables.lua and utils/ beside it. A real file there
-- beats a stow symlink, so that install silently shadowed this config: Hyprland
-- read caelestia's tree and none of this. The shadowing copies are parked in
-- ~/.config/hypr/caelestia-unused/; only scheme/ is still live, because the
-- shell regenerates it (see apply_scheme_borders below). The parts of that tree
-- worth keeping are inlined here, each marked "from caelestia", so nothing in
-- this file depends on it and a caelestia update cannot change the config from
-- underneath. An update CAN drop a fresh hyprland.lua on top again -- if the
-- shell's own keybinds suddenly come back, that is what happened, and
-- `stow -R .` in ~/dotfiles puts this file back.
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
-- the commented/uncommented lines in the blocks tagged `SHELL SWITCH` below
-- (autostart, polkit, launcher bind, screenshot binds, media and brightness
-- keys) and reload with `hyprctl reload`.
--
-- Noctalia 5.x bundles its own Quickshell, while caelestia-shell links against
-- the system quickshell-git, so both packages can stay installed side by side.
--
-- Binds tagged "caelestia only" have no Noctalia counterpart. They are left
-- bound in both configurations: under Noctalia they dispatch global shortcuts
-- nothing has registered, and quietly do nothing.
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

    -- Clipboard history, feeding the SUPER + V picker below (from caelestia).
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Forward Bluetooth headset transport buttons to MPRIS (from caelestia).
    hl.exec_cmd("mpris-proxy")

    -- Drop trashed files older than 30 days (from caelestia).
    hl.exec_cmd("trash-empty 30")

    -- Night light, with the geoclue agent supplying the location (from
    -- caelestia). gammastep is packaged on NixOS via nix/modules/home
    -- /_desktop.nix but is not installed on the CachyOS box yet
    -- (`pacman -S gammastep`); the guard keeps this a no-op until it is.
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("command -v gammastep >/dev/null 2>&1 && sleep 1 && exec gammastep")

    -- Rotate the wallpaper on a timer, out of ~/Pictures/Wallpapers.
    --
    -- This replaces variety, which rotated wallpapers but also downloaded new
    -- ones unprompted. Caelestia has no rotation setting of its own -- the
    -- shell only exposes Wallpapers.setRandom() behind the launcher -- so the
    -- timer lives in a small script instead. 1800s matches the interval variety
    -- was set to.
    --
    -- `hyprland.start` fires once per session, so `hyprctl reload` will not
    -- stack a second rotator; the script takes a lock as well.
    hl.exec_cmd(os.getenv("HOME") .. "/dotfiles/scripts/caelestia-wallpaper-rotate.sh 1800")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt platform theme (from caelestia). Without this, Qt loads no platform theme
-- at all, QIcon::themeName() stays empty and icon lookups fall back to bare
-- `hicolor` -- so the caelestia launcher renders blanks for every app whose
-- .desktop Icon= is a freedesktop generic name (network-wired, text-editor,
-- utilities-terminal, ...) rather than a private icon the package dropped into
-- hicolor itself. qtengine reads ~/.config/qtengine/config.json, whose
-- `theme.iconTheme` is the single source of truth for the icon theme
-- (Papirus-Dark) and is kept in sync by caelestia's theming.
--
-- The shell only picks this up at launch, so after changing it restart the
-- shell (`caelestia shell -k && caelestia shell -d`), not just `hyprctl reload`.
--
-- If qtengine is ever unavailable (it is packaged on Arch/CachyOS; the NixOS
-- box would need it adding to nix/modules/home/_desktop.nix), quickshell also
-- honours QS_ICON_THEME as a dependency-free override:
--     hl.env("QS_ICON_THEME", "Papirus-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Gaps, border width, rounding, blur and shadow geometry are caelestia's: a
-- thinner border, heavier rounding and a far softer blur than the Hyprland
-- defaults this config started from.
hl.config({
    general = {
        gaps_in         = 5,
        gaps_out        = 10,
        gaps_workspaces = 20,

        border_size = 1,

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
        rounding       = 15,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 4,
            -- Colour is set by apply_scheme_borders() below.
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            vibrancy          = 0.1696,
            -- Blur what is behind a translucent window, not only what is behind
            -- a fully transparent one. This is what makes the 0.95 opacity
            -- window rule further down read as deliberate rather than washed
            -- out.
            ignore_opacity    = true,
            new_optimizations = true,
            popups            = true,
            input_methods     = true,
            xray              = false,
            special           = false,
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
--
-- dofile, not require: require caches by module name, so a second call would
-- keep handing back the palette from session start.
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

    -- Tint the shadow with the palette too (from caelestia, which uses
    -- inversePrimary at a very low alpha). Optional: a palette without the role
    -- keeps the static shadow set above rather than failing the whole call.
    local shadow = rgba("inversePrimary", "10")
    if shadow then
        hl.config({ decoration = { shadow = { color = shadow } } })
    end

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


-----------------
---- HELPERS ----
-----------------

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

-- Workspaces are addressed in groups of ten: 1-10, 11-20, and so on. SUPER + n
-- picks slot n inside the group you are already on, and CTRL + SUPER + n jumps
-- to the same slot in group n. While you stay in the first group -- which is
-- all this config used to have -- both behave exactly like plain
-- `workspace, n`. From caelestia's utils/functions.lua wsaction, with the slot
-- arithmetic fixed: upstream uses `id % 10`, which sends slot 10 of every group
-- back to workspace 10 instead of 20, 30, ...
local function ws_action(action, range, i)
    return function()
        local active = hl.get_active_workspace()
        if not active then return end

        local id     = active.id
        local target = (range == "group")
            and ((i - 1) * 10 + ((id - 1) % 10) + 1)
            or (math.floor((id - 1) / 10) * 10 + i)

        if action == "move" then
            hl.dispatch(hl.dsp.window.move({ workspace = target }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = target }))
        end
    end
end

-- Grow or shrink the focused window by a percentage of its own size. Returns a
-- closure so the size is read when the bind fires, not when the config loads.
-- From caelestia.
local function resize_active(x, y)
    return function()
        local win = hl.get_active_window()
        if win and win.size then
            hl.dispatch(hl.dsp.window.resize({
                x        = win.size.x * (x / 100),
                y        = win.size.y * (y / 100),
                relative = true,
            }))
        end
    end
end

-- An absolute size, as a percentage of the focused monitor. A zero percentage
-- means "the full extent in that axis". From caelestia.
local function size_by_screen(x, y)
    local screen = hl.get_active_monitor()
    if not screen or type(screen.width) ~= "number" or type(screen.height) ~= "number" then return end
    if x == 0 and y == 0 then return end

    return {
        x        = (x > 0) and math.floor(screen.width * x / 100) or screen.width,
        y        = (y > 0) and math.floor(screen.height * y / 100) or screen.height,
        relative = false,
    }
end

-- Shrink `win` to roughly a quarter of the screen height, keeping its aspect,
-- and park it in the bottom-right corner: the shape a picture-in-picture window
-- wants. Returns the dispatchers rather than running them, so the caller can
-- prepend a float toggle. From caelestia's move_actions.
local function pip_actions(win)
    local screen = hl.get_active_monitor()
    if not (screen and screen.width and screen.height and win and win.size) then return end

    local monitorWidth  = screen.width / screen.scale
    local monitorHeight = screen.height / screen.scale
    local factor        = (monitorHeight / 4) / win.size.y

    local width  = math.floor(math.max(200, win.size.x * factor))
    local height = math.floor(math.max(150, win.size.y * factor))
    local offset = math.min(monitorWidth, monitorHeight) * 0.03

    return {
        hl.dsp.window.resize({ x = width, y = height, window = win }),
        hl.dsp.window.move({
            x        = math.floor(screen.x + monitorWidth - width - offset),
            y        = math.floor(screen.y + monitorHeight - height - offset),
            relative = false,
            window   = win,
        }),
    }
end

-- Run `actions` against `win` when one of its fields matches `pattern`, then
-- size it to `x`/`y` percent of the monitor and pin its aspect ratio. A window
-- rule cannot do this on its own: it fires once at open, before a player has
-- settled on its real aspect. From caelestia.
local function resizer(win, pattern, x, y, actions, exact, field)
    local value = win and win[field or "title"]
    if not (value and string.find(value, pattern, 1, exact)) then return end

    for _, action in ipairs(actions or {}) do
        hl.dispatch(action)
    end

    -- Target the matched window explicitly. Without window=, resize/set_prop
    -- act on the currently focused window instead, mangling whatever tiled
    -- window happened to be focused when this matched.
    local size = size_by_screen(x, y)
    if size then
        size.window = win
        hl.dispatch(hl.dsp.window.resize(size))
    end
    hl.dispatch(hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true", window = win }))
end


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

local locked          = { locked = true }
local mouse           = { mouse = true }
local repeating       = { repeating = true }
local lockedRepeating = { locked = true, repeating = true }

---- Apps ----

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

-- Grab the whole screen without a picker, and record with/without sound
-- (caelestia only). Print is the conventional home for the first; the record
-- chords sit beside the region recorder bound above.
hl.bind("Print",                 hl.dsp.exec_cmd("caelestia screenshot"), locked)
hl.bind("CTRL + ALT + R",        hl.dsp.exec_cmd("caelestia record"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("caelestia record -s"))

-- Shell panels (caelestia only).
hl.bind(mainMod .. " + N",         hl.dsp.global("caelestia:sidebar"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.global("caelestia:clearNotifs"))
hl.bind(mainMod .. " + L",         hl.dsp.global("caelestia:lock"))
hl.bind(mainMod .. " + K",         hl.dsp.global("caelestia:showall"))
hl.bind("CTRL + ALT + Delete",     hl.dsp.global("caelestia:session"))

-- Bring the shell back up and relock, for when the lock screen has been killed
-- out from under a locked session (caelestia only).
hl.bind(mainMod .. " + ALT + L", function()
    hl.dispatch(hl.dsp.exec_cmd("caelestia shell -d"))
    hl.dispatch(hl.dsp.global("caelestia:lock"))
end)

-- Kill / restart the shell (caelestia only).
hl.bind("CTRL + " .. mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("qs -c caelestia kill"), { release = true })
hl.bind("CTRL + " .. mainMod .. " + ALT + R",   hl.dsp.exec_cmd("qs -c caelestia kill; sleep .1; caelestia shell -d"), { release = true })

-- Clipboard history and emoji picker (caelestia only). Both open fuzzel, so
-- the bind doubles as a dismiss while one is up; fed by the cliphist watchers
-- in the autostart block. SUPER + V used to toggle floating -- that moved to
-- SUPER + ALT + SPACE, which is where caelestia puts it too.
hl.bind(mainMod .. " + V",       hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d")) -- delete an entry
hl.bind(mainMod .. " + Period",  hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"))
hl.bind("CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]),
    locked)

---- Window actions ----

hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + ALT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + Backslash",   hl.dsp.window.pin())

-- Keyboard move/resize modes, and the mouse equivalents.
hl.bind(mainMod .. " + Z",         hl.dsp.window.drag(),   mouse)
hl.bind(mainMod .. " + X",         hl.dsp.window.resize(), mouse)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   mouse)
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), mouse)

-- Resize the focused window by 10% of its own size.
hl.bind(mainMod .. " + Minus",         resize_active(-10, 0), repeating)
hl.bind(mainMod .. " + Equal",         resize_active(10, 0),  repeating)
hl.bind(mainMod .. " + SHIFT + Minus", resize_active(0, -10), repeating)
hl.bind(mainMod .. " + SHIFT + Equal", resize_active(0, 10),  repeating)
hl.bind(mainMod .. " + ALT + left",    resize_active(-10, 0), repeating)
hl.bind(mainMod .. " + ALT + right",   resize_active(10, 0),  repeating)
hl.bind(mainMod .. " + ALT + up",      resize_active(0, -10), repeating)
hl.bind(mainMod .. " + ALT + down",    resize_active(0, 10),  repeating)

hl.bind("CTRL + " .. mainMod .. " + Backslash", hl.dsp.window.center())

-- Back to a readable 55% x 70%, centred.
hl.bind("CTRL + " .. mainMod .. " + ALT + Backslash", function()
    local size = size_by_screen(55, 70)
    if size then
        hl.dispatch(hl.dsp.window.resize(size))
    end
    hl.dispatch(hl.dsp.window.center())
end)

-- Shrink the focused window into a pinned picture-in-picture corner.
hl.bind(mainMod .. " + ALT + Backslash", function()
    local win = hl.get_active_window()
    if not win then return end

    local actions = pip_actions(win) or {}
    if not win.floating then
        table.insert(actions, 1, hl.dsp.window.float())
    end
    table.insert(actions, hl.dsp.window.pin({ action = "on", window = "address:" .. win.address }))

    for _, action in ipairs(actions) do
        hl.dispatch(action)
    end
end)

---- Focus and movement ----

-- Move focus with mainMod + arrow keys, carry the window with + SHIFT
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. dir,         hl.dsp.focus({ direction = dir }))
    hl.bind(mainMod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

---- Workspaces ----

-- SUPER + n / SUPER + SHIFT + n stay within the current group of ten;
-- CTRL + SUPER + n / CTRL + SUPER + ALT + n switch group, keeping the slot.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,                    ws_action("focus", "", i))
    hl.bind(mainMod .. " + SHIFT + " .. key,            ws_action("move", "", i))
    hl.bind("CTRL + " .. mainMod .. " + " .. key,       ws_action("focus", "group", i))
    hl.bind("CTRL + " .. mainMod .. " + ALT + " .. key, ws_action("move", "group", i))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Previous / next workspace, and the same by group of ten.
hl.bind("CTRL + " .. mainMod .. " + left",       hl.dsp.focus({ workspace = "-1" }), repeating)
hl.bind("CTRL + " .. mainMod .. " + right",      hl.dsp.focus({ workspace = "+1" }), repeating)
hl.bind(mainMod .. " + Page_Up",                 hl.dsp.focus({ workspace = "-1" }), repeating)
hl.bind(mainMod .. " + Page_Down",               hl.dsp.focus({ workspace = "+1" }), repeating)
hl.bind("CTRL + " .. mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + " .. mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "+10" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Carry the focused window to the previous / next workspace.
hl.bind("CTRL + " .. mainMod .. " + SHIFT + left",  hl.dsp.window.move({ workspace = "-1" }), repeating)
hl.bind("CTRL + " .. mainMod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), repeating)
hl.bind(mainMod .. " + ALT + Page_Up",              hl.dsp.window.move({ workspace = "-1" }), repeating)
hl.bind(mainMod .. " + ALT + Page_Down",            hl.dsp.window.move({ workspace = "+1" }), repeating)

---- Volume, brightness and media ----

-- Volume stays on wpctl under either shell -- both draw an OSD off the
-- resulting PipeWire change -- but unmutes first, so nudging the volume on a
-- muted sink does what it looks like it should.
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    lockedRepeating)
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    lockedRepeating)
hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   lockedRepeating)
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   locked)
hl.bind("XF86AudioMicMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), lockedRepeating)

-- SHELL SWITCH (brightness and media). Routing these through the shell is what
-- raises its on-screen display; the commented lines are the shell-agnostic
-- fallbacks, which change the value but show nothing under caelestia.
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("caelestia:brightnessUp"),   locked)
hl.bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), locked)
-- hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), lockedRepeating)
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), lockedRepeating)

hl.bind("XF86AudioPlay",  hl.dsp.global("caelestia:mediaToggle"), locked)
hl.bind("XF86AudioPause", hl.dsp.global("caelestia:mediaToggle"), locked)
hl.bind("XF86AudioNext",  hl.dsp.global("caelestia:mediaNext"),   locked)
hl.bind("XF86AudioPrev",  hl.dsp.global("caelestia:mediaPrev"),   locked)
hl.bind("XF86AudioStop",  hl.dsp.global("caelestia:mediaStop"),   locked)
-- Requires playerctl
-- hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), locked)
-- hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
-- hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       locked)
-- hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   locked)

-- Media on the keyboard, for a board with no dedicated transport keys
-- (caelestia only).
hl.bind("CTRL + " .. mainMod .. " + SPACE",     hl.dsp.global("caelestia:mediaToggle"), locked)
hl.bind("CTRL + " .. mainMod .. " + Equal",     hl.dsp.global("caelestia:mediaNext"),   locked)
hl.bind("CTRL + " .. mainMod .. " + Minus",     hl.dsp.global("caelestia:mediaPrev"),   locked)
hl.bind("CTRL + " .. mainMod .. " + BackSpace", hl.dsp.global("caelestia:mediaStop"),   locked)


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

-- Slight transparency on everything but fullscreen windows (from caelestia).
-- `override` beats any opacity an app sets for itself; the opaque tag below
-- takes it back for the ones where colour accuracy matters.
hl.window_rule({
    name  = "default-opacity",
    match = { fullscreen = false },

    opacity = "0.95 override",
})

-- Centre floating windows, except xwayland ones -- xwayland popups count as
-- windows, and centring a popup puts it nowhere near what spawned it.
hl.window_rule({
    name  = "centre-floaters",
    match = { float = true, xwayland = false },

    center = true,
})

hl.window_rule({
    -- Initial placement only, so the window does not visibly jump before the
    -- resizer at the bottom of this file settles it.
    name  = "picture-in-picture",
    match = { title = "Picture(-| )in(-| )[Pp]icture" },

    move              = "(monitor_w*0.98-window_w) (monitor_h*0.97-window_h)",
    pin               = true,
    float             = true,
    keep_aspect_ratio = true,
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


----------------------
---- Tagged rules ----
----------------------
--
-- From caelestia. Tagging keeps the match lists apart from the behaviour they
-- select, so a new app joins a list without repeating the rule body. Every tag
-- has to be applied before it is defined, which is why the definitions sit at
-- the end of this block.

-- Tag each of `matches` with `tag`. With `field`, matches are plain strings
-- tested against that one field; without it, they are full match tables.
local function tag_windows(tag, matches, field)
    for _, match in ipairs(matches) do
        if field then
            match = { [field] = match }
        end
        hl.window_rule({ match = match, tag = "+" .. tag })
    end
end

local function define_tag(tag, rules)
    rules.match = { tag = tag }
    hl.window_rule(rules)
end

-- Apps that must stay opaque: terminals, anything showing real colours, and
-- the shell itself.
tag_windows("opaque", {
    "kitty|foot|Alacritty",          -- Terminals
    "org.quickshell",                -- Quickshell (the shell)
    "feh|imv|swappy",                -- Image viewers
    "krita|gimp|inkscape|darktable", -- Image editors
    "resolve|kdenlive|shotcut",      -- Video editors
    "blender|godot",                 -- 3D editors
}, "class")

-- Windows that have no business being tiled.
tag_windows("float", {
    "guifetch",                         -- System info
    "yad|zenity",                       -- Dialogs
    "wev",                              -- Input detector
    "org.gnome.FileRoller|file-roller", -- Archive manager
    "blueman-manager",                  -- Bluetooth GUI
    "feh|imv|swappy",                   -- Image viewers
    "org.quickshell",                   -- Quickshell
}, "class")
tag_windows("float", {
    "File (Operation|Upload)( Progress)?", -- File manager progress dialogs
    ".* Properties",                       -- File properties
    'Rename ".*"',                         -- File renaming
}, "title")

-- Floating, at a fixed fraction of the monitor.
tag_windows("float_60_70", {
    "(Select|Open)( a)? (File|Folder)(s)?", -- File pickers
    "Save As",                              -- Save dialogs
}, "title")
tag_windows("float_60_70", {
    { title = "(Save|Export) Image", class = "gimp" },
})
tag_windows("float_60_70", {
    "org.pulseaudio.pavucontrol|com.saivert.pwvucontrol", -- Audio control
}, "class")
tag_windows("float_70_80", {
    "org.gnome.Settings",
}, "class")
tag_windows("float_50_60", {
    "nwg-look",              -- GTK theme manager
    "system-config-printer", -- Printer config
}, "class")

-- Games: no transparency, and keep the screen awake.
tag_windows("game", {
    "steam_app_[0-9]+",  -- Steam
    "steam_app_default", -- Lutris
    "gamescope",
}, "class")
tag_windows("float", { { class = "steam", title = "Friends List" } })

-- XWayland popups: chrome-less, unstyled, and cheap to draw.
tag_windows("xwl_popup", {
    { xwayland = true, title = "win[0-9]+" },
    { xwayland = true, title = "", class = "", initial_title = "", initial_class = "" },
    { class = "steam", title = "" },
})

-- Ueberzugpp draws terminal image previews; focusing one steals the terminal's
-- keyboard.
hl.window_rule({ match = { class = "ueberzugpp_.*" }, float = true, no_initial_focus = true })

define_tag("opaque",      { opaque = true })
define_tag("float",       { float = true })
define_tag("float_50_60", { float = true, size = "(monitor_w*0.5) (monitor_h*0.6)", center = true })
define_tag("float_60_70", { float = true, size = "(monitor_w*0.6) (monitor_h*0.7)", center = true })
define_tag("float_70_80", { float = true, size = "(monitor_w*0.7) (monitor_h*0.8)", center = true })
define_tag("game",        { opaque = true, idle_inhibit = "always" })
define_tag("xwl_popup", {
    no_dim    = true,
    no_shadow = true,
    no_blur   = true,
    opaque    = true,
    rounding  = 10, -- Popups are small, so cap the rounding
})


-------------------------
---- Workspace rules ----
-------------------------

-- Widen the gap when a workspace holds a single tiled or fullscreen window, so
-- one window does not sit flush against the shell's bar (from caelestia).
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 20 })
hl.workspace_rule({ workspace = "f[1]s[false]",   gaps_out = 20 })


---------------------
---- Layer rules ----
---------------------

hl.layer_rule({ match = { namespace = "selection" }, animation = "fade" })                  -- slurp region picker
hl.layer_rule({ match = { namespace = "wayfreeze" }, animation = "fade" })                  -- frozen screenshot overlay
hl.layer_rule({ match = { namespace = "launcher" }, animation = "popin 80%", blur = true }) -- fuzzel, behind the clipboard and emoji pickers

-- The shell's own surfaces.
hl.layer_rule({ match = { namespace = "caelestia-(border-exclusion|area-picker)" }, no_anim = true })
hl.layer_rule({ match = { namespace = "caelestia-(drawers|background)" }, animation = "fade" })


----------------------------
---- Picture-in-picture ----
----------------------------

-- A window rule fires once, at open, before a video player has settled on its
-- real aspect ratio, so the final sizing has to happen on title/open events
-- instead (from caelestia).
local function apply_resizer_rules(win)
    resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions(win) or {}, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)


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
