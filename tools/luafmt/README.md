# luafmt

Run the local StyLua formatter for the Medical Icons Lua runtime files.

## Purpose

This script formats or checks the Lua runtime code under `Lua/` using the
project-local StyLua binary at `bin/stylua.exe`. It exists so formatting can be
run from one stable project command without hard-coded absolute paths. StyLua is
run from the project root with the relative `Lua` path so `.styluaignore` is
applied to generated runtime files.

## Usage

Format the Lua runtime files:

```powershell
python tools/luafmt/luafmt.py
```

Check formatting and print a diff without rewriting files:

```powershell
python tools/luafmt/luafmt.py --check
```

Show command help:

```powershell
python tools/luafmt/luafmt.py --help
```

## Options

- `--check`: check formatting and print a diff without rewriting files.
- `-h`, `--help`: show the help text and exit.

## Inputs and Outputs

Inputs:

- `Lua/`: Lua runtime files to format or check.
- `.styluaignore`: project ignore patterns used by StyLua.
- `bin/stylua.exe`: project-local StyLua executable.

Outputs:

- Default mode may rewrite Lua files under `Lua/`.
- `--check` mode only reports formatting differences and leaves files unchanged.
- Files matched by `.styluaignore`, such as generated Lua data, are skipped.

## Notes

The script resolves paths relative to its own location and expects to remain at
`tools/luafmt/luafmt.py`.
