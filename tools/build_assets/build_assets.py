from __future__ import annotations

import argparse
import json
import math
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

sys.dont_write_bytecode = True

SCRIPT_DIR = Path(__file__).resolve().parent


def find_project_root() -> Path:
    for path in [SCRIPT_DIR, *SCRIPT_DIR.parents]:
        if (path / "filelist.xml").is_file():
            return path
    raise SystemExit("ERROR: Could not find project root with filelist.xml")


PROJECT_ROOT = find_project_root()
DEFAULT_TEXTUREPACKS_DIR = PROJECT_ROOT / "source" / "texturepacks"
DEFAULT_OVERLAYPACKS_DIR = PROJECT_ROOT / "source" / "overlaypacks"
DEFAULT_ASSETS_DIR = PROJECT_ROOT / "assets"
TEXTUREPACKS_LIST_NAME = "list.json"
OVERLAYPACKS_LIST_NAME = "list.json"
ICON_SIZE = 64


@dataclass(frozen=True)
class ItemAsset:
    identifier: str
    texture: str
    icon_path: Path
    sprite_path: Path
    icon_size: tuple[int, int]
    sprite_size: tuple[int, int]


@dataclass(frozen=True)
class AtlasEntry:
    identifier: str
    source: Path
    x: int
    y: int
    width: int
    height: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build Medical Icons texturepack and overlaypack atlases from source into assets."
        )
    )
    parser.add_argument(
        "--texturepacks-dir",
        type=Path,
        default=DEFAULT_TEXTUREPACKS_DIR,
        help="Directory with source texturepacks. Default: source/texturepacks.",
    )
    parser.add_argument(
        "--overlaypacks-dir",
        type=Path,
        default=DEFAULT_OVERLAYPACKS_DIR,
        help="Directory with source overlaypacks. Default: source/overlaypacks.",
    )
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=DEFAULT_ASSETS_DIR,
        help="Output assets directory. Default: assets.",
    )
    parser.add_argument(
        "--sprite-atlas-width",
        type=int,
        default=512,
        help="Preferred sprite atlas shelf width before multiple-of-4 padding. Default: 512.",
    )
    parser.add_argument(
        "--overlay-atlas-width",
        type=int,
        default=512,
        help="Preferred overlay atlas shelf width before multiple-of-4 padding. Default: 512.",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove generated texturepacks and overlaypacks outputs before writing them.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs and report planned writes without writing files.",
    )
    parser.add_argument("--verbose", action="store_true", help="Print detailed source and output information.")
    return parser.parse_args()


