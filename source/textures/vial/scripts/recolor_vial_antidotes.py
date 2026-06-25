from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[4]
VIAL_DIR = PROJECT_ROOT / "source" / "textures" / "vial"
ITEMS_DIR = VIAL_DIR / "items"
MASKS_DIR = VIAL_DIR / "masks"
SOURCE_CAP_METAL_MASK = MASKS_DIR / "mask_source_cap_metal.png"
SOURCE_CAP_RUBBER_MASK = MASKS_DIR / "mask_source_cap_rubber.png"
SOURCE_CAP_EDGE_MASK = MASKS_DIR / "mask_source_cap_edge.png"
SOURCE_LABEL_UPPER_MASK = MASKS_DIR / "mask_source_label_upper.png"
SOURCE_LABEL_LOWER_MASK = MASKS_DIR / "mask_source_label_lower.png"
ANTIDOTE_ICON_SOURCE_DIR = VIAL_DIR / "antidote_icon_sources"


ANTIDOTE_COLORS: dict[str, dict[str, tuple[int, int, int]]] = {
    "cyanideantidote": {
        "label": (0, 220, 205),
        "liquid": (120, 245, 230),
        "cap": (0, 205, 170),
    },
    "sufforinantidote": {
        "label": (30, 105, 225),
        "liquid": (120, 170, 245),
        "cap": (20, 85, 205),
    },
    "morbusineantidote": {
        "label": (45, 150, 80),
        "liquid": (130, 205, 150),
        "cap": (45, 150, 85),
    },
    "deliriumineantidote": {
        "label": (145, 95, 45),
        "liquid": (196, 154, 98),
        "cap": (145, 95, 45),
    },
    "antiparalysis": {
        "label": (0, 155, 215),
        "liquid": (125, 225, 245),
        "cap": (0, 120, 190),
        "rubber": (225, 180, 45),
    },
    "antirad": {
        "label": (185, 125, 5),
        "liquid": (214, 178, 58),
        "cap": (185, 125, 5),
    },
    "calyxanide": {
        "label": (115, 115, 115),
        "liquid": (168, 173, 176),
        "cap": (115, 115, 115),
    },
    "antinarc": {
        "label": (220, 55, 85),
        "liquid": (255, 170, 185),
        "cap": (190, 35, 65),
    },
    "antipsychosis": {
        "label": (155, 65, 235),
        "liquid": (215, 175, 255),
        "cap": (115, 45, 205),
    },
}


def manual_masks(size: tuple[int, int]) -> dict[str, Image.Image]:
    if size == (64, 64):
        return icon_masks(size)
    if size == (36, 82):
        return sprite_masks(size)
    raise ValueError(f"No manual vial masks for {size[0]}x{size[1]}")


def icon_masks(size: tuple[int, int]) -> dict[str, Image.Image]:
    source = Image.open(VIAL_DIR / "icon_source.png").convert("RGBA")
    if size != (64, 64):
        raise ValueError(f"No source-rendered vial icon masks for {size[0]}x{size[1]}")

    required_paths = {
        "cap_metal": SOURCE_CAP_METAL_MASK,
        "cap_rubber": SOURCE_CAP_RUBBER_MASK,
    }
    missing = [path.relative_to(PROJECT_ROOT) for path in required_paths.values() if not path.is_file()]
    if missing:
        joined = ", ".join(str(path) for path in missing)
        raise FileNotFoundError(f"Missing required vial masks: {joined}")

    masks = {
        name: render_mask_from_source(source, load_mask(path))
        for name, path in required_paths.items()
    }
    for name, path in optional_source_mask_paths().items():
        masks[name] = render_mask_from_source(source, load_mask(path))
    return masks


def sprite_masks(size: tuple[int, int]) -> dict[str, Image.Image]:
    metal = Image.new("L", size, 0)
    rubber = Image.new("L", size, 0)
    draw_metal = ImageDraw.Draw(metal)
    draw_rubber = ImageDraw.Draw(rubber)
    draw_metal.ellipse((5, 1, 31, 12), fill=255)
    draw_metal.rectangle((6, 6, 30, 14), fill=230)
    draw_rubber.ellipse((10, 3, 26, 9), fill=255)
    return {
        "cap_metal": metal,
        "cap_rubber": rubber,
    }


