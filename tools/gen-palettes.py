#!/usr/bin/env python3
"""Generate lumen's colour palettes from the oklch values of the UI demo.

Development tool only: the generated files in share/palettes/ are committed,
so Python is never needed on a user's machine. Re-run after changing a value:

    python3 tools/gen-palettes.py
"""
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "share" / "palettes"

# The accents of Pane (same design), in its order.
HUES = {"blue": 262, "violet": 295, "teal": 190, "green": 150, "orange": 55, "pink": 355,
        "red": 25, "amber": 85, "lime": 125, "cyan": 215, "sky": 240, "indigo": 278, "fuchsia": 325}
# Light mode: warm and cool accents are darker to stay readable on white (as in Pane).
LIGHT_ACCENT = {"amber": (.535, .12), "lime": (.52, .16), "green": (.515, .12),
                "teal": (.505, .12), "cyan": (.51, .12), "sky": (.53, .12)}
MODES = ("light", "dark", "black")

# (L, C) pairs straight from UI_elements.html; hue comes from the accent.
UI = {
    "light": dict(bg=(.965, .014), panel=(.995, .004), ink=(.22, .03), muted=(.5, .04),
                  line=(.88, .02), accent=(.55, .2), field=(.975, .01), on_accent=None,
                  deep=(.84, .02)),
    "dark": dict(bg=(.17, .035), panel=(.22, .04), ink=(.95, .01), muted=(.72, .04),
                 line=(.32, .05), accent=(.72, .16), field=(.19, .035), on_accent=(.18, .04),
                 deep=(.12, .03)),
}
# Black (OLED): the dark palette on a pure black background, as in Pane.
UI["black"] = dict(UI["dark"], panel=(.13, .012), line=(.36, .04), field=(.10, .01), deep=(.06, .01))

MONO = {
    "light": dict(bg=.965, panel=1, ink=.2, muted=.5, line=.87, accent=.25, field=.975,
                  on_accent=None, deep=.84),
    "dark": dict(bg=.16, panel=.21, ink=.95, muted=.72, line=.32, accent=.92, field=.18,
                 on_accent=.15, deep=.11),
}
MONO["black"] = dict(MONO["dark"], panel=.13, line=.34, field=.10, deep=.06)

# Status colours (danger and success come from the demo).
STATUS = {
    "light": dict(danger=(.58, .21, 25), success=(.55, .15, 150), warning=(.68, .16, 75)),
    "dark": dict(danger=(.68, .19, 25), success=(.72, .15, 150), warning=(.80, .14, 80)),
}
STATUS["black"] = STATUS["dark"]
# Terminal ANSI hues: red, green, yellow, blue, magenta, cyan.
ANSI_HUES = [25, 145, 90, 255, 330, 200]


def oklch_to_rgb(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def in_gamut(rgb):
    return all(-1e-4 <= c <= 1 + 1e-4 for c in rgb)


def hexc(L, C, h):
    """oklch -> #rrggbb, reducing chroma until it fits sRGB (as browsers do)."""
    rgb = oklch_to_rgb(L, C, h)
    if not in_gamut(rgb):
        lo, hi = 0.0, C
        for _ in range(30):
            mid = (lo + hi) / 2
            if in_gamut(oklch_to_rgb(L, mid, h)):
                lo = mid
            else:
                hi = mid
        rgb = oklch_to_rgb(L, lo, h)

    def enc(x):
        x = min(1.0, max(0.0, x))
        x = 12.92 * x if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055
        return round(x * 255)

    return "#%02x%02x%02x" % tuple(enc(c) for c in rgb)


def ansi(mode, hue, chroma_scale=1.0):
    if mode != "light":
        normal, bright = (.70, .14), (.80, .12)
        neutrals = [(.30, .03), (.85, .02), (.45, .03), (.97, .01)]  # 0, 7, 8, 15
    else:
        normal, bright = (.50, .16), (.58, .16)
        neutrals = [(.22, .03), (.80, .02), (.48, .03), (.92, .01)]
    c = [None] * 16
    for i, ah in enumerate(ANSI_HUES):
        c[1 + i] = hexc(normal[0], normal[1], ah)
        c[9 + i] = hexc(bright[0], bright[1], ah)
    for idx, (L, C) in zip((0, 7, 8, 15), neutrals):
        c[idx] = hexc(L, C * chroma_scale, hue)
    return c


def build(accent, mode):
    if accent == "mono":
        h = 0
        p = {k: (hexc(v, 0, 0) if v is not None else "#ffffff") for k, v in MONO[mode].items()}
        scale = 0.0
    else:
        h = HUES[accent]
        ui = dict(UI[mode])
        if mode == "light" and accent in LIGHT_ACCENT:
            ui["accent"] = LIGHT_ACCENT[accent]
        p = {k: (hexc(v[0], v[1], h) if v is not None else "#ffffff") for k, v in ui.items()}
        scale = 1.0
    for k, (L, C, sh) in STATUS[mode].items():
        p[k] = hexc(L, C, sh)
    if mode == "black":
        p["bg"] = "#000000"
    for i, col in enumerate(ansi(mode, h, scale)):
        p[f"color{i}"] = col
    return p


ORDER = ["bg", "panel", "field", "deep", "ink", "muted", "line", "accent", "on_accent",
         "danger", "success", "warning"] + [f"color{i}" for i in range(16)]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for accent in list(HUES) + ["mono"]:
        for mode in MODES:
            p = build(accent, mode)
            lines = [f"# lumen palette: {accent} / {mode} (generated by tools/gen-palettes.py)"]
            lines += [f"{k}={p[k]}" for k in ORDER]
            (OUT / f"{accent}-{mode}.conf").write_text("\n".join(lines) + "\n")
    print(f"wrote {(len(HUES) + 1) * len(MODES)} palettes to {OUT}")


if __name__ == "__main__":
    main()
