from __future__ import annotations

import argparse
import os
import shutil
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent


@dataclass(frozen=True)
class CopyEntry:
    source: Path
    target: Path


def find_project_root() -> Path:
    for path in (SCRIPT_DIR, *SCRIPT_DIR.parents):
        if (path / "filelist.xml").is_file() and (path / "Lua").is_dir():
            return path
    raise SystemExit("ERROR: Could not find project root from script location.")


PROJECT_ROOT = find_project_root()
LOCALMODS_DIR = PROJECT_ROOT.parent
DEV_PREFIX = "DEV"
DEV_PREFIX_SEPARATORS = " -_"
STEAM_WORKSHOP_ID = "3748775860"
WORKSHOP_ALLOWLIST = (
    "Lua",
    "assets/icons.png",
    "assets/sprites.png",
    "preview/logo.gif",
    "filelist.xml",
)


def clean_dev_prefix(value: str) -> str:
    return value.removeprefix(DEV_PREFIX).lstrip(DEV_PREFIX_SEPARATORS)


DEFAULT_TARGET_NAME = clean_dev_prefix(PROJECT_ROOT.name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build the clean Workshop folder for this Barotrauma mod by copying only runtime files "
            "from the development folder."
        )
    )
    parser.add_argument(
        "--target-name",
        default=DEFAULT_TARGET_NAME,
        help=(
            "Output folder name inside the parent LocalMods directory. "
            f"Default: {DEFAULT_TARGET_NAME!r}, derived from the current folder without the DEV prefix."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the target folder and files that would be copied without writing anything.",
    )
    return parser.parse_args()


def rel(path: Path) -> str:
    path = path.resolve()
    try:
        return str(path.relative_to(PROJECT_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def validate_target(target_dir: Path) -> None:
    target_dir = target_dir.resolve()
    project_root = PROJECT_ROOT.resolve()
    localmods_dir = LOCALMODS_DIR.resolve()

    if not DEFAULT_TARGET_NAME:
        fail("Development folder name does not produce a valid Workshop folder name.")
    if not PROJECT_ROOT.name.startswith(DEV_PREFIX):
        fail("Refusing to build Workshop folder because the source folder does not start with DEV.")
    if target_dir == project_root:
        fail("Target folder resolves to the development folder.")
    if target_dir.parent != localmods_dir:
        fail(f"Target folder must be directly inside {localmods_dir}.")
    if not target_dir.name:
        fail("Target folder name is empty.")
    if target_dir.name in {".", ".."}:
        fail(f"Invalid target folder name: {target_dir.name!r}.")


def collect_entries(target_dir: Path) -> list[CopyEntry]:
    entries: list[CopyEntry] = []

    for allowlist_path in WORKSHOP_ALLOWLIST:
        source = PROJECT_ROOT / allowlist_path
        if not source.exists():
            fail(f"Allow-listed path not found: {rel(source)}")
        if not source.is_file() and not source.is_dir():
            fail(f"Allow-listed path is not a file or directory: {rel(source)}")
        entries.append(CopyEntry(source=source, target=target_dir / allowlist_path))

    return entries


def print_plan(target_dir: Path, entries: list[CopyEntry], dry_run: bool) -> None:
    action = "Would rebuild" if dry_run else "Rebuilding"
    print(f"{action} Workshop folder: {target_dir}")
    print("Runtime files:")
    for entry in entries:
        print(f"  {rel(entry.source)}")


def make_writable_and_retry(function, path: str, error: BaseException) -> None:
    try:
        os.chmod(path, 0o700)
        function(path)
    except OSError as retry_error:
        raise retry_error from error


def remove_existing_target(target_dir: Path) -> None:
    try:
        shutil.rmtree(target_dir, onexc=make_writable_and_retry)
    except PermissionError as error:
        fail(
            "Could not remove the existing Workshop folder. "
            f"Close programs that may be using it and check file permissions: {error.filename}"
        )


def copy_workshop_filelist(source: Path, target: Path) -> None:
    try:
        tree = ET.parse(source)
    except ET.ParseError as error:
        fail(f"Could not parse {rel(source)}: {error}")

    root = tree.getroot()
    if root.tag != "contentpackage":
        fail(f"{rel(source)} root element must be <contentpackage>, found <{root.tag}>.")

    package_name = root.get("name")
    if package_name is None:
        fail(f"{rel(source)} is missing the contentpackage name attribute.")

    root.set("name", clean_dev_prefix(package_name))
    root.set("steamworkshopid", STEAM_WORKSHOP_ID)
    target.parent.mkdir(parents=True, exist_ok=True)
    tree.write(target, encoding="utf-8", xml_declaration=True, short_empty_elements=False)


def copy_entries(target_dir: Path, entries: list[CopyEntry]) -> None:
    if target_dir.exists():
        if not target_dir.is_dir():
            fail(f"Target path exists and is not a directory: {target_dir}")
        remove_existing_target(target_dir)

    target_dir.mkdir(parents=True)
    for entry in entries:
        if entry.source.is_dir():
            shutil.copytree(entry.source, entry.target)
        elif entry.source.name == "filelist.xml":
            copy_workshop_filelist(entry.source, entry.target)
        else:
            entry.target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(entry.source, entry.target)


def main() -> None:
    args = parse_args()
    target_dir = LOCALMODS_DIR / args.target_name
    validate_target(target_dir)
    entries = collect_entries(target_dir)
    print_plan(target_dir, entries, args.dry_run)

    if args.dry_run:
        return

    copy_entries(target_dir, entries)
    print("Workshop folder is ready.")


if __name__ == "__main__":
    main()
