from __future__ import annotations

import argparse
import csv
import math
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
VENDOR_DIR = PROJECT_ROOT / "_vendor"
DEFAULT_TEXTURES_DIR = PROJECT_ROOT / "source" / "textures"
DEFAULT_STATUSICONS_DIR = PROJECT_ROOT / "source" / "status_icons"
DEFAULT_ATLAS_OUT_DIR = PROJECT_ROOT / "assets"
DEFAULT_ATLASES_LUA = PROJECT_ROOT / "Lua" / "limanchel" / "medical_icons" / "generated" / "atlases.lua"
DEFAULT_STATUS_ICON_CSV = SCRIPT_DIR / "statusicons.csv"
DEFAULT_STATUS_ICON_OUT_DIR = SCRIPT_DIR / "status_icons"
LUAFMT_SCRIPT = PROJECT_ROOT / "tools" / "luafmt" / "luafmt.py"
LUALINT_SCRIPT = PROJECT_ROOT / "tools" / "lualint" / "lualint.py"
ICON_SIZE = 64
STATUS_ICON_SIZE = 24


@dataclass(frozen=True)
class ItemAsset:
    identifier: str
    texture: str
    item_dir: Path
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


@dataclass
class BuildContext:
    args: argparse.Namespace
    items: list[ItemAsset]
    icon_entries: dict[str, AtlasEntry]
    sprite_entries: dict[str, AtlasEntry]
    warnings: list[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate Medical Icons item assets, build atlases, and generate lua atlas data."
    )
    parser.add_argument("--validate-only", action="store_true", help="Only validate source item assets.")
    parser.add_argument(
        "--status-icons-csv",
        dest="status_icons_csv",
        type=Path,
        default=DEFAULT_STATUS_ICON_CSV,
        metavar="STATUS_CSV",
        help=(
            "Path to the item identifier -> status icon CSV mapping used by the default overlay step. "
            "Default: tools/build/statusicons.csv."
        ),
    )
    parser.add_argument(
        "--disable-status-icons",
        dest="disable_status_icons",
        action="store_true",
        help="Build item icon atlases without status icon overlays.",
    )
    parser.add_argument(
        "--save-status-icons",
        nargs="?",
        const=DEFAULT_STATUS_ICON_OUT_DIR,
        type=Path,
        metavar="DIR",
        help="Save 64x64 item icons after status icon overlay. Default: tools/build/status_icons.",
    )
    parser.add_argument(
        "--atlas-out",
        type=Path,
        default=DEFAULT_ATLAS_OUT_DIR,
        help="Directory for icons.png and sprites.png. Default: assets.",
    )
    parser.add_argument(
        "--atlases-lua",
        type=Path,
        default=DEFAULT_ATLASES_LUA,
        help="Generated Lua atlas table. Default: Lua/limanchel/medical_icons/generated/atlases.lua.",
    )
    parser.add_argument(
        "--textures-dir",
        type=Path,
        default=DEFAULT_TEXTURES_DIR,
        help="Directory with source texture item asset folders. Default: source/textures.",
    )
    parser.add_argument(
        "--statusicons-dir",
        type=Path,
        default=DEFAULT_STATUSICONS_DIR,
        help="Directory with 24x24 status icon PNGs. Default: source/status_icons.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Validate and report planned writes without writing files.")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors, for example missing status icon CSV mappings.",
    )
    parser.add_argument("--verbose", action="store_true", help="Print detailed item and output information.")
    parser.add_argument(
        "--sprite-atlas-width",
        type=int,
        default=512,
        help="Preferred sprite atlas shelf width before final multiple-of-4 padding. Default: 512.",
    )
    parser.add_argument("--csv-out", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--xml", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--filelist", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--vanilla-medical-dir", type=Path, help=argparse.SUPPRESS)
    return parser.parse_args()


def rel(path: Path) -> str:
    path = path.resolve()
    try:
        return str(path.relative_to(PROJECT_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def mod_path(path: Path) -> str:
    return rel(path)


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def run_python_tool(label: str, script_path: Path, extra_args: list[str] | None = None) -> None:
    if not script_path.is_file():
        fail(f"{label} script not found: {rel(script_path)}")

    command = [sys.executable, str(script_path), *(extra_args or [])]
    display_command = " ".join(["python", rel(script_path), *(extra_args or [])])
    print(f"Running {label}: {display_command}", flush=True)
    completed = subprocess.run(command, cwd=PROJECT_ROOT)
    if completed.returncode != 0:
        fail(f"{label} failed with exit code {completed.returncode}")


def run_pre_build_lua_checks(args: argparse.Namespace) -> None:
    formatter_args = ["--check"] if args.dry_run else []
    run_python_tool("Lua formatter", LUAFMT_SCRIPT, formatter_args)
    run_python_tool("Lua linter", LUALINT_SCRIPT)


def run_post_build_lua_checks() -> None:
    run_python_tool("Lua linter", LUALINT_SCRIPT)


def warn(ctx: BuildContext | None, message: str) -> None:
    if ctx is not None:
        ctx.warnings.append(message)
    print(f"WARNING: {message}")


def warn_deprecated_flags(args: argparse.Namespace) -> None:
    deprecated: list[str] = []
    if args.csv_out is not None:
        deprecated.append("--csv-out")
    if args.xml:
        deprecated.append("--xml")
    if args.filelist:
        deprecated.append("--filelist")
    if args.vanilla_medical_dir is not None:
        deprecated.append("--vanilla-medical-dir")
    if deprecated:
        print(f"WARNING: ignored deprecated XML/CSV build flag(s): {', '.join(deprecated)}")


def ensure_project_dirs(args: argparse.Namespace) -> None:
    required = [args.textures_dir, args.statusicons_dir]
    missing = [rel(path) for path in required if not path.is_dir()]
    if missing:
        fail(f"Missing required directories: {', '.join(missing)}")


def image_size(path: Path) -> tuple[int, int]:
    from PIL import Image

    with Image.open(path) as image:
        return image.size


def discover_items(textures_dir: Path) -> list[ItemAsset]:
    if not textures_dir.is_dir():
        fail(f"Textures directory not found: {rel(textures_dir)}")

    items: list[ItemAsset] = []
    seen: dict[str, Path] = {}
    for texture_dir in sorted(path for path in textures_dir.iterdir() if path.is_dir()):
        items_dir = texture_dir / "items"
        if not items_dir.is_dir():
            continue

        for item_dir in sorted(path for path in items_dir.iterdir() if path.is_dir()):
            identifier = item_dir.name
            if identifier in seen:
                fail(f"Duplicate item identifier '{identifier}' in {rel(seen[identifier])} and {rel(item_dir)}")
            seen[identifier] = item_dir

            icon_path = item_dir / "icon.png"
            sprite_path = item_dir / "sprite.png"
            if not icon_path.is_file():
                fail(f"Missing icon.png for '{identifier}' in {rel(item_dir)}")
            if not sprite_path.is_file():
                fail(f"Missing sprite.png for '{identifier}' in {rel(item_dir)}")

            icon_size = image_size(icon_path)
            sprite_size = image_size(sprite_path)
            if icon_size != (ICON_SIZE, ICON_SIZE):
                fail(f"{rel(icon_path)} is {icon_size[0]}x{icon_size[1]}, expected {ICON_SIZE}x{ICON_SIZE}")
            if sprite_size[0] <= 0 or sprite_size[1] <= 0:
                fail(f"{rel(sprite_path)} has invalid size {sprite_size[0]}x{sprite_size[1]}")

            items.append(
                ItemAsset(
                    identifier=identifier,
                    texture=texture_dir.name,
                    item_dir=item_dir,
                    icon_path=icon_path,
                    sprite_path=sprite_path,
                    icon_size=icon_size,
                    sprite_size=sprite_size,
                )
            )

    if not items:
        fail(f"No item folders found under {rel(textures_dir)}")
    return items


def read_status_icon_map(csv_path: Path, item_ids: set[str], statusicons_dir: Path) -> dict[str, str]:
    if not csv_path.is_file():
        fail(f"Status icon CSV not found: {rel(csv_path)}")

    mapping: dict[str, str] = {}
    with csv_path.open("r", newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            fail(f"Status icon CSV is empty: {rel(csv_path)}")
        normalized = {name.strip().lower(): name for name in reader.fieldnames}
        id_key = normalized.get("identifier") or normalized.get("identefer") or normalized.get("id")
        status_key = normalized.get("statusicon") or normalized.get("status_icon") or normalized.get("icon")
        if id_key is None or status_key is None:
            fail("Status icon CSV must contain identifier,statusicon columns")

        for line_number, row in enumerate(reader, start=2):
            identifier = (row.get(id_key) or "").strip()
            statusicon = (row.get(status_key) or "").strip()
            if not identifier and not statusicon:
                continue
            if not identifier or not statusicon:
                fail(f"Incomplete status icon CSV row {line_number}: {row}")
            if identifier not in item_ids:
                fail(f"Status icon CSV references unknown item identifier '{identifier}' on row {line_number}")
            if identifier in mapping:
                fail(f"Duplicate status icon mapping for '{identifier}' on row {line_number}")
            icon_path = statusicons_dir / f"{statusicon}.png"
            if not icon_path.is_file():
                fail(f"Status icon '{statusicon}' for '{identifier}' not found at {rel(icon_path)}")
            if image_size(icon_path) != (STATUS_ICON_SIZE, STATUS_ICON_SIZE):
                fail(f"{rel(icon_path)} must be {STATUS_ICON_SIZE}x{STATUS_ICON_SIZE}")
            mapping[identifier] = statusicon

    return mapping


def warn_missing_status_icon_mappings(ctx: BuildContext, status_map: dict[str, str]) -> None:
    missing = sorted(item.identifier for item in ctx.items if item.identifier not in status_map)
    if missing:
        warn(ctx, f"Status icon CSV is missing mappings for {len(missing)} item(s): {', '.join(missing)}")


def load_icon_with_status_overlay(item: ItemAsset, statusicon: str | None, statusicons_dir: Path) -> Image.Image:
    from PIL import Image

    icon = Image.open(item.icon_path).convert("RGBA")
    if statusicon is not None:
        overlay = Image.open(statusicons_dir / f"{statusicon}.png").convert("RGBA")
        icon.alpha_composite(overlay, (0, 0))
        overlay.close()
    return icon


def atlas_dimension(value: int) -> int:
    return max(4, math.ceil(value / 4) * 4)


def build_icon_atlas(
    items: list[ItemAsset],
    status_map: dict[str, str],
    args: argparse.Namespace,
) -> tuple[Image.Image, list[AtlasEntry]]:
    from PIL import Image

    columns = math.ceil(math.sqrt(len(items)))
    rows = math.ceil(len(items) / columns)
    atlas = Image.new("RGBA", (atlas_dimension(columns * ICON_SIZE), atlas_dimension(rows * ICON_SIZE)), (0, 0, 0, 0))
    entries: list[AtlasEntry] = []

    for index, item in enumerate(items):
        x = index % columns * ICON_SIZE
        y = index // columns * ICON_SIZE
        icon = load_icon_with_status_overlay(item, status_map.get(item.identifier), args.statusicons_dir)
        atlas.alpha_composite(icon, (x, y))
        entries.append(AtlasEntry(item.identifier, item.icon_path, x, y, ICON_SIZE, ICON_SIZE))
        icon.close()

    return atlas, entries


def build_sprite_atlas(items: list[ItemAsset], atlas_width: int) -> tuple[Image.Image, list[AtlasEntry]]:
    from PIL import Image

    if atlas_width <= 0:
        fail("--sprite-atlas-width must be greater than 0")
    atlas_width = atlas_dimension(atlas_width)
    x = 0
    y = 0
    row_height = 0
    placements: list[AtlasEntry] = []

    for item in items:
        width, height = item.sprite_size
        if width > atlas_width:
            fail(f"{rel(item.sprite_path)} is wider than --sprite-atlas-width ({width} > {atlas_width})")
        if x > 0 and x + width > atlas_width:
            x = 0
            y += row_height
            row_height = 0
        placements.append(AtlasEntry(item.identifier, item.sprite_path, x, y, width, height))
        x += width
        row_height = max(row_height, height)

    atlas_height = atlas_dimension(y + row_height)
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    for item, entry in zip(items, placements):
        sprite = Image.open(item.sprite_path).convert("RGBA")
        atlas.alpha_composite(sprite, (entry.x, entry.y))
        sprite.close()

    return atlas, placements


def save_status_overlay_icons(items: list[ItemAsset], status_map: dict[str, str], args: argparse.Namespace) -> None:
    if args.save_status_icons is None:
        return
    if not status_map:
        fail("--save-status-icons requires --status-icons-csv with at least one mapping")

    out_dir = args.save_status_icons
    if args.dry_run:
        print(f"DRY RUN: would write status-overlaid icons to {rel(out_dir)}")
        return

    out_dir.mkdir(parents=True, exist_ok=True)
    saved_count = 0
    for item in items:
        statusicon = status_map.get(item.identifier)
        if statusicon is None:
            continue
        icon = load_icon_with_status_overlay(item, statusicon, args.statusicons_dir)
        icon.save(out_dir / f"{item.identifier}.png")
        icon.close()
        saved_count += 1
    print(f"Wrote {saved_count} status-overlaid icon(s) to {rel(out_dir)}")


def load_lua_ast_modules() -> tuple[Any, Any]:
    if str(VENDOR_DIR) not in sys.path:
        sys.path.insert(0, str(VENDOR_DIR))
    try:
        from luaparser import ast, astnodes
    except ModuleNotFoundError:
        fail(
            "Missing vendored luaparser dependency. "
            "Install it with: python -m pip install luaparser==4.0.1 --target _vendor"
        )
    return ast, astnodes


def lua_string_node(astnodes: Any, value: str) -> Any:
    raw = value.replace("\\", "\\\\").replace("'", "\\'")
    return astnodes.String(raw.encode("utf-8"), raw, astnodes.StringDelimiter.SINGLE_QUOTE)


def lua_array_table(astnodes: Any, values: list[Any]) -> Any:
    return astnodes.Table([astnodes.Field(None, value) for value in values])


def lua_named_field(astnodes: Any, key: str, value: Any) -> Any:
    return astnodes.Field(astnodes.Name(key), value)


def lua_string_keyed_field(astnodes: Any, key: str, value: Any) -> Any:
    return astnodes.Field(lua_string_node(astnodes, key), value, between_brackets=True)


def lua_rect_table(astnodes: Any, entry: AtlasEntry) -> Any:
    return lua_array_table(
        astnodes,
        [
            astnodes.Number(entry.x),
            astnodes.Number(entry.y),
            astnodes.Number(entry.width),
            astnodes.Number(entry.height),
        ],
    )


def build_atlases_lua_ast(ctx: BuildContext, icons_path: Path, sprites_path: Path) -> Any:
    _, astnodes = load_lua_ast_modules()
    item_by_id = {item.identifier: item for item in ctx.items}
    item_fields = []

    for identifier in sorted(item_by_id):
        item = item_by_id[identifier]
        icon_entry = ctx.icon_entries[identifier]
        sprite_entry = ctx.sprite_entries[identifier]
        item_fields.append(
            lua_string_keyed_field(
                astnodes,
                identifier,
                astnodes.Table(
                    [
                        lua_named_field(astnodes, "texture", lua_string_node(astnodes, item.texture)),
                        lua_named_field(
                            astnodes,
                            "icon",
                            astnodes.Table([lua_named_field(astnodes, "rect", lua_rect_table(astnodes, icon_entry))]),
                        ),
                        lua_named_field(
                            astnodes,
                            "sprite",
                            astnodes.Table([lua_named_field(astnodes, "rect", lua_rect_table(astnodes, sprite_entry))]),
                        ),
                    ]
                ),
            )
        )

    atlases_table = astnodes.Table(
        [
            lua_named_field(
                astnodes,
                "assets",
                astnodes.Table(
                    [
                        lua_named_field(astnodes, "icons", lua_string_node(astnodes, mod_path(icons_path))),
                        lua_named_field(astnodes, "sprites", lua_string_node(astnodes, mod_path(sprites_path))),
                    ]
                ),
            ),
            lua_named_field(astnodes, "items", astnodes.Table(item_fields)),
        ]
    )

    return astnodes.Chunk(
        astnodes.Block(
            [
                astnodes.LocalAssign([astnodes.Name("atlases")], [atlases_table]),
                astnodes.Return([astnodes.Name("atlases")]),
            ]
        )
    )


def render_atlases_lua(ctx: BuildContext, icons_path: Path, sprites_path: Path) -> str:
    ast, _ = load_lua_ast_modules()
    chunk = build_atlases_lua_ast(ctx, icons_path, sprites_path)
    generated_source = ast.to_lua_source(chunk).rstrip()
    header = [
        "-- This file is generated by tools/build/build_project.py.",
        "-- Manual runtime constants belong in data.lua.",
        "",
        "---@alias MedicalIconsAtlasRect integer[]",
        "",
        "---@class MedicalIconsAtlasRegion",
        "---@field rect MedicalIconsAtlasRect",
        "",
        "---@class MedicalIconsAtlasItem",
        "---@field texture string",
        "---@field icon MedicalIconsAtlasRegion",
        "---@field sprite MedicalIconsAtlasRegion",
        "",
        "---@class MedicalIconsAtlasAssets",
        "---@field icons string",
        "---@field sprites string",
        "",
        "---@class MedicalIconsAtlases",
        "---@field assets MedicalIconsAtlasAssets",
        "---@field items table<string, MedicalIconsAtlasItem>",
        "",
        "---@type MedicalIconsAtlases",
    ]
    return "\n".join([*header, generated_source, ""])


def write_atlases_lua(ctx: BuildContext, icons_path: Path, sprites_path: Path) -> None:
    content = render_atlases_lua(ctx, icons_path, sprites_path)
    if ctx.args.dry_run:
        print(f"DRY RUN: would write {rel(ctx.args.atlases_lua)}")
        return

    ctx.args.atlases_lua.parent.mkdir(parents=True, exist_ok=True)
    ctx.args.atlases_lua.write_text(content, encoding="utf-8")
    print(f"Wrote {rel(ctx.args.atlases_lua)}")


def write_atlases(ctx: BuildContext, status_map: dict[str, str]) -> None:
    icon_atlas, icon_entries = build_icon_atlas(ctx.items, status_map, ctx.args)
    sprite_atlas, sprite_entries = build_sprite_atlas(ctx.items, ctx.args.sprite_atlas_width)
    ctx.icon_entries = {entry.identifier: entry for entry in icon_entries}
    ctx.sprite_entries = {entry.identifier: entry for entry in sprite_entries}

    icons_path = ctx.args.atlas_out / "icons.png"
    sprites_path = ctx.args.atlas_out / "sprites.png"

    if ctx.args.dry_run:
        print(f"DRY RUN: would write {rel(icons_path)} ({icon_atlas.width}x{icon_atlas.height})")
        print(f"DRY RUN: would write {rel(sprites_path)} ({sprite_atlas.width}x{sprite_atlas.height})")
    else:
        ctx.args.atlas_out.mkdir(parents=True, exist_ok=True)
        icon_atlas.save(icons_path)
        sprite_atlas.save(sprites_path)
        print(f"Wrote {rel(icons_path)} ({icon_atlas.width}x{icon_atlas.height})")
        print(f"Wrote {rel(sprites_path)} ({sprite_atlas.width}x{sprite_atlas.height})")

    write_atlases_lua(ctx, icons_path, sprites_path)
    print(f"Packed {len(icon_entries)} icons into {icon_atlas.width}x{icon_atlas.height}")
    print(f"Packed {len(sprite_entries)} sprites into {sprite_atlas.width}x{sprite_atlas.height}")
    icon_atlas.close()
    sprite_atlas.close()


def print_item_summary(items: list[ItemAsset], verbose: bool) -> None:
    print(f"Validated {len(items)} item asset folders")
    if not verbose:
        return
    for item in items:
        print(
            f"  {item.identifier}: {item.texture}, icon {item.icon_size[0]}x{item.icon_size[1]}, "
            f"sprite {item.sprite_size[0]}x{item.sprite_size[1]}"
        )


def main() -> None:
    args = parse_args()
    warn_deprecated_flags(args)
    ensure_project_dirs(args)
    if args.disable_status_icons and args.save_status_icons is not None:
        fail("--save-status-icons cannot be used with --disable-status-icons")

    if not args.validate_only:
        run_pre_build_lua_checks(args)

    items = discover_items(args.textures_dir)
    print_item_summary(items, args.verbose)
    ctx = BuildContext(args=args, items=items, icon_entries={}, sprite_entries={}, warnings=[])

    status_map: dict[str, str] = {}
    if not args.disable_status_icons:
        status_map = read_status_icon_map(args.status_icons_csv, {item.identifier for item in items}, args.statusicons_dir)
        print(f"Loaded {len(status_map)} status icon mappings from {rel(args.status_icons_csv)}")
        warn_missing_status_icon_mappings(ctx, status_map)

    if not args.disable_status_icons:
        save_status_overlay_icons(items, status_map, args)

    if not args.validate_only:
        write_atlases(ctx, status_map)
        if not args.dry_run:
            run_post_build_lua_checks()

    if ctx.warnings and args.strict:
        fail(f"Strict mode failed with {len(ctx.warnings)} warnings")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("Interrupted")
