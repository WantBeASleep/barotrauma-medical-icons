from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
SELENE = PROJECT_ROOT / "bin" / "selene.exe"
DEFAULT_TARGET = "Lua"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Selene for the project's Lua runtime files."
    )
    parser.add_argument(
        "targets",
        nargs="*",
        default=[DEFAULT_TARGET],
        help="Lua files or directories to lint, relative to the project root. Defaults to Lua/.",
    )
    parser.add_argument(
        "--selene-arg",
        action="append",
        default=[],
        help="Additional argument to pass to Selene. Repeat for multiple arguments.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not SELENE.is_file():
        print(f"Selene executable not found at {SELENE}", file=sys.stderr)
        return 1

    command = [str(SELENE), *args.selene_arg, *args.targets]
    completed = subprocess.run(command, cwd=PROJECT_ROOT)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
