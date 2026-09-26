# Login screen: SDDM + sddm-astronaut-theme in caelestia colours

**Current setup:** SDDM runs
[sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme), with its
colours, font and wallpaper taken from the palette caelestia is using on the
desktop. It replaces greetd + ReGreet ([login-greeter.md](login-greeter.md)),
which stays installed as the fallback.

## How the pieces fit

| File | What it does |
| ---- | ------------ |
| AUR `sddm-astronaut-theme` | → `/usr/share/sddm/themes/sddm-astronaut-theme/`. The theme, built from upstream git HEAD. Also drops its fonts into `/usr/share/fonts`. |
| [`sddm/sddm.conf.d/10-caelestia.conf`](../sddm/sddm.conf.d/10-caelestia.conf) | → `/etc/sddm.conf.d/`. Selects the theme, cursor, remembered user/session. |
| generated | `…/sddm-astronaut-theme/Themes/astronaut.conf.user` — the caelestia overrides, written by `scripts/sddm-theme.sh`. |
| generated | `…/sddm-astronaut-theme/Backgrounds/caelestia.<ext>` — a copy of the current wallpaper. |

The theme reads `Themes/astronaut.conf` (named in its `metadata.desktop`), and
SDDM layers `<that file>.user` over it key by key, skipping empty values. Only the
`.user` file and the wallpaper copy are written, and pacman owns neither, so theme
updates (`paru -Syu`) keep the caelestia look and no package file is modified.

The mapping follows caelestia's lock screen: the clock in `primary`, the form as a
frosted `surface` panel centred on the blurred wallpaper, fields in
`surfaceContainer`, an accent-filled login button, Rubik throughout, 25px
rounding. The key → role table is in `scripts/sddm-theme.sh`.

## Installing it

```sh
paru -S --needed sddm sddm-astronaut-theme
sudo scripts/setup-sddm.sh
```

The script installs the SDDM config, generates the overrides, then repoints
`display-manager.service` from greetd to sddm. It takes effect at the next boot.

To try it without rebooting, switch to a TTY (`Ctrl+Alt+F2`) and **log in there
first** so you have a way back, then
`sudo systemctl stop greetd && sudo systemctl start sddm`. That kills the running
graphical session.

## Previewing

No root, no logout: build a themed copy in a scratch directory and run the
greeter in a window.

```sh
scripts/sddm-theme.sh ~/.cache/sddm-preview
sddm-greeter-qt6 --test-mode --theme ~/.cache/sddm-preview
```

## Keeping the colours in sync

The sddm user cannot read `/home/png` (mode `0700`), so the palette and wallpaper
are *copied*, and only track the desktop when you re-run:

```sh
sudo scripts/sddm-theme.sh
```

Worth doing after `caelestia scheme set …`, or when variety has rotated to a
wallpaper you want at login. The scheme is `dynamic`, so the palette moves with
the wallpaper — see [caelestia-theming.md](caelestia-theming.md).

## Caveats

- **Font.** caelestia's shell renders in the Google Sans Flex it bundles under
  `/etc/xdg/quickshell/caelestia/assets/`, but that is a QML asset, not a
  fontconfig font, so SDDM uses Rubik, caelestia's other UI font.
- **Cursor.** `sweet-cursors` lives in `~/.local/share/icons`, out of the sddm
  user's reach, so the greeter uses Adwaita.
- **Keyboard.** The greeter runs on X11 and takes its layout from
  `/etc/X11/xorg.conf.d/00-keyboard.conf` (`localectl set-x11-keymap`), not from
  Hyprland's `kb_layout`.
- **Avatar.** astronaut shows a username field rather than a picture.

## Going back to ReGreet

```sh
sudo systemctl disable sddm.service
sudo systemctl enable greetd.service
```

`/etc/greetd` is untouched. To drop the caelestia look but keep SDDM, delete
`Themes/astronaut.conf.user` from the theme directory.
