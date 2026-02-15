#!/usr/bin/env python3
"""Generate macOS app icon (.icns) for Blue Screen of Death.

Creates a blue square (#0000AA) with white monospace "0x" text centered.
Produces an .icns file via iconutil from an .iconset directory.
"""

import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

# Icon sizes required for macOS .iconset
# Format: (filename, pixel_size)
ICON_SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

BG_COLOR = (0, 0, 170)  # #0000AA
TEXT_COLOR = (255, 255, 255)  # white


def find_monospace_font():
    """Find a suitable monospace font on macOS."""
    candidates = [
        "/System/Library/Fonts/SFMono-Bold.otf",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Monaco.dfont",
        "/Library/Fonts/Courier New Bold.ttf",
        "/System/Library/Fonts/Courier.dfont",
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return None


def render_icon(size, font_path):
    """Render a single icon at the given pixel size."""
    img = Image.new("RGBA", (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Scale font to ~45% of icon size for good visual balance
    font_size = max(int(size * 0.45), 8)
    try:
        font = ImageFont.truetype(font_path, font_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    text = "0x"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]

    x = (size - text_w) / 2 - bbox[0]
    y = (size - text_h) / 2 - bbox[1]

    draw.text((x, y), text, fill=TEXT_COLOR, font=font)
    return img


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    resources_dir = os.path.join(project_root, "Sources", "BlueScreenOfDeath", "Resources")
    iconset_dir = os.path.join(resources_dir, "AppIcon.iconset")
    icns_path = os.path.join(resources_dir, "AppIcon.icns")

    os.makedirs(iconset_dir, exist_ok=True)

    font_path = find_monospace_font()
    if not font_path:
        print("Warning: No monospace font found, using default", file=sys.stderr)

    for filename, size in ICON_SIZES:
        img = render_icon(size, font_path)
        out_path = os.path.join(iconset_dir, filename)
        img.save(out_path, "PNG")
        print(f"  Generated {filename} ({size}x{size})")

    # Use iconutil to create .icns
    print(f"  Creating {icns_path}")
    result = subprocess.run(
        ["iconutil", "-c", "icns", iconset_dir, "-o", icns_path],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"Error running iconutil: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print(f"  App icon created: {icns_path}")


if __name__ == "__main__":
    main()
