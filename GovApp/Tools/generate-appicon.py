#!/usr/bin/env python3
"""Render the ayiti.io app icon from the same geometry as AyitiMark.swift.

The coordinates below are the single source of truth shared with
GovApp/DesignSystem/AyitiMark.swift and the skill's DESIGN.md. Change them in
all three or not at all.

    python3 Tools/generate-appicon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

GRID = 1024
SUPERSAMPLE = 4

BLUE = (30, 86, 200, 255)      # #1E56C8
RED = (230, 57, 70, 255)       # #E63946
WHITE = (255, 255, 255, 255)

BLUE_QUAD = [(435, 195), (555, 195), (660, 355), (190, 805)]
RED_POLY = [(678, 408), (448, 652), (562, 656), (648, 805), (838, 805)]
KNOCKOUT_CENTER = (716, 735)
KNOCKOUT_RADIUS = 62

OUTPUT = Path(__file__).resolve().parent.parent / (
    "GovApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
)


def render(size: int) -> Image.Image:
    canvas = size * SUPERSAMPLE
    scale = canvas / GRID
    image = Image.new("RGBA", (canvas, canvas), WHITE)
    draw = ImageDraw.Draw(image)

    def scaled(points):
        return [(x * scale, y * scale) for x, y in points]

    draw.polygon(scaled(BLUE_QUAD), fill=BLUE)
    draw.polygon(scaled(RED_POLY), fill=RED)

    cx, cy = KNOCKOUT_CENTER
    r = KNOCKOUT_RADIUS
    draw.ellipse(scaled([(cx - r, cy - r), (cx + r, cy + r)]), fill=WHITE)

    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    render(1024).convert("RGB").save(OUTPUT, "PNG", optimize=True)
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
