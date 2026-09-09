# Caelestia theming: real Catppuccin, and the theme picker

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

## Config tracked here

`caelestia/shell.json` is stowed to `~/.config/caelestia/shell.json`. The
active scheme itself is *not* config — it lives in
`~/.local/state/caelestia/scheme.json` and is written by the CLI.

Because `~/.config/caelestia/shell.json` already exists as a real file, stow
will refuse to link over it the first time:

```sh
rm ~/.config/caelestia/shell.json
cd ~/dotfiles && stow .
```
