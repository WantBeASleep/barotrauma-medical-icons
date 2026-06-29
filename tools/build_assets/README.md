# Build Assets

## Purpose

Builds runtime texturepack and overlaypack assets from `source` into `assets`.

The script packs every source texturepack into separate item icon and sprite atlases, writes an item atlas JSON file with atlas rectangles, packs every overlaypack into an overlay atlas, and copies item overlay JSON files plus `availability.json` from `source/overlaypacks`.

It also writes simple package indexes:

- `assets/texturepacks/index.json`
- `assets/overlaypacks/index.json`

## Usage

Default build:

```powershell
python tools/build_assets/build_assets.py
```

Preview planned writes without changing files:

```powershell
python tools/build_assets/build_assets.py --dry-run
```

Rebuild generated asset folders from scratch:

```powershell
python tools/build_assets/build_assets.py --clean
```

Use custom atlas widths:

```powershell
python tools/build_assets/build_assets.py --sprite-atlas-width 1024 --overlay-atlas-width 256
```

## Options

- `--texturepacks-dir DIR` reads texturepacks from `DIR`. Default: `source/texturepacks`.
- `--overlaypacks-dir DIR` reads overlaypacks from `DIR`. Default: `source/overlaypacks`.
- `--assets-dir DIR` writes generated assets under `DIR`. Default: `assets`.
- `--sprite-atlas-width PX` sets the preferred shelf width for `sprites.png`. Default: `512`.
- `--overlay-atlas-width PX` sets the preferred shelf width for overlaypack `atlas.png`. Default: `512`.
- `--clean` removes generated `assets/texturepacks` and `assets/overlaypacks` before writing.
- `--dry-run` validates inputs and reports writes without changing files.
- `--verbose` prints additional pack summaries.

## Inputs And Outputs

Texturepack inputs:

- `source/texturepacks/<texturepack_name>/<texture_name>/items/<item>/icon.png`
- `source/texturepacks/<texturepack_name>/<texture_name>/items/<item>/sprite.png`

Texturepack outputs:

- `assets/texturepacks/index.json`
- `assets/texturepacks/<texturepack_name>/icons.png`
- `assets/texturepacks/<texturepack_name>/sprites.png`
- `assets/texturepacks/<texturepack_name>/item_atlas.json`

Overlaypack inputs:

- `source/overlaypacks/availability.json`
- `source/overlaypacks/<overlaypack_name>/overlays/*.png`
- `source/overlaypacks/<overlaypack_name>/item_overlays/<texturepack_name>.json`

Overlaypack outputs:

- `assets/overlaypacks/index.json`
- `assets/overlaypacks/availability.json`
- `assets/overlaypacks/<overlaypack_name>/atlas.png`
- `assets/overlaypacks/<overlaypack_name>/overlay_atlas.json`
- `assets/overlaypacks/<overlaypack_name>/item_overlays/<texturepack_name>.json`

## Notes

- Item icons are packed into 64x64 cells. Non-64x64 source icons produce a warning and are resized in memory for the atlas; source files are not modified.
- Sprite and overlay atlas dimensions are padded to multiples of 4.
- `item_atlas.json` stores each item's icon and sprite rectangles inside the texturepack atlases.
- `overlay_atlas.json` stores each overlay's rectangle inside the overlaypack atlas.
- Item overlay JSON files must be arrays of objects with `overlay` and `item` string fields. Referenced overlays and texturepack items are checked, then files are copied unchanged.
- `availability.json` is copied unchanged after JSON validation. Its top-level keys must match all discovered overlaypack names.
