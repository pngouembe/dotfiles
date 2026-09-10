# Login screen: ReGreet themed from the caelestia palette

**Current setup:** greetd runs [ReGreet](https://github.com/rharish101/ReGreet)
inside a cage kiosk session, styled with the colours caelestia is using on the
desktop. It replaces cosmic-greeter, which CachyOS installs by default.

## Why not caelestia itself

caelestia-shell has no greeter. It ships a *lock* screen
(`/etc/xdg/quickshell/caelestia/modules/lock/`, PAM-backed, bound to
`SUPER + L`), and a lock screen only authenticates a session that is already
running as you. A greeter runs before any user session exists, as an
unprivileged user talking to greetd over a socket — different job, different
privileges, and nothing in the caelestia package does it:

```sh
pacman -Ql caelestia-shell | grep -ci greet   # 0
```

The alternative would have been to autologin and raise the caelestia lock screen
at session start. That gets the real caelestia UI, but the session — and
everything in `exec-once` — starts before the password is typed. ReGreet
authenticates first; the cost is that the login screen is a GTK form wearing
caelestia's colours rather than caelestia.

## How the pieces fit

greetd was already the login daemon here — cosmic-greeter is a greetd front end,
not a display manager of its own — so only the greeter and its config changed:

| File | What it does |
| ---- | ------------ |
| [`greetd/config.toml`](../greetd/config.toml) | → `/etc/greetd/config.toml`. Tells greetd to run `cage -s -- regreet` as the `greeter` user. |
| [`greetd/regreet.toml`](../greetd/regreet.toml) | → `/etc/greetd/regreet.toml`. Fonts, icon/cursor themes, background, greeting. |
| generated | `/etc/greetd/regreet.css` — the palette, written by `scripts/greeter-theme.sh`. |
| generated | `/etc/greetd/background.<ext>` — a copy of the current wallpaper. |

ReGreet is a GTK4 client and needs a compositor to draw into; cage provides one
fullscreen surface and exits when the client exits, which is the signal greetd
uses to hand over to the session.

## Installing it

```sh
sudo pacman -S --needed greetd-regreet cage
sudo scripts/setup-greeter.sh
```

The script backs up whatever is at `/etc/greetd/*.toml`, installs the tracked
copies, generates the theme, then flips `display-manager.service` from
cosmic-greeter to greetd. It takes effect at the next boot.

To try it without rebooting, switch to a TTY (`Ctrl+Alt+F2`) and **log in there
first** so you have a way back, then `sudo systemctl restart greetd`. That kills
the running graphical session.

## Keeping the colours in sync

The greeter user is unprivileged and cannot read `/home/png` (mode `0700`), so
it cannot follow `~/.local/state/caelestia/scheme.json` the way the desktop
does. The palette and wallpaper are *copied* into `/etc/greetd` instead, which
means they only track the desktop when you re-run:

```sh
sudo scripts/greeter-theme.sh
```

Worth doing after `caelestia scheme set …`, or whenever variety has rotated to a
wallpaper you want to see at login. The scheme is `dynamic` here, so the desktop
palette moves with the wallpaper — see
[caelestia-theming.md](caelestia-theming.md) — and the greeter will otherwise
sit on whatever it was last given.

The generated CSS overrides the same handful of libadwaita named colours that
caelestia writes into `~/.config/gtk-4.0/gtk.css`, plus a rounded translucent
card around the login form. Widget-level selectors are kept deliberately thin:
ReGreet's internal widget names are not a stable API, and a selector that stops
matching after an update silently loses its styling rather than erroring.

## Fonts

`font_name = "Rubik 14"`. Rubik is caelestia's UI font and is installed
system-wide. The shell itself renders in the Google Sans Flex it bundles under
`/etc/xdg/quickshell/caelestia/assets/`, but that is a QML asset rather than a
fontconfig font, so GTK cannot resolve it.

Icons and cursors are Adwaita for the same reason the wallpaper is copied: the
desktop's `Papirus-Dark` lives in `~/.local/share/icons`, out of the greeter's
reach.

## Going back to cosmic-greeter

```sh
sudo systemctl disable greetd.service
sudo systemctl enable cosmic-greeter.service
```

cosmic-greeter is left installed, and its config is untouched at
`/etc/greetd/cosmic-greeter.toml` (it reads that, not `config.toml`). The
timestamped `/etc/greetd/config.toml.bak.*` from the first install has the stock
`agreety` fallback, which is what to fall back to if the graphical greeter fails
to start at all.
