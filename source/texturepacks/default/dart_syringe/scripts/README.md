# Poison Dart Syringe Recolor

`recolor_dart_syringe_poisons.py` generates poison-specific dart syringe item assets.

The script reads the base dart syringe preview assets:

```text
source/texturepacks/default/dart_syringe/base/icon.png
source/texturepacks/default/dart_syringe/base/sprite.png
```

It recolors the red accent and blue chamber areas for each supported poison identifier, then writes final in-game assets to:

```text
source/texturepacks/default/dart_syringe/items/<identifier>/icon.png
source/texturepacks/default/dart_syringe/items/<identifier>/sprite.png
```

The `paralyzant` variant uses a special multi-color tail/band recolor.

## Output

- One `icon.png` and `sprite.png` pair per poison identifier.
- `source/texturepacks/default/dart_syringe/poison_dart_preview.png`, a visual preview sheet.

## Usage

Run from the project root:

```powershell
python source/texturepacks/default/dart_syringe/scripts/recolor_dart_syringe_poisons.py
```
