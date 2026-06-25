# build_workshop

Build the clean Workshop version of the Medical Icons Barotrauma mod.

## Purpose

The development folder contains source assets, scripts, tooling, previews, lint configuration, and other files that must not be uploaded as the runtime Workshop mod. This script rebuilds a sibling folder in `LocalMods` with only the files required by the mod at runtime.

For a development folder named `DEV-medical-icons`, the default output folder is:

```text
../medical-icons
```

## Usage

Preview the output without writing files:

```powershell
python tools/workshop_build/build_workshop.py --dry-run
```

Build or overwrite the Workshop folder:

```powershell
python tools/workshop_build/build_workshop.py
```

Use a custom sibling output folder name:

```powershell
python tools/workshop_build/build_workshop.py --target-name medical-icons-workshop
```

## Options

```text
--dry-run
```

Print the target folder and runtime files that would be copied without creating or deleting anything.

```text
--target-name NAME
```

Set the output folder name inside the parent `LocalMods` directory.

Default:

```text
medical-icons
```

## Inputs

The script reads these runtime files from the development folder:

- `filelist.xml`
- `Lua/`
- `assets/icons.png`
- `assets/sprites.png`
- `preview/logo.gif`

The copied `filelist.xml` is adjusted for Workshop upload:

- A leading `DEV` prefix is removed from the root `contentpackage` `name` attribute.
- The root `contentpackage` gets `steamworkshopid="3748775860"`.

## Outputs

The script creates or replaces one sibling folder under the parent `LocalMods` directory. Existing contents of that target folder are removed before copying the runtime files.

## Notes

- The source project folder must start with `DEV`.
- The target folder must be a direct child of the same parent `LocalMods` directory.
- The Workshop output is built strictly from the allow-list in `build_workshop.py`. Development-only folders such as `source`, `tools`, `bin`, `.git`, `.codex`, and non-allow-listed files under `assets` and `preview` are intentionally not copied.
- When replacing an existing Workshop folder, the script removes the whole target first. On Windows it retries read-only files by making them writable; if a file is still locked by another process, close that process and run the script again.
