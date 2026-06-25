from __future__ import annotations

import colorsys
import math
from pathlib import Path

from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[4]
DART_DIR = PROJECT_ROOT / "source" / "textures" / "dart_syringe"
ITEMS_DIR = DART_DIR / "items"

POISON_COLORS: dict[str, tuple[int, int, int]] = {
    "cyanide": (0, 190, 180),
    "sufforin": (35, 120, 190),
    "morbusine": (45, 150, 85),
    "deliriumine": (145, 95, 45),
    "paralyzant": (45, 115, 165),
    "radiotoxin": (185, 125, 5),
    "huskeggs": (115, 115, 115),
    "sulphuricacidsyringe": (190, 45, 40),
    "raptorbaneextract": (190, 15, 90),
    "europabrew": (65, 55, 70),
    "chloralhydrate": (140, 155, 45),
}

CHAMBER_COLORS: dict[str, tuple[int, int, int]] = {
    "cyanide": (127, 222, 216),
    "sufforin": (111, 169, 216),
    "morbusine": (131, 196, 147),
    "deliriumine": (196, 154, 98),
    "paralyzant": (124, 169, 201),
    "radiotoxin": (214, 178, 58),
    "huskeggs": (168, 173, 176),
    "sulphuricacidsyringe": (216, 120, 88),
    "raptorbaneextract": (214, 90, 149),
    "europabrew": (139, 120, 148),
    "chloralhydrate": (185, 196, 93),
}

PARALYZANT_BAND_COLOR = (210, 170, 55)
PARALYZANT_FEATHER_COLORS = [
    (55, 145, 210),
    (210, 170, 55),
    (55, 145, 210),
    (210, 170, 55),
    (55, 145, 210),
]