def rel(path: Path) -> str:
    path = path.resolve()
    try:
        return str(path.relative_to(PROJECT_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def warn(message: str) -> None:
    print(f"WARNING: {message}")


def atlas_dimension(value: int) -> int:
    return max(4, math.ceil(value / 4) * 4)


def image_size(path: Path) -> tuple[int, int]:
    try:
        from PIL import Image
    except ModuleNotFoundError:
        fail("Missing Pillow dependency. Install it with: python -m pip install pillow")

    with Image.open(path) as image:
        return image.size


def ensure_dirs(args: argparse.Namespace) -> None:
    missing = [
        rel(path)
        for path in [args.texturepacks_dir, args.overlaypacks_dir]
        if not path.is_dir()
    ]
    if missing:
        fail(f"Missing required directories: {', '.join(missing)}")


def discover_texturepack_items(texturepack_dir: Path) -> list[ItemAsset]:
    items: list[ItemAsset] = []
    seen: dict[str, Path] = {}

    for texture_dir in sorted(path for path in texturepack_dir.iterdir() if path.is_dir()):
        items_dir = texture_dir / "items"
        if not items_dir.is_dir():
            continue

        for item_dir in sorted(path for path in items_dir.iterdir() if path.is_dir()):
            identifier = item_dir.name
            if identifier in seen:
                fail(f"Duplicate item '{identifier}' in {rel(seen[identifier])} and {rel(item_dir)}")
            seen[identifier] = item_dir

            icon_path = item_dir / "icon.png"
            sprite_path = item_dir / "sprite.png"
            if not icon_path.is_file():
                fail(f"Missing icon.png for '{identifier}' in {rel(item_dir)}")
            if not sprite_path.is_file():
                fail(f"Missing sprite.png for '{identifier}' in {rel(item_dir)}")

            icon_size = image_size(icon_path)
            if icon_size[0] <= 0 or icon_size[1] <= 0:
                fail(f"{rel(icon_path)} has invalid size {icon_size[0]}x{icon_size[1]}")
            if icon_size != (ICON_SIZE, ICON_SIZE):
                warn(
                    f"{rel(icon_path)} is {icon_size[0]}x{icon_size[1]}; "
                    f"it will be resized to {ICON_SIZE}x{ICON_SIZE} in icons.png"
                )

            sprite_size = image_size(sprite_path)
            if sprite_size[0] <= 0 or sprite_size[1] <= 0:
                fail(f"{rel(sprite_path)} has invalid size {sprite_size[0]}x{sprite_size[1]}")

            items.append(
                ItemAsset(
                    identifier=identifier,
                    texture=texture_dir.name,
                    icon_path=icon_path,
                    sprite_path=sprite_path,
                    icon_size=icon_size,
                    sprite_size=sprite_size,
                )
            )

    if not items:
        fail(f"No item folders found under {rel(texturepack_dir)}")
    return items


def discover_texturepacks(texturepacks_dir: Path) -> dict[str, list[ItemAsset]]:
    texturepacks: dict[str, list[ItemAsset]] = {}
    for texturepack_dir in sorted(path for path in texturepacks_dir.iterdir() if path.is_dir()):
        texturepacks[texturepack_dir.name] = discover_texturepack_items(texturepack_dir)
    if not texturepacks:
        fail(f"No texturepacks found under {rel(texturepacks_dir)}")
    return texturepacks


def build_icon_atlas(items: list[ItemAsset]) -> tuple[object, list[AtlasEntry]]:
    from PIL import Image

    columns = math.ceil(math.sqrt(len(items)))
    rows = math.ceil(len(items) / columns)
    atlas = Image.new("RGBA", (atlas_dimension(columns * ICON_SIZE), atlas_dimension(rows * ICON_SIZE)), (0, 0, 0, 0))
    entries: list[AtlasEntry] = []

    for index, item in enumerate(items):
        x = index % columns * ICON_SIZE
        y = index // columns * ICON_SIZE
        with Image.open(item.icon_path) as source:
            icon = source.convert("RGBA")
            if icon.size != (ICON_SIZE, ICON_SIZE):
                icon = icon.resize((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS)
            atlas.alpha_composite(icon, (x, y))
        entries.append(AtlasEntry(item.identifier, item.icon_path, x, y, ICON_SIZE, ICON_SIZE))

    return atlas, entries


def build_shelf_atlas(images: list[tuple[str, Path, tuple[int, int]]], atlas_width: int) -> tuple[object, list[AtlasEntry]]:
    from PIL import Image

    if atlas_width <= 0:
        fail("Atlas width must be greater than 0")

    atlas_width = atlas_dimension(atlas_width)
    x = 0
    y = 0
    row_height = 0
    entries: list[AtlasEntry] = []

    for identifier, path, (width, height) in images:
        if width > atlas_width:
            fail(f"{rel(path)} is wider than atlas width ({width} > {atlas_width})")
        if x > 0 and x + width > atlas_width:
            x = 0
            y += row_height
            row_height = 0
        entries.append(AtlasEntry(identifier, path, x, y, width, height))
        x += width
        row_height = max(row_height, height)

    atlas_height = atlas_dimension(y + row_height)
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    for entry in entries:
        with Image.open(entry.source) as source:
            atlas.alpha_composite(source.convert("RGBA"), (entry.x, entry.y))

    return atlas, entries


def build_sprite_atlas(items: list[ItemAsset], atlas_width: int) -> tuple[object, list[AtlasEntry]]:
    images = [(item.identifier, item.sprite_path, item.sprite_size) for item in items]
    return build_shelf_atlas(images, atlas_width)


def texturepack_mapping_rows(
    items: list[ItemAsset],
    icon_entries: list[AtlasEntry],
    sprite_entries: list[AtlasEntry],
) -> list[dict[str, str | int]]:
    icons = {entry.identifier: entry for entry in icon_entries}
    sprites = {entry.identifier: entry for entry in sprite_entries}
    rows: list[dict[str, str | int]] = []

    for item in items:
        icon = icons[item.identifier]
        sprite = sprites[item.identifier]
        rows.append(
            {
                "item": item.identifier,
                "texture": item.texture,
                "icon_x": icon.x,
                "icon_y": icon.y,
                "icon_width": icon.width,
                "icon_height": icon.height,
                "sprite_x": sprite.x,
                "sprite_y": sprite.y,
                "sprite_width": sprite.width,
                "sprite_height": sprite.height,
            }
        )
    return rows


def write_mapping_json(path: Path, rows: list[dict[str, str | int]], dry_run: bool) -> None:
    if dry_run:
        print(f"DRY RUN: would write {rel(path)} ({len(rows)} row(s))")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(rows, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"Wrote {rel(path)} ({len(rows)} row(s))")


def write_name_list_json(path: Path, names: list[str], dry_run: bool) -> None:
    if dry_run:
        print(f"DRY RUN: would write {rel(path)} ({len(names)} name(s))")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(names, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"Wrote {rel(path)} ({len(names)} name(s))")


def clean_dir(path: Path, dry_run: bool) -> None:
    if not path.exists():
        return
    if dry_run:
        print(f"DRY RUN: would remove {rel(path)}")
        return
    shutil.rmtree(path)
    print(f"Removed {rel(path)}")


def save_atlas(path: Path, atlas: object, dry_run: bool) -> None:
    width = getattr(atlas, "width")
    height = getattr(atlas, "height")
    if dry_run:
        print(f"DRY RUN: would write {rel(path)} ({width}x{height})")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
    print(f"Wrote {rel(path)} ({width}x{height})")


def build_texturepacks(args: argparse.Namespace, texturepacks: dict[str, list[ItemAsset]]) -> None:
    out_root = args.assets_dir / "texturepacks"
    if args.clean:
        clean_dir(out_root, args.dry_run)

    texturepacks_list = sorted(texturepacks)
    write_name_list_json(out_root / TEXTUREPACKS_LIST_NAME, texturepacks_list, args.dry_run)

    for name, items in texturepacks.items():
        out_dir = out_root / name
        icon_atlas, icon_entries = build_icon_atlas(items)
        sprite_atlas, sprite_entries = build_sprite_atlas(items, args.sprite_atlas_width)
        rows = texturepack_mapping_rows(items, icon_entries, sprite_entries)

        save_atlas(out_dir / "icons.png", icon_atlas, args.dry_run)
        save_atlas(out_dir / "sprites.png", sprite_atlas, args.dry_run)
        write_mapping_json(out_dir / "mapping.json", rows, args.dry_run)

        if args.verbose:
            print(f"Packed texturepack '{name}' with {len(items)} item(s)")
        icon_atlas.close()
        sprite_atlas.close()


def read_overlay_mapping(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        fail(f"Overlay mapping JSON must be an array: {rel(path)}")

    rows: list[dict[str, str]] = []
    for index, item in enumerate(data, start=1):
        if not isinstance(item, dict):
            fail(f"Overlay mapping entry {index} must be an object in {rel(path)}")
        overlay = item.get("overlay")
        target_item = item.get("item")
        if not isinstance(overlay, str) or not isinstance(target_item, str):
            fail(f"Overlay mapping entry {index} must contain string overlay,item in {rel(path)}")
        overlay = overlay.strip()
        target_item = target_item.strip()
        if not overlay or not target_item:
            fail(f"Overlay mapping entry {index} has empty overlay or item in {rel(path)}")
        rows.append({"overlay": overlay, "item": target_item})
    return rows


def validate_overlay_mapping(
    mapping_path: Path,
    overlay_ids: set[str],
    texturepacks: dict[str, list[ItemAsset]],
) -> None:
    texturepack_name = mapping_path.stem
    if texturepack_name not in texturepacks:
        fail(f"{rel(mapping_path)} references unknown texturepack '{texturepack_name}'")

    item_ids = {item.identifier for item in texturepacks[texturepack_name]}
    for row in read_overlay_mapping(mapping_path):
        if row["overlay"] not in overlay_ids:
            fail(f"{rel(mapping_path)} references unknown overlay '{row['overlay']}'")
        if row["item"] not in item_ids:
            fail(f"{rel(mapping_path)} references unknown item '{row['item']}'")


def discover_overlay_pngs(overlays_dir: Path) -> list[tuple[str, Path, tuple[int, int]]]:
    if not overlays_dir.is_dir():
        fail(f"Missing overlays directory: {rel(overlays_dir)}")

    overlays: list[tuple[str, Path, tuple[int, int]]] = []
    for path in sorted(overlays_dir.glob("*.png")):
        overlays.append((path.stem, path, image_size(path)))
    if not overlays:
        fail(f"No overlay PNG files found under {rel(overlays_dir)}")
    return overlays


def copy_file(source: Path, destination: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"DRY RUN: would copy {rel(source)} -> {rel(destination)}")
        return

    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    print(f"Copied {rel(source)} -> {rel(destination)}")


def copy_overlay_mapping(source_dir: Path, destination_dir: Path, dry_run: bool) -> None:
    if not source_dir.is_dir():
        fail(f"Missing overlay mapping directory: {rel(source_dir)}")

    mapping_files = sorted(source_dir.glob("*.json"))
    if not mapping_files:
        fail(f"No overlay mapping JSON files found under {rel(source_dir)}")

    for source in mapping_files:
        copy_file(source, destination_dir / source.name, dry_run)


def validate_rules_json(path: Path, overlaypacks_list: list[str]) -> None:
    if not path.is_file():
        fail(f"Missing overlaypack rules file: {rel(path)}")
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        fail(f"Overlaypack rules JSON must be an object: {rel(path)}")

    expected = set(overlaypacks_list)
    actual = set(data)
    missing = sorted(expected - actual)
    unknown = sorted(actual - expected)
    if missing:
        fail(f"{rel(path)} is missing overlaypack rule(s): {', '.join(missing)}")
    if unknown:
        fail(f"{rel(path)} contains unknown overlaypack rule(s): {', '.join(unknown)}")


def build_overlaypacks(args: argparse.Namespace, texturepacks: dict[str, list[ItemAsset]]) -> None:
    out_root = args.assets_dir / "overlaypacks"
    rules_path = args.overlaypacks_dir / "rules.json"
    overlaypack_dirs = sorted(
        path for path in args.overlaypacks_dir.iterdir() if path.is_dir()
    )
    if not overlaypack_dirs:
        fail(f"No overlaypacks found under {rel(args.overlaypacks_dir)}")
    overlaypacks_list = [path.name for path in overlaypack_dirs]
    validate_rules_json(rules_path, overlaypacks_list)

    if args.clean:
        clean_dir(out_root, args.dry_run)

    write_name_list_json(out_root / OVERLAYPACKS_LIST_NAME, overlaypacks_list, args.dry_run)
    copy_file(rules_path, out_root / "rules.json", args.dry_run)

    for overlaypack_dir in overlaypack_dirs:
        name = overlaypack_dir.name
        overlays = discover_overlay_pngs(overlaypack_dir / "overlays")
        overlay_ids = {identifier for identifier, _, _ in overlays}
        mapping_dir = overlaypack_dir / "mapping"
        for mapping_path in sorted(mapping_dir.glob("*.json")):
            validate_overlay_mapping(mapping_path, overlay_ids, texturepacks)

        atlas, entries = build_shelf_atlas(overlays, args.overlay_atlas_width)
        out_dir = out_root / name
        save_atlas(out_dir / "atlas.png", atlas, args.dry_run)
        copy_overlay_mapping(mapping_dir, out_dir / "mapping", args.dry_run)

        if args.verbose:
            print(f"Packed overlaypack '{name}' with {len(entries)} overlay(s)")
        atlas.close()


def main() -> None:
    args = parse_args()
    ensure_dirs(args)
    texturepacks = discover_texturepacks(args.texturepacks_dir)
    build_texturepacks(args, texturepacks)
    build_overlaypacks(args, texturepacks)


if __name__ == "__main__":
    main()
