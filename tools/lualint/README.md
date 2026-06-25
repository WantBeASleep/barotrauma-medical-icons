# lualint

Run the local Selene linter for the Medical Icons Lua runtime files.

## Purpose

This script checks Lua runtime code using the project-local Selene binary at
`bin/selene.exe`. It exists so Lua linting can be run from one stable project
command without hard-coded absolute paths.

Selene is run from the project root, so it automatically uses `selene.toml` and
the project-local LuaCs standard files.

## Usage

Lint the Lua runtime files:

```powershell
python tools/lualint/lualint.py
```

Lint a specific Lua file or directory:

```powershell
python tools/lualint/lualint.py Lua/Autorun
```

Pass an extra argument to Selene:

```powershell
python tools/lualint/lualint.py --selene-arg=--display-style --selene-arg=rich
```

Show command help:

```powershell
python tools/lualint/lualint.py --help
```

## Options

- `targets`: optional Lua files or directories to lint, relative to the project
  root. Defaults to `Lua/`.
- `--selene-arg`: pass one additional argument to Selene. Repeat this option to
  pass multiple arguments.
- `-h`, `--help`: show the help text and exit.

## Inputs and Outputs

Inputs:

- `Lua/`: default Lua runtime directory to lint.
- `selene.toml`: lint rules and selected LuaCs standard.
- `selene_std_luacs_client.yml`: client-side LuaCs standard used by the current
  Selene configuration.
- `selene_std_luacs_server.yml`: alternate server-side LuaCs standard.
- `bin/selene.exe`: project-local Selene executable.

Outputs:

- The script prints Selene diagnostics to the console.
- It does not modify Lua source files.
- The process exits with Selene's exit code.

## Notes

The script resolves paths relative to its own location and expects to remain at
`tools/lualint/lualint.py`.
