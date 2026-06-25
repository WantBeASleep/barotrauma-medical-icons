from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
STYLUA = PROJECT_ROOT / "bin" / "stylua.exe"
LUA_DIR = "Lua"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run StyLua for the project's Lua runtime files in Lua/."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check formatting and print a diff without rewriting files.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not STYLUA.is_file():
        print(f"StyLua executable not found at {STYLUA}", file=sys.stderr)
        return 1

    command = [str(STYLUA), "--verify"]
    if args.check:
        command.append("--check")
    command.append(LUA_DIR)

    completed = subprocess.run(command, cwd=PROJECT_ROOT)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
