#!/usr/bin/env python3
"""Turn ChromaLeon's wallpaper palette into a tinted8 scheme.

This is a faithful port of ChromaLeon's colour extraction (utils/colorUtils.js
and ui/wallpaperPage.js): the wallpaper is scaled to 64x64 by the caller and
fed here as raw 8-bit RGB on stdin. We reproduce the 24-wide channel
quantisation, HSL conversion, vibrancy ranking, contrast adjustment and
similarity dedupe, then map the resulting palette onto tinted8's eight
semantic slots.

The eight ANSI slots are not arbitrary: red/yellow/green/cyan/blue/magenta
carry meaning in a terminal theme, so instead of assigning the wallpaper
swatches in rank order we pick the extracted colour whose hue is closest to
each slot's reference hue. black/white are the luminance anchors.
"""

import argparse
import math
import sys

WIDTH = 64
HEIGHT = 64
STEP = 24

# Reference hues for the six chromatic tinted8 slots.
SLOTS = [
    ("red", 0),
    ("yellow", 60),
    ("green", 120),
    ("cyan", 180),
    ("blue", 240),
    ("magenta", 300),
]

# ChromaLeon's contrast anchors (relative luminance of its light/dark bgs).
LIGHT_BG_LUMINANCE = 0.957
DARK_BG_LUMINANCE = 0.037


def js_round(value):
    """JavaScript's Math.round (half away from zero, i.e. up for positives)."""
    return math.floor(value + 0.5)


def to_hex(channel):
    return f"{max(0, min(255, js_round(channel * 255))):02x}"


def rgb_to_hsl(r, g, b):
    r /= 255.0
    g /= 255.0
    b /= 255.0

    maximum = max(r, g, b)
    minimum = min(r, g, b)
    lightness = (maximum + minimum) / 2

    if maximum == minimum:
        return [0, 0, js_round(lightness * 100)]

    delta = maximum - minimum
    saturation = (
        delta / (2 - maximum - minimum)
        if lightness > 0.5
        else delta / (maximum + minimum)
    )

    if maximum == r:
        hue = (g - b) / delta + (6 if g < b else 0)
    elif maximum == g:
        hue = (b - r) / delta + 2
    else:
        hue = (r - g) / delta + 4

    return [
        js_round((hue / 6) * 360),
        js_round(saturation * 100),
        js_round(lightness * 100),
    ]


def hsl_to_rgb(hue, saturation, lightness):
    hue /= 360.0
    saturation /= 100.0
    lightness /= 100.0

    if saturation == 0:
        return (lightness, lightness, lightness)

    def hue_to_rgb(p, q, t):
        if t < 0:
            t += 1
        if t > 1:
            t -= 1
        if t < 1 / 6:
            return p + (q - p) * 6 * t
        if t < 1 / 2:
            return q
        if t < 2 / 3:
            return p + (q - p) * (2 / 3 - t) * 6
        return p

    q = (
        lightness * (1 + saturation)
        if lightness < 0.5
        else lightness + saturation - lightness * saturation
    )
    p = 2 * lightness - q

    return (
        hue_to_rgb(p, q, hue + 1 / 3),
        hue_to_rgb(p, q, hue),
        hue_to_rgb(p, q, hue - 1 / 3),
    )


def relative_luminance(r, g, b):
    def adjust(channel):
        if channel <= 0.04045:
            return channel / 12.92
        return ((channel + 0.055) / 1.055) ** 2.4

    return 0.2126 * adjust(r) + 0.7152 * adjust(g) + 0.0722 * adjust(b)


def contrast_ratio(lum1, lum2):
    brightest = max(lum1, lum2)
    darkest = min(lum1, lum2)
    return js_round(((brightest + 0.05) / (darkest + 0.05)) * 100) / 100


