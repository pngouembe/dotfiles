#!/usr/bin/env python3
"""Generate a true-to-spec Catppuccin scheme for caelestia-shell.

caelestia-cli ships its own "catppuccin" scheme, but it is a Material You
re-derivation seeded from Catppuccin's key colours rather than the palette
itself: mocha's base comes out #131317 instead of #1e1e2e, `green` is #c8e3ff
(blue) and `red` is #c1a5fd (purple). Everything collapses onto one lavender
hue, which is why it does not read as Catppuccin.

This emits a `catppuccin-true` scheme instead, using the official palettes from
https://github.com/catppuccin/catppuccin verbatim for the 14 accents plus the
base/surface/overlay/text ramps, and deriving the Material 3 roles caelestia
needs (containers, fixed variants, `on*` pairs) by mixing those palette colours.
No new hues are invented -- every output colour is either a palette colour or a
mix of two of them.

Usage:  ./generate.py [OUTDIR]      (default OUTDIR: ./catppuccin-true)
"""

from __future__ import annotations

import sys
from pathlib import Path

# --- Official Catppuccin palettes -------------------------------------------
# Source: catppuccin/catppuccin palette.json (v1.7.1). Kept as plain hex so the
# generated files can be diffed against upstream by eye.

FLAVOURS: dict[str, dict[str, str]] = {
    "latte": {
        "rosewater": "dc8a78", "flamingo": "dd7878", "pink": "ea76cb",
        "mauve": "8839ef", "red": "d20f39", "maroon": "e64553",
        "peach": "fe640b", "yellow": "df8e1d", "green": "40a02b",
        "teal": "179299", "sky": "04a5e5", "sapphire": "209fb5",
        "blue": "1e66f5", "lavender": "7287fd",
        "text": "4c4f69", "subtext1": "5c5f77", "subtext0": "6c6f85",
        "overlay2": "7c7f93", "overlay1": "8c8fa1", "overlay0": "9ca0b0",
        "surface2": "acb0be", "surface1": "bcc0cc", "surface0": "ccd0da",
        "base": "eff1f5", "mantle": "e6e9ef", "crust": "dce0e8",
    },
    "frappe": {
        "rosewater": "f2d5cf", "flamingo": "eebebe", "pink": "f4b8e4",
        "mauve": "ca9ee6", "red": "e78284", "maroon": "ea999c",
        "peach": "ef9f76", "yellow": "e5c890", "green": "a6d189",
        "teal": "81c8be", "sky": "99d1db", "sapphire": "85c1dc",
        "blue": "8caaee", "lavender": "babbf1",
        "text": "c6d0f5", "subtext1": "b5bfe2", "subtext0": "a5adce",
        "overlay2": "949cbb", "overlay1": "838ba7", "overlay0": "737994",
        "surface2": "626880", "surface1": "51576d", "surface0": "414559",
        "base": "303446", "mantle": "292c3c", "crust": "232634",
    },
    "macchiato": {
        "rosewater": "f4dbd6", "flamingo": "f0c6c6", "pink": "f5bde6",
        "mauve": "c6a0f6", "red": "ed8796", "maroon": "ee99a0",
        "peach": "f5a97f", "yellow": "eed49f", "green": "a6da95",
        "teal": "8bd5ca", "sky": "91d7e3", "sapphire": "7dc4e4",
        "blue": "8aadf4", "lavender": "b7bdf8",
        "text": "cad3f5", "subtext1": "b8c0e0", "subtext0": "a5adcb",
        "overlay2": "939ab7", "overlay1": "8087a2", "overlay0": "6e738d",
        "surface2": "5b6078", "surface1": "494d64", "surface0": "363a4f",
        "base": "24273a", "mantle": "1e2030", "crust": "181926",
    },
    "mocha": {
        "rosewater": "f5e0dc", "flamingo": "f2cdcd", "pink": "f5c2e7",
        "mauve": "cba6f7", "red": "f38ba8", "maroon": "eba0ac",
        "peach": "fab387", "yellow": "f9e2af", "green": "a6e3a1",
        "teal": "94e2d5", "sky": "89dceb", "sapphire": "74c7ec",
        "blue": "89b4fa", "lavender": "b4befe",
        "text": "cdd6f4", "subtext1": "bac2de", "subtext0": "a6adc8",
        "overlay2": "9399b2", "overlay1": "7f849c", "overlay0": "6c7086",
        "surface2": "585b70", "surface1": "45475a", "surface0": "313244",
        "base": "1e1e2e", "mantle": "181825", "crust": "11111b",
    },
}

# Latte is the only light flavour; the rest are dark.
MODES = {"latte": "light", "frappe": "dark", "macchiato": "dark", "mocha": "dark"}


# --- Colour helpers ----------------------------------------------------------


