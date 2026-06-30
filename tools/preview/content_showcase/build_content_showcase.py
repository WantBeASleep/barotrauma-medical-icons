from __future__ import annotations

from argparse import ArgumentParser
from dataclasses import dataclass
from pathlib import Path
import math
import sys


SCRIPT_DIR = Path(__file__).resolve().parent


def find_project_root() -> Path:
    for path in [SCRIPT_DIR, *SCRIPT_DIR.parents]:
        if (path / "filelist.xml").exists():
            return path
    raise FileNotFoundError("Could not find project root marker filelist.xml")


PROJECT_ROOT = find_project_root()
VENDOR_DIR = PROJECT_ROOT / "_vendor"
if VENDOR_DIR.exists():
    sys.path.insert(0, str(VENDOR_DIR))

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


SIZE = (1920, 1080)
FONT_DIR = PROJECT_ROOT / "source" / "fonts"
TEXTURES_DIR = PROJECT_ROOT / "source" / "texturepacks" / "default"
STATUS_ICON_DIR = PROJECT_ROOT / "tools" / "build" / "status_icons"
OUTPUT_DIR = PROJECT_ROOT / "preview"


@dataclass(frozen=True)
class Showcase:
    filename: str
    subtitle: str
    items: tuple[str, ...]
    use_status_icons: bool = True
    icon_scale: int = 172


SHOWCASES = [
    Showcase(
        "01_textures.png",
        "Textures",
        ("ampoule", "vial", "dart_syringe", "insulin_syringe", "pocket_injector"),
        use_status_icons=False,
        icon_scale=260,
    ),
    Showcase(
        "02_medicine.png",
        "Medicine",
        (
            "pomegrenadeextract",
            "antidama1",
            "antidama2",
            "deusizine",
            "liquidoxygenite",
        ),
        icon_scale=260,
    ),
    Showcase(
        "03_basic_chemicals.png",
        "Basic Chemicals",
        ("adrenaline", "antibiotics", "opium", "stabilozine"),
        icon_scale=280,
    ),
    Showcase(
        "04_toxins.png",
        "Toxins",
        (
            "cyanide",
            "sufforin",
            "morbusine",
            "deliriumine",
            "paralyzant",
            "radiotoxin",
            "chloralhydrate",
            "sulphuricacidsyringe",
            "raptorbaneextract",
            "europabrew",
            "huskeggs",
        ),
        icon_scale=190,
    ),
    Showcase(
        "05_antidotes.png",
        "Antidotes",
        (
            "cyanideantidote",
            "sufforinantidote",
            "morbusineantidote",
            "deliriumineantidote",
            "antiparalysis",
            "antirad",
            "calyxanide",
            "antinarc",
            "antipsychosis",
        ),
        icon_scale=210,
    ),
    Showcase(
        "06_stimulants.png",
        "Stimulants",
        ("meth", "steroids", "hyperzine", "combatstimulantsyringe", "pressurestabilizer"),
        icon_scale=260,
    ),
]


def parse_args():
    parser = ArgumentParser(description="Build 1920x1080 static content showcase PNGs for Medical Icons.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUTPUT_DIR,
        help="Directory for generated PNG files. Defaults to preview.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned output files without writing images.",
    )
    return parser.parse_args()


def load_font(name: str, size: int) -> ImageFont.ImageFont:
    path = FONT_DIR / name
    if path.exists():
        return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def fit_font(text: str, max_width: int, start_size: int) -> ImageFont.ImageFont:
    size = start_size
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    while size > 20:
        font = load_font("Bangers-Regular.ttf", size)
        box = probe.textbbox((0, 0), text, font=font, stroke_width=5)
        if box[2] - box[0] <= max_width:
            return font
        size -= 2
    return load_font("Bangers-Regular.ttf", size)


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    y: int,
    text: str,
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int],
    stroke: tuple[int, int, int] = (1, 5, 7),
    stroke_width: int = 5,
):
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke_width)
    x = (SIZE[0] - (box[2] - box[0])) / 2
    draw.text((x, y - box[1]), text, font=font, fill=fill, stroke_width=stroke_width, stroke_fill=stroke)