def colorize_with_mask(
    image: Image.Image,
    mask: Image.Image,
    target: tuple[int, int, int],
    amount: float,
    saturation_scale: float = 0.65,
) -> Image.Image:
    image = image.convert("RGBA")
    mask = Image.composite(mask, Image.new("L", image.size, 0), image.getchannel("A"))
    out = image.copy()
    target_h, target_s, target_v = colorsys.rgb_to_hsv(*(channel / 255 for channel in target))

    for y in range(image.height):
        for x in range(image.width):
            mask_alpha = mask.getpixel((x, y)) / 255
            if mask_alpha <= 0:
                continue

            r, g, b, a = image.getpixel((x, y))
            _, source_s, source_v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            blend = amount * mask_alpha
            new_s = min(1.0, max(0.02, target_s * saturation_scale + source_s * 0.28))
            new_v = min(1.0, max(0.03, source_v * (0.88 + target_v * 0.16)))
            cr, cg, cb = colorsys.hsv_to_rgb(target_h, new_s, new_v)
            nr = round(r * (1 - blend) + cr * 255 * blend)
            ng = round(g * (1 - blend) + cg * 255 * blend)
            nb = round(b * (1 - blend) + cb * 255 * blend)
            out.putpixel((x, y), (nr, ng, nb, a))

    return out


def recolor_vial(image: Image.Image, colors: dict[str, tuple[int, int, int]]) -> Image.Image:
    masks = manual_masks(image.size)
    out = colorize_with_mask(image, masks["cap_metal"], colors["cap"], amount=0.48, saturation_scale=0.45)
    return colorize_with_mask(out, masks["cap_rubber"], colors["label"], amount=0.92, saturation_scale=0.85)


