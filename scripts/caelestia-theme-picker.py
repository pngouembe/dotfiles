#!/usr/bin/env python3
"""A one-keybind theme picker for caelestia-shell, rendered with fuzzel.

caelestia has a built-in picker (open the launcher, type `>scheme `), but there
is no IPC to open the launcher already in that mode -- `caelestia shell -s`
exposes only `drawers toggle`, with no way to prefill the search text -- so it
cannot be put on a key of its own. This covers that, and also lists the
light/dark mode of each flavour, which the built-in picker does not.

Scheme names, flavours and modes come from caelestia's own Python package
rather than from a hardcoded list, so custom schemes (`catppuccin-true`) and
any the package gains later show up automatically.

Usage:
    caelestia-theme-picker.py            # pick a scheme
    caelestia-theme-picker.py --random   # jump straight to a random one
"""

from __future__ import annotations

import shutil
import subprocess
import sys

try:
    from caelestia.utils.scheme import (
        get_scheme,
        get_scheme_flavours,
        get_scheme_modes,
        get_scheme_names,
    )
except ImportError:
    print("error: caelestia-cli is not installed (cannot import caelestia)", file=sys.stderr)
    raise SystemExit(1)

# Schemes to float to the top of the list, best first.
PREFERRED = ["catppuccin-true", "catppuccin"]


def entries() -> list[tuple[str, str, str]]:
    """Every valid (name, flavour, mode) triple caelestia can switch to."""
    out: list[tuple[str, str, str]] = []

    for name in get_scheme_names():
        for flavour in get_scheme_flavours(name):
            for mode in get_scheme_modes(name, flavour):
                out.append((name, flavour, mode))

    def sort_key(e: tuple[str, str, str]) -> tuple[int, str, str, str]:
        name, flavour, mode = e
        rank = PREFERRED.index(name) if name in PREFERRED else len(PREFERRED)
        return (rank, name, flavour, mode)

    return sorted(out, key=sort_key)


def label(entry: tuple[str, str, str], current: tuple[str, str, str]) -> str:
    name, flavour, mode = entry
    # A marker rather than a separate "current" entry, so the list stays
    # keyboard-navigable in one pass.
    mark = "●" if entry == current else "○"
    return f"{mark} {name} · {flavour} · {mode}"


def pick(options: list[str], preselect: int) -> str | None:
    """Show the fuzzel menu; return the chosen line, or None if cancelled."""
    result = subprocess.run(
        [
            "fuzzel",
            "--dmenu",
            "--prompt=theme ",
            f"--select-index={preselect}",
            "--lines=15",
            "--width=40",
        ],
        input="\n".join(options),
        capture_output=True,
        text=True,
    )

    # fuzzel exits 1 when dismissed with Escape; that is not an error.
    if result.returncode != 0 or not result.stdout.strip():
        return None

    return result.stdout.strip()


def apply(name: str, flavour: str, mode: str) -> int:
    result = subprocess.run(
        ["caelestia", "scheme", "set", "--notify", "-n", name, "-f", flavour, "-m", mode],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
    return result.returncode


def main() -> int:
    if not shutil.which("fuzzel"):
        print("error: fuzzel is not installed", file=sys.stderr)
        return 1

    all_entries = entries()
    if not all_entries:
        print("error: no schemes found", file=sys.stderr)
        return 1

    if "--random" in sys.argv[1:]:
        import random

        return apply(*random.choice(all_entries))

    scheme = get_scheme()
    current = (scheme.name, scheme.flavour, scheme.mode)

    options = [label(e, current) for e in all_entries]
    preselect = all_entries.index(current) if current in all_entries else 0

    chosen = pick(options, preselect)
    if chosen is None:
        return 0

    try:
        entry = all_entries[options.index(chosen)]
    except ValueError:
        # fuzzel returns the typed text when nothing matched.
        print(f"error: no scheme matching {chosen!r}", file=sys.stderr)
        return 1

    if entry == current:
        return 0

    return apply(*entry)


if __name__ == "__main__":
    raise SystemExit(main())
