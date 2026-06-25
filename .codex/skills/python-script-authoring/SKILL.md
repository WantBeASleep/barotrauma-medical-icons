---
name: python-script-authoring
description: Create or edit project Python utility scripts with a consistent folder layout, argparse help, relative path handling, and companion README documentation. Use when Codex needs to add, modify, review, or relocate Python scripts in this repository or similar project workspaces.
---

# Python Script Authoring

## Core Rules

- Put every Python script in its own dedicated folder.
- Name the main script clearly, usually after the folder or action it performs.
- Include a `README.md` in the same folder as the script.
- Support both `-h` and `--help` through `argparse`; the help output must explain what the script does and list every available flag.
- Do not hard-code absolute paths.
- Resolve project paths relative to the script location, the current script folder, or an explicitly detected project root.
- Keep support files that the script needs inside the project tree and load them through relative paths.
- If a script needs external non-standard Python dependencies, vendor or install them into the current project's root `_vendor` directory and load them from there, for example by inserting `PROJECT_ROOT / "_vendor"` into `sys.path`. Do not create per-script `_vendor` folders for shared project dependencies.

## Script Pattern

Use `pathlib.Path` for filesystem paths. Prefer this shape:

```python
from argparse import ArgumentParser
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[2]


def parse_args():
    parser = ArgumentParser(
        description="Explain what this script does and when to use it."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without writing files.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    # Implement the script using paths derived from SCRIPT_DIR or PROJECT_ROOT.


if __name__ == "__main__":
    main()
```

Adjust `PROJECT_ROOT` detection to the actual folder depth. If the depth may change, walk upward until a stable project marker is found, such as `filelist.xml`, `.git`, or another repository-specific file.

## README Pattern

Create a nearby `README.md` with:

- Purpose: what the script does and why it exists.
- Usage: example commands, including the default command and meaningful flag combinations.
- Options: every supported flag and its effect.
- Inputs and outputs: files or folders read and written, described relative to the project.
- Notes: assumptions, limitations, or cleanup steps.

## Validation

- Run the script with `-h` or `--help` after creating or changing CLI arguments.
- Run a dry-run mode when the script can modify files.