def render_icon_from_source(source: Image.Image) -> Image.Image:
    source = source.convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", (64, 64), (0, 0, 0, 0))

    crop = source.crop(bbox)
    scale = min(60 / crop.width, 60 / crop.height)
    rendered_size = (round(crop.width * scale), round(crop.height * scale))
    crop = crop.resize(rendered_size, Image.Resampling.LANCZOS)

    icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    icon.alpha_composite(crop, ((64 - rendered_size[0]) // 2, (64 - rendered_size[1]) // 2))
    return icon


def render_mask_from_source(source: Image.Image, source_mask: Image.Image) -> Image.Image:
    source = source.convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("L", (64, 64), 0)

    crop = source_mask.crop(bbox)
    scale = min(60 / crop.width, 60 / crop.height)
    rendered_size = (round(crop.width * scale), round(crop.height * scale))
    crop = crop.resize(rendered_size, Image.Resampling.LANCZOS)

    icon_mask = Image.new("L", (64, 64), 0)
    icon_mask.paste(crop, ((64 - rendered_size[0]) // 2, (64 - rendered_size[1]) // 2))
    return icon_mask


def load_mask(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA").getchannel("A")


def recolor_icon_source(source: Image.Image, colors: dict[str, tuple[int, int, int]]) -> Image.Image:
    source_masks = {
        "cap_metal": load_mask(SOURCE_CAP_METAL_MASK),
        "cap_rubber": load_mask(SOURCE_CAP_RUBBER_MASK),
        **{name: load_mask(path) for name, path in optional_source_mask_paths().items()},
    }
    for name, mask in source_masks.items():
        if mask.size != source.size:
            raise ValueError(f"{name} source mask is {mask.size}, expected {source.size}")

    out = tint_liquid_without_mask(source, colors["liquid"])
    out = colorize_with_mask(out, source_masks["cap_metal"], colors["cap"], amount=0.58, saturation_scale=0.62)
    out = colorize_with_mask(out, source_masks["cap_rubber"], colors.get("rubber", colors["label"]), amount=0.98, saturation_scale=1.05)
    if "cap_edge" in source_masks:
        out = colorize_with_mask(out, source_masks["cap_edge"], colors["cap"], amount=0.90, saturation_scale=0.92)
    if "label_upper" in source_masks:
        out = colorize_with_mask(out, source_masks["label_upper"], colors["label"], amount=0.84, saturation_scale=0.78)
    if "label_lower" in source_masks:
        out = colorize_with_mask(out, source_masks["label_lower"], colors["label"], amount=0.84, saturation_scale=0.78)
    return out


def tint_liquid_without_mask(image: Image.Image, target: tuple[int, int, int]) -> Image.Image:
    image = image.convert("RGBA")
    out = image.copy()
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return out

    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top
    tr, tg, tb = lighten_color(target, 0.34)

    for y in range(top, bottom):
        rel_y = (y - top) / height
        for x in range(left, right):
            rel_x = (x - left) / width
            r, g, b, a = image.getpixel((x, y))
            if not is_liquid_candidate(r, g, b, a, rel_x, rel_y):
                continue

            _, source_s, source_v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            strength = 0.24
            if source_v < 0.28:
                strength = 0.34
            if source_s > 0.18:
                strength *= 0.9

            nr = round(r * (1 - strength) + tr * strength)
            ng = round(g * (1 - strength) + tg * strength)
            nb = round(b * (1 - strength) + tb * strength)
            out.putpixel((x, y), (nr, ng, nb, a))

    return out


def lighten_color(color: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(round(channel * (1 - amount) + 255 * amount) for channel in color)


def is_liquid_candidate(r: int, g: int, b: int, a: int, rel_x: float, rel_y: float) -> bool:
    if a == 0:
        return False

    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    paper_label = r > 105 and g > 85 and b > 65 and r > b * 1.08
    bright_highlight = v > 0.74 and s < 0.22
    cap_region = rel_y < 0.34 and rel_x > 0.48
    colored_label_stripe = g > r * 1.08 and g > b * 0.92 and 0.33 < rel_y < 0.76

    if paper_label or bright_highlight or cap_region or colored_label_stripe:
        return False

    in_glass_body = 0.10 <= rel_x <= 0.86 and 0.20 <= rel_y <= 0.95
    dark_or_neutral_glass = 0.08 <= v <= 0.55 and s <= 0.34 and b >= r * 0.78
    return in_glass_body and dark_or_neutral_glass


def optional_source_mask_paths() -> dict[str, Path]:
    candidates = {
        "cap_edge": SOURCE_CAP_EDGE_MASK,
        "label_upper": SOURCE_LABEL_UPPER_MASK,
        "label_lower": SOURCE_LABEL_LOWER_MASK,
    }
    return {name: path for name, path in candidates.items() if path.exists()}


def save_manual_mask_preview() -> None:
    icon = Image.open(VIAL_DIR / "icon.png").convert("RGBA")
    icon_source = Image.open(VIAL_DIR / "icon_source.png").convert("RGBA")
    sprite = Image.open(VIAL_DIR / "sprite.png").convert("RGBA")
    pieces = [(icon, manual_masks(icon.size)), (sprite, manual_masks(sprite.size))]
    sheet = Image.new("RGBA", (220, 100), (255, 255, 255, 255))

    x = 8
    for base, masks in pieces:
        preview = base.copy()
        overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
        for name, color in {
            "cap_metal": (255, 70, 70, 135),
            "cap_rubber": (60, 210, 255, 180),
            "cap_edge": (255, 220, 60, 180),
            "label_upper": (75, 255, 115, 160),
            "label_lower": (75, 255, 115, 160),
        }.items():
            if name not in masks:
                continue
            layer = Image.new("RGBA", base.size, color)
            layer.putalpha(masks[name])
            overlay.alpha_composite(layer)
        preview.alpha_composite(overlay)
        scale = 2 if base.width <= 40 else 1
        preview = preview.resize((base.width * scale, base.height * scale), Image.Resampling.NEAREST)
        sheet.alpha_composite(preview, (x, 8))
        x += preview.width + 22

    sheet.save(VIAL_DIR / "manual_recolor_masks_preview.png")

    save_mask_image(icon.size, manual_masks(icon.size), VIAL_DIR / "manual_recolor_mask_icon.png")
    save_mask_image(sprite.size, manual_masks(sprite.size), VIAL_DIR / "manual_recolor_mask_sprite.png")
    save_source_mask_preview(icon_source)


def save_source_mask_preview(icon_source: Image.Image) -> None:
    masks = {
        "cap_metal": load_mask(SOURCE_CAP_METAL_MASK),
        "cap_rubber": load_mask(SOURCE_CAP_RUBBER_MASK),
        **{name: load_mask(path) for name, path in optional_source_mask_paths().items()},
    }
    preview = icon_source.copy()
    overlay = Image.new("RGBA", icon_source.size, (0, 0, 0, 0))
    for name, color in {
        "cap_metal": (255, 70, 70, 120),
        "cap_rubber": (60, 210, 255, 165),
        "cap_edge": (255, 220, 60, 165),
        "label_upper": (75, 255, 115, 150),
        "label_lower": (75, 255, 115, 150),
    }.items():
        if name not in masks:
            continue
        layer = Image.new("RGBA", icon_source.size, color)
        layer.putalpha(masks[name])
        overlay.alpha_composite(layer)
    preview.alpha_composite(overlay)
    preview.save(VIAL_DIR / "manual_recolor_masks_source_preview.png")


def save_mask_image(size: tuple[int, int], masks: dict[str, Image.Image], path: Path) -> None:
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for name, color in {
        "cap_metal": (255, 70, 70),
        "cap_rubber": (60, 210, 255),
        "cap_edge": (255, 220, 60),
        "label_upper": (75, 255, 115),
        "label_lower": (75, 255, 115),
    }.items():
        if name not in masks:
            continue
        layer = Image.new("RGBA", size, (*color, 255))
        layer.putalpha(masks[name])
        out.alpha_composite(layer)
    out.save(path)


def build_preview(identifiers: list[str]) -> None:
    cell_w = 94
    cell_h = 180
    sheet = Image.new("RGBA", (cell_w * len(identifiers), cell_h), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)

    for index, ident in enumerate(identifiers):
        x = index * cell_w
        icon = Image.open(ITEMS_DIR / ident / "icon.png").convert("RGBA")
        sprite = Image.open(ITEMS_DIR / ident / "sprite.png").convert("RGBA")
        sheet.alpha_composite(icon.resize((64, 64), Image.Resampling.NEAREST), (x + 15, 0))
        sprite_preview = sprite.resize((sprite.width * 2, sprite.height * 2), Image.Resampling.NEAREST)
        sheet.alpha_composite(sprite_preview, (x + (cell_w - sprite_preview.width) // 2, 62))
        draw.text((x + 2, cell_h - 12), ident[:13], fill=(0, 0, 0, 255))

    sheet.save(VIAL_DIR / "antidote_vial_preview.png")


def main() -> None:
    base_icon_source = Image.open(VIAL_DIR / "icon_source.png").convert("RGBA")
    base_sprite = Image.open(VIAL_DIR / "sprite.png").convert("RGBA")

    save_manual_mask_preview()
    ANTIDOTE_ICON_SOURCE_DIR.mkdir(parents=True, exist_ok=True)

    identifiers = list(ANTIDOTE_COLORS)
    for ident, colors in ANTIDOTE_COLORS.items():
        item_dir = ITEMS_DIR / ident
        item_dir.mkdir(parents=True, exist_ok=True)
        icon_source = recolor_icon_source(base_icon_source, colors)
        icon_source.save(ANTIDOTE_ICON_SOURCE_DIR / f"{ident}.png")
        render_icon_from_source(icon_source).save(item_dir / "icon.png")
        recolor_vial(base_sprite, colors).save(item_dir / "sprite.png")

    build_preview(identifiers)
    print(f"Wrote {len(identifiers)} antidote vial item folders under {ITEMS_DIR.relative_to(PROJECT_ROOT)}")
    print(f"Wrote {(VIAL_DIR / 'antidote_vial_preview.png').relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