def adjust_contrast(color):
    """ChromaLeon's _adjustContrast, mutating hue/sat/light/hex in place."""
    r, g, b = hsl_to_rgb(color["h"], color["s"], color["l"])
    luminance = relative_luminance(r, g, b)
    lightness = color["l"]
    initial_lightness = lightness

    if contrast_ratio(luminance, LIGHT_BG_LUMINANCE) < 3:
        while contrast_ratio(luminance, LIGHT_BG_LUMINANCE) < 3 and lightness > 0:
            lightness -= 1
            rgb = hsl_to_rgb(color["h"], color["s"], lightness)
            luminance = relative_luminance(*rgb)
    elif contrast_ratio(luminance, DARK_BG_LUMINANCE) < 3:
        while contrast_ratio(luminance, DARK_BG_LUMINANCE) < 3 and lightness < 100:
            lightness += 1
            rgb = hsl_to_rgb(color["h"], color["s"], lightness)
            luminance = relative_luminance(*rgb)

    lightness_shift = abs(lightness - initial_lightness)
    is_deep_dark = initial_lightness < 15
    is_bright_light = initial_lightness > 85
    is_muted = 8 <= color["s"] < 35

    if is_deep_dark:
        color["s"] = js_round(color["s"] * (initial_lightness / 15.0))
    elif is_bright_light:
        color["s"] = js_round(color["s"] * ((100 - initial_lightness) / 15.0))
    elif lightness_shift > 10 and is_muted:
        boost = 1 + (lightness_shift / 50.0) * 0.4
        color["s"] = min(45, js_round(color["s"] * boost))

    color["l"] = lightness
    r, g, b = hsl_to_rgb(color["h"], color["s"], lightness)
    color["hex"] = "#" + to_hex(r) + to_hex(g) + to_hex(b)