def is_red_accent(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return a > 0 and r > 75 and r > g * 1.25 and r > b * 1.15 and r - max(g, b) > 18


def is_blue_chamber(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    return a > 0 and b > 70 and b > r * 1.12 and b > g * 0.82 and b - r > 18


def recolor_hue(
    image: Image.Image,
    target: tuple[int, int, int],
    predicate,
    source_value: float,
    saturation_bias: float,
) -> Image.Image:
    image = image.convert("RGBA")
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    target_h, target_s, target_v = colorsys.rgb_to_hsv(*(channel / 255 for channel in target))

    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if not predicate((r, g, b, a)):
                out.putpixel((x, y), (r, g, b, a))
                continue

            _, source_s, source_v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            new_s = max(0.05, min(1.0, target_s * (saturation_bias + source_s * 0.45)))
            new_v = max(0.05, min(1.0, source_v * target_v / source_value))
            nr, ng, nb = colorsys.hsv_to_rgb(target_h, new_s, new_v)
            out.putpixel((x, y), (round(nr * 255), round(ng * 255), round(nb * 255), a))

    return out


def recolor_dart(
    image: Image.Image,
    accent_color: tuple[int, int, int],
    chamber_color: tuple[int, int, int],
) -> Image.Image:
    out = recolor_hue(image, accent_color, is_red_accent, source_value=0.82, saturation_bias=0.65)
    return recolor_hue(out, chamber_color, is_blue_chamber, source_value=0.72, saturation_bias=0.42)


def red_components(image: Image.Image) -> list[list[tuple[int, int]]]:
    image = image.convert("RGBA")
    red_pixels = {
        (x, y)
        for y in range(image.height)
        for x in range(image.width)
        if is_red_accent(image.getpixel((x, y)))
    }
    components: list[list[tuple[int, int]]] = []
    while red_pixels:
        start = red_pixels.pop()
        stack = [start]
        component = [start]
        while stack:
            x, y = stack.pop()
            for nx in (x - 1, x, x + 1):
                for ny in (y - 1, y, y + 1):
                    if (nx, ny) in red_pixels:
                        red_pixels.remove((nx, ny))
                        stack.append((nx, ny))
                        component.append((nx, ny))
        components.append(component)
    return sorted(components, key=len, reverse=True)


def recolor_paralyzant(image: Image.Image) -> Image.Image:
    image = recolor_hue(
        image,
        CHAMBER_COLORS["paralyzant"],
        is_blue_chamber,
        source_value=0.72,
        saturation_bias=0.42,
    )
    out = image.copy()
    components = red_components(image)
    if not components:
        return out

    tail_component = components[0]
    tail_set = set(tail_component)
    xs = [x for x, _ in tail_component]
    ys = [y for _, y in tail_component]
    min_x = min(xs)
    max_x = max(xs)
    min_y = min(ys)
    max_y = max(ys)
    span = max(1, max_x - min_x + 1)
    vertical_tail = max_y - min_y > span * 1.4
    feather_positions: dict[tuple[int, int], float] = {}

    if vertical_tail:
        for x, y in tail_component:
            feather_positions[(x, y)] = (x - min_x) / span
    else:
        base_x = min_x + span * 0.08
        base_y = max_y - (max_y - min_y) * 0.08
        angles = []
        for x, y in tail_component:
            angle = math.atan2(base_y - y, x - base_x)
            angles.append(angle)
            feather_positions[(x, y)] = angle
        min_angle = min(angles)
        angle_span = max(0.001, max(angles) - min_angle)
        for position, angle in list(feather_positions.items()):
            feather_positions[position] = (angle - min_angle) / angle_span

    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if not is_red_accent(pixel):
                continue
            if (x, y) in tail_set:
                feather_position = feather_positions[(x, y)]
                palette_index = min(len(PARALYZANT_FEATHER_COLORS) - 1, max(0, int(feather_position * len(PARALYZANT_FEATHER_COLORS))))
                target = PARALYZANT_FEATHER_COLORS[palette_index]
            else:
                target = PARALYZANT_BAND_COLOR

            single = Image.new("RGBA", (1, 1), pixel)
            recolored = recolor_hue(
                single,
                target,
                lambda p: True,
                source_value=0.82,
                saturation_bias=0.65,
            )
            out.putpixel((x, y), recolored.getpixel((0, 0)))

    return out


def build_preview(identifiers: list[str]) -> None:
    icons = [Image.open(ITEMS_DIR / ident / "icon.png").convert("RGBA") for ident in identifiers]
    sprites = [Image.open(ITEMS_DIR / ident / "sprite.png").convert("RGBA") for ident in identifiers]
    cell_w = 84
    cell_h = 150
    sheet = Image.new("RGBA", (cell_w * len(identifiers), cell_h), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)

    for index, ident in enumerate(identifiers):
        x = index * cell_w
        icon = icons[index]
        sprite = sprites[index]
        sheet.alpha_composite(icon.resize((64, 64), Image.Resampling.NEAREST), (x + 10, 0))
        sprite_preview = sprite.resize((sprite.width * 2, sprite.height * 2), Image.Resampling.NEAREST)
        sheet.alpha_composite(sprite_preview, (x + (cell_w - sprite_preview.width) // 2, 58))
        draw.text((x + 2, cell_h - 12), ident[:12], fill=(0, 0, 0, 255))

    sheet.save(DART_DIR / "poison_dart_preview.png")


def main() -> None:
    base_icon = Image.open(DART_DIR / "icon.png").convert("RGBA")
    base_sprite = Image.open(DART_DIR / "sprite.png").convert("RGBA")

    identifiers = list(POISON_COLORS)
    for ident, color in POISON_COLORS.items():
        item_dir = ITEMS_DIR / ident
        item_dir.mkdir(parents=True, exist_ok=True)
        chamber_color = CHAMBER_COLORS[ident]
        if ident == "paralyzant":
            recolor_paralyzant(base_icon).save(item_dir / "icon.png")
            recolor_paralyzant(base_sprite).save(item_dir / "sprite.png")
        else:
            recolor_dart(base_icon, color, chamber_color).save(item_dir / "icon.png")
            recolor_dart(base_sprite, color, chamber_color).save(item_dir / "sprite.png")

    build_preview(identifiers)
    print(f"Wrote {len(identifiers)} poison dart item folders under {ITEMS_DIR.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {(DART_DIR / 'poison_dart_preview.png').relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
