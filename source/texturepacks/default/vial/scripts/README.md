# Antidote Vial Recolor

`recolor_vial_antidotes.py` generates antidote vial item assets from the base vial artwork.

The script reads:

```text
source/texturepacks/default/vial/base/icon_source.png
source/texturepacks/default/vial/base/sprite.png
source/texturepacks/default/vial/masks/mask_source_*.png
```

It uses the vial masks to recolor cap metal, cap rubber, optional cap edge, optional label regions, and the glass/liquid area for each supported antidote identifier.

## Output

- Final in-game assets at `source/texturepacks/default/vial/items/<identifier>/icon.png`.
- Final in-game assets at `source/texturepacks/default/vial/items/<identifier>/sprite.png`.
- Recolored large icon sources in `source/texturepacks/default/vial/antidote_icon_sources/`.
- Mask preview images and `source/texturepacks/default/vial/antidote_vial_preview.png` for visual checking.

## Usage

Run from the project root:

```powershell
python source/texturepacks/default/vial/scripts/recolor_vial_antidotes.py
```
