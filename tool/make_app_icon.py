#!/usr/bin/env python3
"""Render Ally's Journey Mark app-icon sources.

The mark itself is a Flutter CustomPainter (carbon_ui journey_mark.dart), which
means there is no artwork file anywhere to be the source of truth — and the app
icon previously drifted because pubspec still pointed flutter_launcher_icons at
a retired caduceus PNG. This script is that source of truth instead: it redraws
the painter's exact geometry so regenerating icons can never silently change
them.

Geometry mirrors _JourneyMarkPainter (radius 0.34, stroke 0.14, dot 0.06 of the
canvas) and Ally's own variant from lib/screens/start_up.dart — a 40 degree gap
centred at 3 o'clock, solid #00A7BE, centre dot held. Ally is the settled end of
the product story, so its ring is nearly closed.

    python3 tool/make_app_icon.py && dart run flutter_launcher_icons

Writes assets/icon/: the opaque icon, a transparent version iOS composites for
its Dark appearance, and a grayscale one it derives Tinted from.

One thing to check afterwards: flutter_launcher_icons 0.14.4 also writes junk
into ios/Runner.xcodeproj/project.pbxproj, substituting the icon name into two
settings that have nothing to do with icons —
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS (should stay YES)
and ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME (should stay AccentColor).
Revert that file after every run; only the image files are wanted.
"""

import math
import os

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersample factor; PIL has no antialiased drawing of its own

# _JourneyMarkPainter fractions.
RADIUS_FRAC = 0.34
STROKE_FRAC = 0.14
DOT_FRAC = 0.06

# Ally's variant.
GAP_CENTER_DEG = 90.0  # clockwise from 12 o'clock, so 3 o'clock
GAP_WIDTH_DEG = 40.0
MARK = (0x00, 0xA7, 0xBE)
GRAY = (0x77, 0x77, 0x77)
BACKGROUND = (0xF8, 0xF9, 0xFA)

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "icon")


def draw_mark(color, background, opaque=False):
    """Return a SIZE square with the mark drawn in `color`.

    `background` is an RGBA tuple; pass an alpha of 0 for the transparent
    variants iOS needs in order to composite the icon onto its own backing.

    `opaque` drops the alpha channel entirely. The App Store rejects a large
    app icon that merely *has* one, even fully opaque, so the main icon must be
    RGB while the Dark and Tinted variants keep their transparency.
    """
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), background)
    d = ImageDraw.Draw(img)

    cx = cy = s / 2
    radius = RADIUS_FRAC * s
    stroke = STROKE_FRAC * s
    half = stroke / 2

    # The painter measures the gap clockwise from 12; PIL's arc measures from 3
    # o'clock, clockwise, which is the same convention Flutter's drawArc uses
    # once you subtract the quarter turn.
    start = GAP_CENTER_DEG + GAP_WIDTH_DEG / 2 - 90
    end = start + (360 - GAP_WIDTH_DEG)

    fill = color + (255,)
    # PIL draws an arc's width inward from the bounding box, while the painter
    # centres the stroke on the radius — so the box is the radius plus half a
    # stroke, which puts the drawn band back where Flutter would put it.
    outer = radius + half
    d.arc(
        [cx - outer, cy - outer, cx + outer, cy + outer],
        start=start,
        end=end,
        fill=fill,
        width=int(round(stroke)),
    )

    # StrokeCap.round — PIL leaves the arc butt-ended, so cap it by hand.
    for deg in (start, end):
        px = cx + radius * math.cos(math.radians(deg))
        py = cy + radius * math.sin(math.radians(deg))
        d.ellipse([px - half, py - half, px + half, py + half], fill=fill)

    dot = DOT_FRAC * s
    d.ellipse([cx - dot, cy - dot, cx + dot, cy + dot], fill=fill)

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    return img.convert("RGB") if opaque else img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, color, background, opaque in (
        ("ally_icon.png", MARK, BACKGROUND + (255,), True),
        ("ally_icon_transparent.png", MARK, (0, 0, 0, 0), False),
        ("ally_icon_grayscale.png", GRAY, (0, 0, 0, 0), False),
    ):
        path = os.path.join(OUT_DIR, name)
        draw_mark(color, background, opaque).save(path)
        print("wrote", os.path.relpath(path, os.path.dirname(OUT_DIR)))


if __name__ == "__main__":
    main()
