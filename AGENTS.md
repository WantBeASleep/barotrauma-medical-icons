# Project Notes

## Overview
This project is a Barotrauma local client-side only mod named `Medical Icons` working through the LuaCs bridge.

## Project Layout
The project is structured as a normal Lua mod workspace.

Runtime and publishing files:

- `filelist.xml` - root Barotrauma mod descriptor.
- `workshop_description_en.bbcode` - English Steam Workshop description, similar to a Workshop-facing README.
- `workshop_description_ru.bbcode` - Russian Steam Workshop description, similar to a Workshop-facing README.
- `Lua/Autorun` - LuaCs autorun entrypoints.
- `Lua/limanchel/medical_icons` - main Lua module namespace.
- `Lua/limanchel/medical_icons/generated` - generated Lua data used by the runtime.
- `assets` - generated runtime atlases and other assets loaded by the mod.

Development and source areas:

- `source/textures` - item icon/sprite sources and final per-item texture inputs.
- `source/status_icons` - status icon source PNGs.
- `source/fonts` - fonts used by preview/generation scripts.
- `source/paint_dotnet` - paint.net working files.
- `preview/source` - source images for preview generation.
- `tools/build` - whole-project build and validation scripts.
- `tools/lualint` - Lua lint wrapper around the project-local Selene binary.
- `tools/luafmt` - Lua formatting wrapper around the project-local StyLua binary.
- `bin` - project-local helper executables such as Selene and StyLua.
- `preview` - generated development and Workshop preview images.

## Build Workflow
The canonical build command is:

```powershell
python tools/build/build_project.py
```

The build formats and lints Lua, validates item assets, packs item icon/sprite atlases into `assets`, overlays status icons by default, and generates Lua atlas data under `Lua/limanchel/medical_icons/generated`.

Run the mod build workflow when a change affects runtime data or generated assets: item icons/sprites under `source/textures/*/items/*`, status icon PNGs under `source/status_icons`, status icon mappings such as `tools/build/statusicons.csv`, atlas packing behavior, or scripts that generate atlas data.

## Lua Format

The canonical Lua format command is:

```powershell
python tools/luafmt/luafmt.py
```

Run the Lua format workflow after changing Lua runtime files under `Lua`, StyLua configuration files such as `.stylua.toml` or `.styluaignore`, or formatting helper scripts under `tools/luafmt`. Generated Lua data under `Lua/limanchel/medical_icons/generated` is excluded from formatting.

## Lua Lint
The canonical Lua lint command is:

```powershell
python tools/lualint/lualint.py
```

Run the Lua lint workflow after changing Lua runtime files under `Lua`, Selene configuration files such as `selene.toml`, `selene_std_luacs_client.yml`, or `selene_std_luacs_server.yml`, or lint helper scripts under `tools/lualint`.

## Agent Guidelines
- Agents must never create git commits in this repository.
- Keep Lua runtime code under `Lua`, preserving the `limanchel/medical_icons` namespace required by the LuaCs loading layout.
- Store generated Lua files under `Lua/limanchel/medical_icons/generated`.
- Store generated runtime atlases directly under `assets`.
- Keep source assets under `source`, scripts under `tools`, and generated previews under `preview`.
- Scripts must not hard-code absolute paths. Compute paths from the current script, project root, or known Barotrauma directory structure.
- Scripts must not depend on external files outside the Barotrauma install/project tree. If a script needs support files such as fonts, images, templates, or references, copy those files into the appropriate project folder and load them from there.