def draw_centered_text_shadow(
    draw: ImageDraw.ImageDraw,
    y: int,
    text: str,
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int],
    stroke: tuple[int, int, int],
    shadow: tuple[int, int, int],
    stroke_width: int = 6,
):
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke_width)
    x = (SIZE[0] - (box[2] - box[0])) / 2
    draw.text(
        (x + 7, y - box[1] + 7),
        text,
        font=font,
        fill=shadow,
        stroke_width=stroke_width,
        stroke_fill=(0, 0, 0),
    )
    draw.text((x, y - box[1]), text, font=font, fill=fill, stroke_width=stroke_width, stroke_fill=stroke)


def draw_sonar_background() -> Image.Image:
    width, height = SIZE
    bg = Image.new("RGBA", SIZE, (8, 18, 20, 255))
    draw = ImageDraw.Draw(bg)

    for y in range(height):
        blend = y / height
        r = int(8 * (1 - blend) + 0 * blend)
        g = int(18 * (1 - blend) + 132 * blend)
        b = int(20 * (1 - blend) + 138 * blend)
        draw.line((0, y, width, y), fill=(r, g, b, 255))

    for y in range(0, height, 28):
        alpha = 62 if y % 84 == 0 else 30
        draw.line((0, y, width, y), fill=(236, 255, 250, alpha), width=2 if y % 84 == 0 else 1)

    radar = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    radar_draw = ImageDraw.Draw(radar)
    center = (width // 2, 610)
    for radius in range(170, 1080, 145):
        alpha = max(52, 210 - radius // 8)
        radar_draw.ellipse(
            (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
            outline=(42, 230, 235, alpha),
            width=5,
        )
    for angle in range(0, 360, 20):
        radians = math.radians(angle)
        radar_draw.line(
            (center[0], center[1], center[0] + math.cos(radians) * 1180, center[1] + math.sin(radians) * 1180),
            fill=(42, 230, 235, 44),
            width=3,
        )
    shade = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    shade_draw.rectangle((0, 0, width, height), fill=(0, 0, 0, 8))
    shade_draw.rectangle((0, 0, width, 250), fill=(0, 0, 0, 62))
    shade_draw.rectangle((0, 910, width, height), fill=(0, 0, 0, 48))
    bg.alpha_composite(shade)
    bg.alpha_composite(radar)
    return bg


def icon_path(identifier: str, use_status_icons: bool) -> Path:
    if use_status_icons:
        return STATUS_ICON_DIR / f"{identifier}.png"
    return TEXTURES_DIR / identifier / "base" / "icon.png"


def load_icon(identifier: str, use_status_icons: bool) -> Image.Image:
    path = icon_path(identifier, use_status_icons)
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def icon_card(icon: Image.Image, size: int, accent: tuple[int, int, int]) -> Image.Image:
    card = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    inset = int(size * 0.05)
    radius = max(12, size // 14)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=(0, 0, 0, 118),
        outline=(*accent, 120),
        width=max(3, size // 56),
    )
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.rounded_rectangle((inset, inset, size - inset, size - inset), radius=radius, fill=(*accent, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(size // 14))
    card.alpha_composite(glow)
    card.alpha_composite(icon_box(icon, int(size * 0.72)), ((size - int(size * 0.72)) // 2, (size - int(size * 0.72)) // 2))
    return card


def icon_box(icon: Image.Image, max_size: int) -> Image.Image:
    fitted = ImageOps.contain(icon, (max_size, max_size), Image.Resampling.LANCZOS)
    box = Image.new("RGBA", (max_size, max_size), (0, 0, 0, 0))
    shadow = Image.new("RGBA", fitted.size, (0, 0, 0, 0))
    shadow.putalpha(fitted.getchannel("A").filter(ImageFilter.GaussianBlur(max(4, max_size // 22))))
    x = (max_size - fitted.width) // 2
    y = (max_size - fitted.height) // 2
    box.alpha_composite(shadow, (x + max_size // 24, y + max_size // 22))
    box.alpha_composite(fitted, (x, y))
    return box


def layout_positions(count: int, icon_size: int) -> list[tuple[int, int]]:
    if count <= 5:
        columns = count
    elif count <= 8:
        columns = 4
    elif count <= 10:
        columns = 5
    else:
        columns = 6
    rows = math.ceil(count / columns)
    gap_x = max(34, int(icon_size * 0.22))
    gap_y = max(30, int(icon_size * 0.18))
    total_w = columns * icon_size + (columns - 1) * gap_x
    total_h = rows * icon_size + (rows - 1) * gap_y
    start_x = (SIZE[0] - total_w) // 2
    start_y = 338 + (500 - total_h) // 2
    positions = []
    for index in range(count):
        row = index // columns
        col = index % columns
        row_count = columns if row < rows - 1 else count - row * columns
        row_w = row_count * icon_size + (row_count - 1) * gap_x
        row_x = (SIZE[0] - row_w) // 2
        positions.append((row_x + col * (icon_size + gap_x), start_y + row * (icon_size + gap_y)))
    return positions


def draw_showcase(showcase: Showcase) -> Image.Image:
    image = draw_sonar_background()
    draw = ImageDraw.Draw(image)
    accent = (42, 230, 235)
    accent2 = (255, 68, 150)

    title_font = fit_font("Medical Items", 1660, 132)
    subtitle_font = fit_font(showcase.subtitle, 1450, 92)
    draw_centered_text(draw, 42, "Medical Items", title_font, (242, 252, 253), stroke_width=7)
    draw_centered_text_shadow(
        draw,
        178,
        showcase.subtitle,
        subtitle_font,
        (255, 238, 196),
        stroke=(255, 68, 150),
        shadow=accent,
        stroke_width=7,
    )

    panel = (150, 285, 1770, 895)
    panel_fill = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    panel_fill_draw = ImageDraw.Draw(panel_fill)
    panel_fill_draw.rounded_rectangle(panel, radius=24, fill=(0, 0, 0, 42), outline=(*accent, 130), width=4)
    image.alpha_composite(panel_fill)
    panel_fx = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    panel_draw = ImageDraw.Draw(panel_fx)
    for y in range(panel[1] + 26, panel[3] - 20, 30):
        panel_draw.line((panel[0] + 30, y, panel[2] - 30, y), fill=(236, 255, 250, 42), width=2 if y % 90 == 0 else 1)
    panel_mask = Image.new("L", SIZE, 0)
    mask_draw = ImageDraw.Draw(panel_mask)
    mask_draw.rounded_rectangle(panel, radius=24, fill=255)
    image.alpha_composite(Image.composite(panel_fx, Image.new("RGBA", SIZE, (0, 0, 0, 0)), panel_mask))
    draw.rounded_rectangle(panel, radius=24, outline=(*accent, 130), width=4)
    draw.line((210, 895, 1710, 895), fill=(*accent2, 155), width=6)

    positions = layout_positions(len(showcase.items), showcase.icon_scale)
    for index, identifier in enumerate(showcase.items):
        icon = load_icon(identifier, showcase.use_status_icons)
        local_accent = accent if index % 2 == 0 else accent2
        card = icon_card(icon, showcase.icon_scale, local_accent)
        image.alpha_composite(card, positions[index])
        icon.close()

    return image.convert("RGB")


def validate_inputs():
    missing = []
    for showcase in SHOWCASES:
        for identifier in showcase.items:
            path = icon_path(identifier, showcase.use_status_icons)
            if not path.exists():
                missing.append(path)
    if missing:
        missing_text = "\n".join(f"- {path}" for path in missing)
        raise FileNotFoundError(f"Missing showcase source icons:\n{missing_text}")


def main():
    args = parse_args()
    validate_inputs()
    planned = [args.output_dir / showcase.filename for showcase in SHOWCASES]
    if args.dry_run:
        print("Would write:")
        for path in planned:
            print(f"- {path}")
        return

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for showcase in SHOWCASES:
        image = draw_showcase(showcase)
        output = args.output_dir / showcase.filename
        image.save(output)
        print(f"Wrote {output}")


if __name__ == "__main__":
    main()
