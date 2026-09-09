# Caelestia theming: wallpapers, dynamic colours, and Catppuccin

**Current setup:** the active scheme is `dynamic`, so colours are derived from
the wallpaper, and [variety](#wallpapers-variety) downloads and rotates
wallpapers automatically. `catppuccin-true` is installed alongside as the
fixed-palette alternative — see [switching back](#going-back-to-a-fixed-palette).

## Why the bundled `catppuccin` scheme doesn't look like Catppuccin

caelestia-cli ships a scheme called `catppuccin`, but it is not the Catppuccin
palette. It is a Material You palette *re-derived* from a couple of Catppuccin
key colours, so every hue collapses onto one lavender axis:

| Colour   | Real Catppuccin Mocha | caelestia's `catppuccin` mocha |
| -------- | --------------------- | ------------------------------ |
| `base`   | `#1e1e2e`             | `#131317`                      |
| `text`   | `#cdd6f4`             | `#e5e1e7`                      |
| `red`    | `#f38ba8`             | `#c1a5fd` (purple)             |
| `green`  | `#a6e3a1`             | `#c8e3ff` (blue)               |
| `peach`  | `#fab387`             | `#e0c2f9` (lilac)              |

Red and green being purple and blue is what makes it read as "generic dark
purple" rather than Catppuccin. Setting a different `variant` does not help:
`variant` only has an effect on the `dynamic` (wallpaper-derived) scheme —
named schemes are read verbatim from fixed files, see
`caelestia/utils/scheme.py: Scheme._update_colours`.

So this repo ships its own scheme, `catppuccin-true`.

## `catppuccin-true`

Lives in `scripts/caelestia-schemes/catppuccin-true/`, one file per flavour:
`mocha`, `macchiato`, `frappe` (dark) and `latte` (light).

The 14 accents plus the base/surface/overlay/text ramps are taken verbatim from
[catppuccin/catppuccin](https://github.com/catppuccin/catppuccin). The extra
Material 3 roles caelestia also needs — containers, `on*` pairs, `*Fixed`
variants — are mixes of those same palette colours, so no new hues are
introduced. Each file has the same 110 keys as a bundled scheme, and every
foreground/background pair clears 3:1 contrast (worst case 3.49:1, in latte).

### Installing it

caelestia-cli reads schemes from `<site-packages>/caelestia/data/schemes` and
offers **no user-level override**, so a custom scheme has to be copied into the
package directory:

```sh
sudo cp -r scripts/caelestia-schemes/catppuccin-true \
    /usr/lib/python3.14/site-packages/caelestia/data/schemes/
```

> **This is undone by upgrades.** Reinstalling `caelestia-cli`, or a Python
> minor-version bump moving `site-packages` (3.14 → 3.15), drops the scheme and
> caelestia silently falls back. Re-run the copy afterwards, adjusting the
> Python version in the path.

Then switch to it:

```sh
caelestia scheme set -n catppuccin-true -f mocha
```

To remove it again:

```sh
sudo rm -rf /usr/lib/python3.14/site-packages/caelestia/data/schemes/catppuccin-true
caelestia scheme set -n catppuccin -f mocha
```

## Picking a theme

### Caelestia's built-in picker

Open the launcher (`SUPER + SPACE`) and type `>scheme `. It lists every
scheme with a colour swatch and applies on Enter. `>variant ` switches the
Material variant, which only affects the `dynamic` scheme.

The `>` prefix is pinned in [`caelestia/shell.json`](../caelestia/shell.json)
(`launcher.actionPrefix`) so it does not depend on the upstream default.

Note there is no IPC to open the launcher already in scheme mode —
`caelestia shell -s` exposes only `drawers toggle`, with no way to prefill the
search text — so the picker is always launcher-then-type, and cannot be put on
a keybind of its own.

The built-in picker chooses by name and flavour only. To change light/dark
mode, use the CLI below.

### The CLI

```sh
caelestia scheme set -n catppuccin-true -f mocha       # or macchiato/frappe/latte
caelestia scheme set -m light                          # flip mode
caelestia scheme set -r                                # random
caelestia scheme get                                   # show current + colours
caelestia scheme list --names                          # what's available
```

Switching applies live: caelestia rewrites its templates for GTK, Qt, btop,
htop, fuzzel, Discord clients, spicetify and the terminal, and pushes colours
to Hyprland over IPC (`~/.config/hypr/scheme/current.lua`).

Because caelestia regenerates `~/.config/fuzzel/fuzzel.ini` from its own
template on every scheme change (`caelestia/utils/theme.py: apply_fuzzel`),
**do not stow `fuzzel/fuzzel.ini`** — it is generated, and stowing it would
fight caelestia for the file.

## Wallpapers: variety

caelestia browses and sets wallpapers (`>wallpaper ` in the launcher, or Nexus →
Wallpapers) but cannot *download* them — `caelestia wallpaper` only takes a
local file. [variety](https://peterlevi.com/variety/) fills that gap: it pulls
wallpapers from Wallhaven, Unsplash, Bing, NASA APOD and reddit on a timer.

```sh
sudo pacman -S variety
```

### Wiring it to caelestia

Variety has no Hyprland support of its own, and knows nothing about caelestia.
It shells out to a script for the actual wallpaper change, which is the hook
used here — [`variety/set-wallpaper-caelestia`](../variety/set-wallpaper-caelestia),
stowed to `~/.config/variety/set-wallpaper-caelestia`:

```sh
exec caelestia wallpaper -f "$1"
```

That single call is enough. `caelestia wallpaper -f` sets the wallpaper and,
when the active scheme is `dynamic`, re-derives the entire palette from the
image and auto-picks light/dark mode and Material variant to match it
(`caelestia/utils/wallpaper.py: set_wallpaper`). So the theme follows the
wallpaper with no extra glue.

> **Why the hook is not in `~/.config/variety/scripts/`.** That is variety's
> documented place for it, but variety *regenerates* the scripts in that folder
> on every version upgrade (`VarietyWindow.upgrade_script` — it keeps a
> `set_wallpaper_before_<version>` backup and copies its own default over the
> top). An edit there would be silently reverted. Pointing variety at a path
> outside that folder avoids the problem entirely.

Configure it in `~/.config/variety/variety.conf` **while variety is not
running** (it rewrites that file on exit). Start from variety's own default at
`/usr/lib/python3*/site-packages/variety/data/config/variety.conf` rather than
writing one from scratch, so every key it expects is present, then change:

```ini
set_wallpaper_script = ~/.config/variety/set-wallpaper-caelestia
download_folder = ~/Pictures/Wallpapers
change_interval = 1800
change_on_start = True
```

`download_folder` points at caelestia's wallpaper directory
(`CAELESTIA_WALLPAPERS_DIR`, default `~/Pictures/Wallpapers`) so that everything
variety downloads is also browsable in caelestia's own picker. Variety files
downloads into a per-source subfolder there; caelestia globs recursively, so
they still show up.

`change_interval` is in seconds and defaults to 300. Every change re-themes the
whole desktop here, so 5 minutes is busy — 1800 (30 min) is calmer.

### Sources

The shipped defaults are local folders plus a disabled Flickr entry, so nothing
downloads until a source is added. Format is
`srcN = <enabled>|<type>|<location>`, and the `srcN` keys must be unique:

```ini
src20 = True|wallhaven|https://wallhaven.cc/search?categories=100&purity=100&atleast=2560x1440&sorting=toplist&order=desc&topRange=1y
src21 = True|wallhaven|https://wallhaven.cc/search?q=landscape&categories=100&purity=100&atleast=2560x1440&sorting=random
src22 = True|wallhaven|https://wallhaven.cc/search?colors=424153&categories=100&purity=100&atleast=2560x1440&sorting=relevance
```

`atleast=2560x1440` matters: caelestia's picker filters out images below a
percentage of your largest monitor, so smaller downloads would be fetched and
then never offered.

Two gotchas found the hard way:

- Colour search is a top-level **`colors=`** parameter, not `q=colors:...`. The
  latter parses fine and silently returns zero images.
- Wallhaven only accepts colours from [its own fixed
  palette](https://wallhaven.cc/search), so Catppuccin's `1e1e2e` is not a valid
  value — `424153` is the nearest dark purple, and is what `src22` uses to bias
  towards wallpapers whose derived palette stays in Catppuccin territory.

No Wallhaven API key is needed for SFW searches (`purity=100`);
`wallhaven_api_key` can stay empty. Downloads are capped by `quota_size`
(default 1000 MB) once `quota_enabled` is on, and all downloading is gated
behind `internet_enabled`.

Two constraints worth knowing: the script **must be executable** (variety
checks `os.access(script, os.X_OK)` and silently falls back to gsettings
otherwise), and variety **kills it after 10 seconds**. A full set plus re-theme
measures ~0.2s, since caelestia extracts colour from a 128px thumbnail rather
than the full image, so there is plenty of headroom.

All of the above is also editable in variety's Preferences GUI, as is "run at
startup" — which writes `~/.config/autostart/variety.desktop`, so Hyprland needs
no autostart entry of its own.

Variety's first download can take a couple of minutes: with an empty
`download_folder` there is nothing to show yet, and the download thread backs
off for 180s when it finds no usable downloader. `variety --next` forces it
along. Progress is in `~/.config/variety/variety.log`.

### Catppuccin wallpaper pack

`~/Pictures/Wallpapers/catppuccin-mocha` is a clone of
[orangci/walls-catppuccin-mocha](https://github.com/orangci/walls-catppuccin-mocha)
(333 images), with `.git` deleted afterwards — the shallow clone's pack was
386 MB, roughly half the download. It is wired into variety as a `folder`
source, so it rotates alongside the Wallhaven downloads.

To refresh it later, re-clone rather than pull (there is no `.git` left):

```sh
rm -rf ~/Pictures/Wallpapers/catppuccin-mocha
git clone --depth 1 https://github.com/orangci/walls-catppuccin-mocha.git \
    ~/Pictures/Wallpapers/catppuccin-mocha
rm -rf ~/Pictures/Wallpapers/catppuccin-mocha/.git
```

### When new wallpapers do not show up

Two separate things filter wallpapers, and they fail differently.

**The shell picker is stale.** `>wallpaper ` and Nexus → Wallpapers read a
`FileSystemModel` (`services/Wallpapers.qml`) that scans at startup. Dropping a
whole new directory tree into the wallpapers folder from outside does not
register, and the picker keeps showing the old set. Restart the shell:

```sh
caelestia shell -k
setsid qs -c caelestia -n -d >/dev/null 2>&1 < /dev/null &
```

`caelestia shell -d` is documented as "start the shell detached", but it dies
with the shell that launched it when run from a non-interactive command, which
leaves the desktop with no bar. `setsid` is what actually detaches it.

**`caelestia wallpaper -r` filters by size.** It drops anything below
`threshold` (default 0.8) of the smallest monitor dimension. On a 2560x1440
screen that means images under 2048x1152, which excludes 161 of the 333
Catppuccin wallpapers — most of them 1920x1080. Use `-n` to disable the filter:

```sh
caelestia wallpaper -r -n     # random over all 375, not just the 213 large ones
```

Do **not** reach for `-t` to lower the threshold instead: the argument is
declared without `type=float`, so the value stays a string and
`caelestia wallpaper -r -t 0.7` dies with
`TypeError: '>=' not supported between instances of 'int' and 'str'`.
`-n` is the only working escape hatch.

This filter applies *only* to `-r`. `caelestia wallpaper -f <file>` does no size
checking, and neither does the shell picker, so variety already rotates through
every Catppuccin wallpaper regardless of resolution — it goes through the
bridge, which calls `-f`.

### Going back to a fixed palette

The wallpaper only drives the colours while the scheme is `dynamic`:

```sh
caelestia scheme set -n catppuccin-true -f mocha   # fixed Catppuccin again
caelestia scheme set -n dynamic                    # back to wallpaper-derived
```

Variety keeps rotating wallpapers either way; with a named scheme the colours
simply stop following along. `dynamic` needs a wallpaper to already be set, or
it errors.

## Config tracked here

`caelestia/shell.json` is stowed to `~/.config/caelestia/shell.json`, and
`variety/set-wallpaper-caelestia` to `~/.config/variety/set-wallpaper-caelestia`.

Two things deliberately *not* tracked, because their owners rewrite them:

- `~/.local/state/caelestia/scheme.json` — the active scheme is state, written
  by the CLI, not config.
- `~/.config/variety/variety.conf` — variety rewrites it whenever preferences
  change or it exits. Only the two keys above need setting by hand.

Both of those already exist as real files on this machine, and stow refuses to
link over a real file, so they need removing once before the first `stow`:

```sh
rm ~/.config/caelestia/shell.json ~/.config/variety/set-wallpaper-caelestia
cd ~/dotfiles && stow .
```

Check the bridge survived as an executable symlink afterwards — variety silently
falls back to gsettings (which does nothing under Hyprland) if it is not:

```sh
test -x ~/.config/variety/set-wallpaper-caelestia && echo ok
```
