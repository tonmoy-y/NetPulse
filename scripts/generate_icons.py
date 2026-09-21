#!/usr/bin/env python3
"""Generates the NetPulse app icon (all macOS sizes) and the standalone
brand mark PNGs, drawing the same original "signal pulse" geometry used by
NetPulseMark.swift: a rounded square with a two-tone gradient and a
zig-zag pulse waveform stroke. No third-party artwork is used."""

import math
from PIL import Image, ImageDraw

PRIMARY = (24, 189, 187)      # #18BDBB approx of netPulsePrimary(light)/(dark) blend
SECONDARY = (95, 100, 235)    # #5F64EB approx of netPulseSecondary blend
WHITE = (255, 255, 255)

APP_ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]
BRAND_SIZES = [16, 20, 32, 64, 128, 256, 512, 1024]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_gradient_rounded_square(size, corner_ratio=0.225):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    corner = int(size * corner_ratio)

    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, size - 1, size - 1], radius=corner, fill=255)

    grad = Image.new("RGB", (size, size))
    gpx = grad.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            gpx[x, y] = lerp(PRIMARY, SECONDARY, t)

    img.paste(grad, (0, 0))
    img.putalpha(mask)
    return img


def draw_pulse_mark(img, size, color=WHITE, line_ratio=0.085):
    draw = ImageDraw.Draw(img)
    w = h = size
    mid_y = h * 0.55
    points = [
        (0, mid_y),
        (w * 0.22, mid_y),
        (w * 0.38, h * 0.18),
        (w * 0.54, h * 0.82),
        (w * 0.70, mid_y),
        (w, mid_y),
    ]
    line_width = max(2, int(size * line_ratio))
    draw.line(points, fill=color, width=line_width, joint="curve")
    r = line_width / 2
    for p in points:
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)
    return img


def build_app_icon(size, inset_ratio=0.68):
    base = draw_gradient_rounded_square(size)
    inset_size = int(size * inset_ratio)
    mark_canvas = Image.new("RGBA", (inset_size, inset_size), (0, 0, 0, 0))
    draw_pulse_mark(mark_canvas, inset_size)
    offset = ((size - inset_size) // 2, (size - inset_size) // 2)
    base.alpha_composite(mark_canvas, offset)
    return base


def build_standalone_mark(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_pulse_mark(img, size, color=PRIMARY, line_ratio=0.11)
    return img


def main(app_icon_dir, brand_dir):
    import os
    os.makedirs(app_icon_dir, exist_ok=True)
    os.makedirs(brand_dir, exist_ok=True)

    for size in APP_ICON_SIZES:
        icon = build_app_icon(size)
        icon.save(os.path.join(app_icon_dir, f"icon_{size}x{size}.png"))
        if size <= 512:
            icon2x = build_app_icon(size * 2)
            icon2x.save(os.path.join(app_icon_dir, f"icon_{size}x{size}@2x.png"))

    for size in BRAND_SIZES:
        mark = build_standalone_mark(size)
        mark.save(os.path.join(brand_dir, f"netpulse-mark-{size}.png"))

    print("Icons generated.")


if __name__ == "__main__":
    import sys
    app_icon_dir = sys.argv[1] if len(sys.argv) > 1 else "NetPulse/Resources/Assets.xcassets/AppIcon.appiconset"
    brand_dir = sys.argv[2] if len(sys.argv) > 2 else "Brand/Logo"
    main(app_icon_dir, brand_dir)