def _rgb(c: str) -> tuple[int, int, int]:
    return int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)


def _hex(rgb: tuple[float, float, float]) -> str:
    return "".join(f"{max(0, min(255, round(v))):02x}" for v in rgb)


def mix(a: str, b: str, t: float) -> str:
    """Blend `a` toward `b` by `t` (0 = all a, 1 = all b), in sRGB."""
    ra, ga, ba = _rgb(a)
    rb, gb, bb = _rgb(b)
    return _hex((ra + (rb - ra) * t, ga + (gb - ga) * t, ba + (bb - ba) * t))


def luminance(c: str) -> float:
    """WCAG relative luminance."""

    def chan(v: int) -> float:
        s = v / 255
        return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4

    r, g, b = _rgb(c)
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast(a: str, b: str) -> float:
    """WCAG contrast ratio between two colours (1.0 - 21.0)."""
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def build(flavour: str) -> dict[str, str]:
    p = FLAVOURS[flavour]
    dark = MODES[flavour] == "dark"

    def ink_for(accent: str) -> str:
        # Foreground drawn directly on a saturated accent. In the dark flavours
        # the accents are all light, so `crust` always wins. Latte's accents sit
        # mid-tone -- white-ish text fails on pink and green there -- so pick
        # whichever end of the accent's own ramp separates further.
        light, shade = p["base"], mix(accent, "000000", 0.70)
        return light if contrast(light, accent) >= contrast(shade, accent) else shade

    def container(accent: str) -> str:
        # A filled surface that still reads as the accent's hue -- roughly M3
        # tone 30 in the dark flavours, tone 90 in latte.
        return mix(accent, p["base"], 0.72 if dark else 0.68)

    def on_container(accent: str) -> str:
        # Foreground for the matching container(). Dark flavours need a lighter
        # accent, latte a darker one. These ratios were picked so that every
        # on*/container pair clears WCAG AA in all four flavours.
        return mix(accent, "ffffff", 0.40) if dark else mix(accent, "000000", 0.45)

    def fixed(accent: str) -> str:
        # M3 "fixed" roles keep one tone across light and dark: always the light
        # end of the accent ramp.
        return mix(accent, "ffffff", 0.55) if dark else mix(accent, "ffffff", 0.60)

    def fixed_dim(accent: str) -> str:
        return mix(accent, "ffffff", 0.20) if dark else mix(accent, "ffffff", 0.30)

    def on_fixed(accent: str) -> str:
        return mix(accent, "000000", 0.72)

    def on_fixed_variant(accent: str) -> str:
        return mix(accent, "000000", 0.45)

    primary = p["mauve"]
    secondary = p["lavender"]
    tertiary = p["pink"]
    error = p["red"]
    success = p["green"]

    c: dict[str, str] = {}

    # Material's palette key colours: the hue anchors the tonal ramps come from.
    c["primary_paletteKeyColor"] = mix(primary, p["base"], 0.30)
    c["secondary_paletteKeyColor"] = mix(secondary, p["base"], 0.30)
    c["tertiary_paletteKeyColor"] = mix(tertiary, p["base"], 0.30)
    c["neutral_paletteKeyColor"] = p["overlay0"]
    c["neutral_variant_paletteKeyColor"] = p["overlay1"]

    # Surfaces: mapped straight onto Catppuccin's own base/surface ramp, which
    # is what makes the result actually look like Catppuccin.
    c["background"] = p["base"]
    c["onBackground"] = p["text"]
    c["surface"] = p["base"]
    c["surfaceDim"] = p["mantle"] if dark else p["crust"]
    c["surfaceBright"] = p["surface1"] if dark else p["base"]
    c["surfaceContainerLowest"] = p["crust"]
    c["surfaceContainerLow"] = p["mantle"]
    c["surfaceContainer"] = p["surface0"]
    c["surfaceContainerHigh"] = p["surface1"]
    c["surfaceContainerHighest"] = p["surface2"]
    c["onSurface"] = p["text"]
    c["surfaceVariant"] = p["surface1"]
    c["onSurfaceVariant"] = p["subtext0"]
    c["inverseSurface"] = p["text"]
    c["inverseOnSurface"] = p["base"]
    # The overlay/surface ramps run light-to-dark in latte and dark-to-light in
    # the dark flavours, so the outline takes the opposite end per mode to hold
    # roughly 3:1 against the surface.
    c["outline"] = p["overlay1"] if dark else p["overlay2"]
    c["outlineVariant"] = p["surface1"] if dark else p["surface2"]
    c["shadow"] = "000000"
    c["scrim"] = "000000"
    c["surfaceTint"] = primary

    for role, accent in (
        ("primary", primary),
        ("secondary", secondary),
        ("tertiary", tertiary),
        ("error", error),
    ):
        cap = role.capitalize()
        c[role] = accent
        c[f"on{cap}"] = ink_for(accent)
        c[f"{role}Container"] = container(accent)
        c[f"on{cap}Container"] = on_container(accent)

    c["inversePrimary"] = mix(primary, p["crust"], 0.45)

    for role, accent in (
        ("primary", primary),
        ("secondary", secondary),
        ("tertiary", tertiary),
    ):
        cap = role.capitalize()
        c[f"{role}Fixed"] = fixed(accent)
        c[f"{role}FixedDim"] = fixed_dim(accent)
        c[f"on{cap}Fixed"] = on_fixed(accent)
        c[f"on{cap}FixedVariant"] = on_fixed_variant(accent)

    # Terminal palette, per Catppuccin's published terminal mapping.
    term = [
        p["surface1"], p["red"], p["green"], p["yellow"],
        p["blue"], p["pink"], p["teal"], p["subtext1"],
        p["surface2"], p["red"], p["green"], p["yellow"],
        p["blue"], p["pink"], p["teal"], p["subtext0"],
    ]
    for i, colour in enumerate(term):
        c[f"term{i}"] = colour

    # The 14 accents, verbatim -- these are what templates and the terminal read.
    for name in (
        "rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
        "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender",
    ):
        c[name] = p[name]

    # KDE/Qt semantic colours.
    c["klink"] = p["blue"]
    c["klinkSelection"] = p["blue"]
    c["kvisited"] = p["mauve"]
    c["kvisitedSelection"] = p["mauve"]
    c["knegative"] = p["red"]
    c["knegativeSelection"] = p["red"]
    c["kneutral"] = p["yellow"]
    c["kneutralSelection"] = p["yellow"]
    c["kpositive"] = p["green"]
    c["kpositiveSelection"] = p["green"]

    # Catppuccin's own named ramp, passed through untouched.
    for name in (
        "text", "subtext1", "subtext0", "overlay2", "overlay1", "overlay0",
        "surface2", "surface1", "surface0", "base", "mantle", "crust",
    ):
        c[name] = p[name]

    # caelestia extends M3 with a success role.
    c["success"] = success
    c["onSuccess"] = ink_for(success)
    c["successContainer"] = container(success)
    c["onSuccessContainer"] = on_container(success)

    return c


