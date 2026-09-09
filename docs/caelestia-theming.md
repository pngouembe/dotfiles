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
src4 = True|wallhaven|https://wallhaven.cc/search?categories=100&purity=100&atleast=2560x1440&ratios=landscape&sorting=toplist&order=desc&topRange=1y
src5 = True|wallhaven|https://wallhaven.cc/search?q=landscape&categories=100&purity=100&atleast=2560x1440&ratios=landscape&sorting=random
src6 = True|wallhaven|https://wallhaven.cc/search?colors=424153&categories=100&purity=100&atleast=2560x1440&ratios=landscape&sorting=relevance
src12 = True|folder|/home/png/Pictures/Wallpapers/catppuccin-mocha
```

Variety renumbers `srcN` keys itself on exit, so the numbers above are whatever
it settled on rather than something to preserve.

`ratios=landscape` matters as much as `atleast=`. On its own, `atleast=2560x1440`
admits tall portraits — a 4000x7417 image clears both bounds — which then get
downloaded and merely skipped at display time. Filtering by ratio stops them
server-side, so they are never fetched.

`atleast=2560x1440` matters: `caelestia wallpaper -r` filters out images below a
percentage of your largest monitor, so smaller downloads would be fetched and
then never offered.

Belt and braces, `min_size` re-checks the same thing locally:

```ini
min_size_enabled = True
min_size = 100
use_landscape_enabled = True
```

`min_size` is a percentage of the GDK screen size (2560x1440 here, reported
correctly under XWayland), so 100 means native resolution or better. Note it is
a *display-time* filter (`VarietyWindow.image_ok`), not a download-time one —
it stops an undersized image being shown, but the download already happened.
The query parameters are the only thing that prevents the fetch.

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

### The download folder, and what the quota can delete

Variety picks its real download folder at startup
(`VarietyWindow.get_real_download_folder`): if `download_folder` is missing or
**empty**, it claims it outright and drops a `.variety_download_folder` marker
in it; if the folder already has files, it uses a `Downloaded by Variety`
subfolder instead.

This is worth getting right, because the quota (`quota_size`, default 1000 MB)
purges **oldest images first** across everything under that folder
(`purge_downloaded` just walks it), with no notion of which files it downloaded.

Here the marker sits in `~/Pictures/Wallpapers/Downloaded by Variety/`, so the
quota only ever touches variety's own downloads and the Catppuccin pack beside
it is out of reach. Had variety claimed the top level — which it does when
pointed at an empty folder — the pack would have been eligible for deletion.
Check with:

```sh
find ~/Pictures/Wallpapers -maxdepth 2 -name .variety_download_folder
```

If that marker turns up at the top level, move it (and variety's downloads)
into a subfolder, or keep the local packs somewhere outside `download_folder`.

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

**The shell picker shows only part of the library.** `>wallpaper ` and Nexus →
Wallpapers read a `FileSystemModel` (`services/Wallpapers.qml`). It enumerates
the tree fully at startup, but it does not converge while files are being
written underneath it: each filesystem event produces a partial update, and it
then sits on that partial list. Measured directly — the picker held at 45
entries through 90s of an idle filesystem, jumped to 76 the moment three files
landed, then held at 76 through another 90s. It does not heal with time; only
the arrival of more events moves it, and never to the full count.

So a picker showing a fraction of the library is a symptom, not the disease:
**something is still writing to the wallpapers folder.** Check before reaching
for a restart:

```sh
tail -3 ~/.config/variety/variety.log     # is variety still downloading?
```

The usual culprit is variety never finishing (see below). Once writes have
genuinely stopped, one restart against the quiet filesystem enumerates
everything and it stays complete:

```sh
caelestia shell -k
setsid qs -c caelestia -n -d >/dev/null 2>&1 < /dev/null &
```

`caelestia shell -d` is documented as "start the shell detached", but it dies
with the shell that launched it when run from a non-interactive command, which
leaves the desktop with no bar. `setsid` is what actually detaches it.

### Why variety may never stop downloading

Variety's download thread runs until every downloader has more than
`MAX_UNSEEN_PER_DOWNLOADER` (10) *unseen* images. An image only counts as unseen
if it passes `image_ok`. Anything rejected there is downloaded and then
discarded, so a filter that rejects most images means the queue never fills and
variety downloads forever — which in turn keeps the picker permanently partial.

Two settings caused exactly that here, both variety defaults:

- `lightness_enabled = True` with `lightness_mode = 0` (Dark) rejects any image
  whose dominant lightness is >= 75. Sampled against the actual downloads, that
  was **65% of them**. Turned off: the `dynamic` scheme already flips light/dark
  to match whatever wallpaper is showing, so constraining wallpapers to dark
  ones bought nothing.
- `quota_size = 1000` (MB) with the download folder at 836 MB. `purge_downloaded`
  deletes oldest-first once the folder passes 95% of quota, and deleting a file
  drops it from `unseen_downloads`, which triggers more downloading — a
  self-sustaining download/delete loop. Raised to 3000.

After both changes variety filled its queues and went silent, verified over
5 minutes of no log writes; the picker then enumerated all 383 images on one
restart and stayed complete.

In steady state variety fetches roughly one image per `change_interval`, which
is far too little churn to disturb the model.

> **Changing a source URL orphans its download folder.** The folder name is
> derived from the query, so adding `ratios=landscape` made variety abandon its
> old folders and start new ones. The old images stay on disk and still show in
> the picker, but nothing refreshes them. `ls "~/Pictures/Wallpapers/Downloaded by Variety"`
> shows the orphans; delete them if you do not want them.

**`caelestia wallpaper -r` filters by size.** It drops anything below
`threshold` (default 0.8) of the smallest monitor dimension. On a 2560x1440
screen that means images under 2048x1152. This only bites if the library
contains undersized images at all — the Catppuccin pack was pruned to native
resolution, so it no longer does. If it did, `-n` disables the filter:

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
