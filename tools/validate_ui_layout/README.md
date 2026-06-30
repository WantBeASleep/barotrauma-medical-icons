# Validate UI Layout

## Purpose

Validates strict `barotrauma-ui-layout/v1` JSON files used by
`Lua/limanchel/medical_icons/lib/ui_runtime`.

The script catches schema mistakes before launching Barotrauma: forbidden
dynamic fields, duplicate local child ids, invalid size/color/range shapes,
unknown fields, and runtime-looking asset paths.

## Usage

Validate the default Medical Icons static layout:

```powershell
python tools/validate_ui_layout/validate_ui_layout.py
```

Validate one or more explicit layouts:

```powershell
python tools/validate_ui_layout/validate_ui_layout.py Lua/limanchel/medical_icons/ui/layouts/medical_icons_static.json
```

Print CLI help:

```powershell
python tools/validate_ui_layout/validate_ui_layout.py --help
```

## Options

- `paths`: optional layout JSON files. Defaults to `Lua/limanchel/medical_icons/ui/layouts/medical_icons_static.json`.
- `--allow-runtime-assets`: allows `assets/texturepacks` and `assets/overlaypacks` paths when validating intentionally dynamic/test layouts.
- `--quiet`: prints only errors and warnings.

## Inputs And Outputs

Reads layout JSON files inside the project tree. It does not write files.

Exit codes:

- `0`: valid, no warnings.
- `1`: validation error.
- `2`: valid JSON/schema, but warnings were found.

## Notes

This script mirrors the Lua `ui_runtime` validator, with extra text-level checks
for known footguns such as `\u` escapes and runtime atlas paths.
