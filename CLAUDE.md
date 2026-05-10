# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal NixOS system configuration (hosts, desktop environment, dev tooling, home-manager) for user `png`. There is no application code here — every change ends up flowing through `nixos-rebuild` on one of the configured hosts.

## Common commands

```sh
# Apply the configuration for the current host (matches `hostname`).
sudo nixos-rebuild switch --flake .#paul-desktop
sudo nixos-rebuild switch --flake .#paul-old-desktop

# Dry-run a build without activating it.
nixos-rebuild build --flake .#paul-desktop

# Evaluate the whole flake (catches eval errors across all outputs/hosts).
nix flake check

# Update inputs (commit flake.lock separately).
nix flake update
nix flake lock --update-input nixpkgs   # single input

# Format Nix files (the formatter pinned in development.nix).
nixfmt **/*.nix

# Build a single wrapped program package without rebuilding the system.
nix build .#hyprland
nix build .#kitty
nix build .#starship
```

Conventional Commits is used throughout history (`feat:`, `fix:`, `refactor:`). Match that style.

## Architecture

### Flake layout (flake-parts + dendritic)

`flake.nix` is intentionally tiny. It loads `flake-parts` and uses `vic/import-tree` to **auto-import every `.nix` file under `modules/`**. There is no central `imports = [ ... ]` list — adding a new file under `modules/` is enough to register it. Each file is itself a flake-parts module that contributes to top-level outputs (`flake.nixosModules.*`, `flake.nixosConfigurations.*`, `perSystem.packages.*`, etc.).

Practical consequence: when adding a module, define it as `{ flake.nixosModules.<name> = { ... }: { ... }; }` (or the appropriate `perSystem` shape) rather than expecting somewhere to import it.

### Module composition

Hosts are assembled in `modules/hosts/<host>.nix`. They reference modules indirectly through `config.flake.nixosModules.*`, which are in turn defined under `modules/nixosModules/`:

- `base.nix` — boot, locale, user `png`, zsh, swap, nix experimental features.
- `desktop/desktop.nix` — Hyprland (uses the wrapped package from `self.packages`), GDM/GNOME, pipewire, bluetooth, firefox, kitty.
- `gaming.nix` — Steam + proton-ge.
- `development.nix` — git, nix tooling (nixfmt, nil, nixd), zed-editor, gcc, claude-code, lmstudio.
- `home/_home.nix` — the home-manager user config for `png` (imported into each host via the inline `home-manager.users.png = import ...` block).

Hardware lives separately under `modules/hosts/_machines/`. Each host imports one `*-hardware-config.nix` (machine-specific UUIDs, kernel modules) which itself imports a GPU profile from `gpu_configs/` (`amd.nix` or `nvidia.nix`). Don't hand-edit these except to swap GPU imports — they are largely `nixos-generate-config` output.

### `wrappedPrograms/` — packaged program configs

Programs that need configuration baked into the binary (rather than dropped into `~/.config`) are built as flake packages using `Lassulus/wrappers`. Pattern: each subdirectory exposes `perSystem.packages.<name>` whose `.wrapper` is the configured program.

- `kitty/` — Catppuccin Mocha theme inlined in `settings`.
- `starship/` — points at the local `starship.toml`.
- `hyprland/` — the most involved one: wraps upstream Hyprland, sets `NIXOS_OZONE_WL` / `NOCTALIA_CACHE_DIR`, bundles `noctalia-shell` + `quickshell` as `extraPackages`, and rewrites the `source = ./noctalia/noctalia-colors.conf` line in `hypr/hyprland.conf` to a Nix-store path before installing.

Consumers reference these via `self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` (see `desktop.nix` for hyprland/kitty, `home/_home.nix` for starship). Use `pkgs.stdenv.hostPlatform.system`, not the deprecated `pkgs.system`.

### Home-manager: dotfiles strategy

`home/_home.nix` deliberately mixes two persistence strategies:

1. **HM program modules** (`programs.zsh`, `programs.starship`, `programs.fzf`, `programs.zoxide`, `programs.opencode`) — managed declaratively in Nix.
2. **Out-of-store symlinks** to `/home/png/workspace/dotfiles` via `config.lib.file.mkOutOfStoreSymlink` for files that are iterated on outside Nix (alacritty, tmux, zellij, NvChad lua configs, zsh aliases sourced by `initContent`). Editing those dotfiles takes effect without a rebuild. **This path is hard-coded** — the dotfiles repo must be cloned at `/home/png/workspace/dotfiles` for the activation to succeed.
3. **In-tree `home.file` sources** (zed `settings.json`/`keymap.json`, noctalia `settings/colors/plugins.json`) for configs the flake fully owns. Noctalia's links are load-bearing — without them the shell logs `plugins.json: File does not exist` and the bar is invisible.

NvChad has a one-shot bootstrap in `home.activation.nvchadBootstrap`: it clones `NvChad/starter` into `~/.config/nvim` on first activation, then deletes the starter's `chadrc.lua` / `plugins/` so the symlinked versions take over. Any plugin/config changes upstream go through the dotfiles repo, not this flake.

### Host conventions

- Hostnames in `nixosConfigurations` (`paul-desktop`, `paul-old-desktop`) are the rebuild targets, but `networking.hostName` is set to `"nixos"` in `base.nix` for both.
- `home-manager.backupFileExtension = "bak"` is set in `base.nix` so HM activation can replace pre-existing config files without aborting.
- `home-manager.useGlobalPkgs = true` — HM shares the system `nixpkgs`, so don't introduce a separate `nixpkgs` input for it.