# Key order and count must match what caelestia-cli's bundled schemes provide,
# so nothing downstream reads a missing colour.
EXPECTED_KEYS = 110

# Foreground/background pairs the shell actually paints on top of each other.
# Every one must stay legible, in every flavour -- this is what stops a tweak to
# the blend ratios from quietly producing grey-on-grey somewhere.
CONTRAST_PAIRS = [
    ("onSurface", "surface"),
    ("onSurfaceVariant", "surface"),
    ("onBackground", "background"),
    ("onPrimary", "primary"),
    ("onSecondary", "secondary"),
    ("onTertiary", "tertiary"),
    ("onError", "error"),
    ("onSuccess", "success"),
    ("onPrimaryContainer", "primaryContainer"),
    ("onSecondaryContainer", "secondaryContainer"),
    ("onTertiaryContainer", "tertiaryContainer"),
    ("onErrorContainer", "errorContainer"),
    ("onSuccessContainer", "successContainer"),
    ("onPrimaryFixed", "primaryFixed"),
    ("onSecondaryFixed", "secondaryFixed"),
    ("onTertiaryFixed", "tertiaryFixed"),
    ("outline", "surface"),
]

MIN_CONTRAST = 3.0


def check(flavour: str, colours: dict[str, str]) -> list[str]:
    """Return a list of problems with a generated flavour (empty means good)."""
    problems = []

    if len(colours) != EXPECTED_KEYS:
        problems.append(f"produced {len(colours)} keys, expected {EXPECTED_KEYS}")

    for fg, bg in CONTRAST_PAIRS:
        ratio = contrast(colours[fg], colours[bg])
        if ratio < MIN_CONTRAST:
            problems.append(f"{fg} on {bg} is only {ratio:.2f}:1 (want >= {MIN_CONTRAST})")

    return problems


def main() -> int:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent / "catppuccin-true")
    failed = False

    for flavour in FLAVOURS:
        colours = build(flavour)

        problems = check(flavour, colours)
        if problems:
            failed = True
            for problem in problems:
                print(f"error: {flavour}: {problem}", file=sys.stderr)
            continue

        worst = min(contrast(colours[fg], colours[bg]) for fg, bg in CONTRAST_PAIRS)
        path = out / flavour / f"{MODES[flavour]}.txt"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(f"{k} {v}\n" for k, v in colours.items()))
        print(f"wrote {path}  ({len(colours)} colours, worst contrast {worst:.2f}:1)")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