def extract_colors(raw):
    """Port of _extractColorsFromPixbuf; returns up to 60 adjusted colours."""
    expected = WIDTH * HEIGHT * 3
    if len(raw) < expected:
        return []

    buckets = {}
    for offset in range(0, expected, 3):
        r = raw[offset]
        g = raw[offset + 1]
        b = raw[offset + 2]
        hue, saturation, lightness = rgb_to_hsl(r, g, b)

        qr = min(255, (r // STEP) * STEP + STEP // 2)
        qg = min(255, (g // STEP) * STEP + STEP // 2)
        qb = min(255, (b // STEP) * STEP + STEP // 2)
        key = f"#{qr:02x}{qg:02x}{qb:02x}"

        if key not in buckets:
            buckets[key] = {
                "hex": key,
                "count": 0,
                "h": hue,
                "s": saturation,
                "l": lightness,
            }
        buckets[key]["count"] += 1

    colors = list(buckets.values())

    def vibrancy(color):
        return (
            color["s"]
            * color["s"]
            * (1 - abs(color["l"] - 50) / 50)
            * math.log(color["count"] + 1)
        )

    vibrant_ranking = sorted(colors, key=vibrancy, reverse=True)

    final = []
    used = []

    def too_similar(color):
        for seen in used:
            hue_diff = abs(color["h"] - seen["h"])
            if hue_diff > 180:
                hue_diff = 360 - hue_diff
            sat_diff = abs(color["s"] - seen["s"])
            light_diff = abs(color["l"] - seen["l"])
            if hue_diff < 25 and sat_diff < 20 and light_diff < 20:
                return True
        return False

    def keep(color):
        adjust_contrast(color)
        if color["hex"] not in {item["hex"] for item in final} and not too_similar(
            color
        ):
            final.append(color)
            used.append(
                {"h": color["h"], "s": color["s"], "l": color["l"]}
            )

    for color in vibrant_ranking:
        keep(color)

    frequency_ranking = sorted(colors, key=lambda c: c["count"], reverse=True)
    for color in frequency_ranking:
        keep(color)

    return final[:60]


def hex_to_hsl(hex_color):
    value = hex_color.lstrip("#")
    if len(value) != 6:
        return rgb_to_hsl(0, 0, 0)
    return rgb_to_hsl(
        int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)
    )


def hue_distance(a, b):
    difference = abs(a - b) % 360
    return min(difference, 360 - difference)


def clamp(value, low, high):
    return max(low, min(high, value))


def make_hex(hue, saturation, lightness):
    r, g, b = hsl_to_rgb(hue, saturation, lightness)
    return "#" + to_hex(r) + to_hex(g) + to_hex(b)


def anchor(colors, accent_hsl, darkest):
    """Build a usable black/white anchor, tinted by the wallpaper extremes."""
    if colors:
        pick = min(colors, key=lambda c: c["l"])
        if not darkest:
            pick = max(colors, key=lambda c: c["l"])
        hue, saturation, lightness = pick["h"], pick["s"], pick["l"]
    else:
        hue, saturation, lightness = accent_hsl

    if darkest:
        lightness = min(lightness, 16)
        saturation = min(saturation, 28)
    else:
        lightness = max(lightness, 86)
        saturation = min(saturation, 16)

    return make_hex(hue, saturation, lightness)


def build_palette(colors, accent, variant):
    accent_hsl = hex_to_hsl(accent)

    black = anchor(colors, accent_hsl, darkest=True)
    white = anchor(colors, accent_hsl, darkest=False)

    anchors = {black, white}
    candidates = [color for color in colors if color["hex"] not in anchors]

    dark_variant = variant == "dark"
    palette = {"black": black, "white": white}
    used_hex = set(anchors)

    for name, reference_hue in SLOTS:
        best = None
        for color in candidates:
            # Chromatic slots need actual colour; greys have meaningless hues.
            if color["hex"] in used_hex or color["s"] < 12:
                continue
            distance = hue_distance(color["h"], reference_hue)
            chroma = color["s"] * (1 - abs(color["l"] - 50) / 50)
            score = distance - chroma * 0.05
            if best is None or score < best[0]:
                best = (score, color)

        if best is not None and hue_distance(best[1]["h"], reference_hue) <= 60:
            chosen = best[1]
            hue, saturation, lightness = (
                chosen["h"],
                chosen["s"],
                chosen["l"],
            )
            used_hex.add(chosen["hex"])
        else:
            # No wallpaper colour close enough: synthesise from the accent hue.
            hue = reference_hue
            saturation = clamp(accent_hsl[1], 30, 70)
            lightness = 60 if dark_variant else 45

        # Keep chromatic colours readable against the variant's background.
        if dark_variant:
            lightness = clamp(lightness, 45, 80)
        else:
            lightness = clamp(lightness, 30, 60)

        palette[name] = make_hex(hue, saturation, lightness)

    # Anchor the GNOME accent in the slot it is closest to so the terminal
    # matches the desktop exactly.
    accent_slot = min(SLOTS, key=lambda slot: hue_distance(accent_hsl[0], slot[1]))
    palette[accent_slot[0]] = accent

    return palette, accent_slot[0]


def emit_yaml(palette, accent, variant, accent_slot):
    order = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
    lines = [
        "scheme:",
        '  system: "tinted8"',
        "  supports:",
        '    styling-spec: "0.2.0"',
        '  author: "ChromaLeon (generated)"',
        '  name: "ChromaLeon"',
        '  slug: "chromaleon"',
        '  description: "Generated from the current ChromaLeon wallpaper palette"',
        f'variant: "{variant}"',
        "palette:",
    ]
    for name in order:
        lines.append(f'  {name}: "{palette[name]}"')
    lines += [
        "ui:",
        f'  accent.normal: "{accent}"',
        "",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--accent", default="#785ef0", help="ChromaLeon accent hex")
    parser.add_argument(
        "--variant", choices=("dark", "light"), default="dark", help="Scheme variant"
    )
    args = parser.parse_args()

    if not args.accent.startswith("#") or len(args.accent) != 7:
        args.accent = "#785ef0"

    raw = sys.stdin.buffer.read()
    if not raw:
        print(
            "chromaleon_palette: no wallpaper pixels, deriving from accent",
            file=sys.stderr,
        )

    colors = extract_colors(raw)
    if not colors:
        print(
            "chromaleon_palette: palette extraction empty, deriving from accent",
            file=sys.stderr,
        )

    palette, accent_slot = build_palette(colors, args.accent, args.variant)
    sys.stdout.write(emit_yaml(palette, args.accent, args.variant, accent_slot))


if __name__ == "__main__":
    main()
