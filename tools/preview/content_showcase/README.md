# Content Showcase Builder

## Purpose

Builds six static 1920x1080 PNG images that demonstrate the Medical Icons mod content in the same sonar/comic style as the selected `preview/logo.gif`.

Each image uses a top title, category subtitle, and central icon showcase. Category slides use status-overlaid icons produced by `tools/build/build_project.py --save-status-icons`; the `Textures` slide uses raw texture-family icons without status marks.

## Usage

Build status-overlaid icons first:

```powershell
python tools/build/build_project.py --save-status-icons
```

Generate the showcase PNGs:

```powershell
python tools/preview/content_showcase/build_content_showcase.py
```

Preview planned outputs without writing:

```powershell
python tools/preview/content_showcase/build_content_showcase.py --dry-run
```

## Options

- `--output-dir` - directory for generated PNG files, defaulting to `preview`.
- `--dry-run` - print planned output files without writing images.

## Inputs And Outputs

Reads raw texture icons from `source/textures` and status-overlaid item icons from `tools/build/status_icons`.

Writes:

- `preview/01_textures.png`
- `preview/02_medicine.png`
- `preview/03_basic_chemicals.png`
- `preview/04_toxins.png`
- `preview/05_antidotes.png`
- `preview/06_stimulants.png`

## Notes

The script resolves all paths from its own location and the project root marker `filelist.xml`.
