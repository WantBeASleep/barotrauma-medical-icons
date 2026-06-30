from __future__ import annotations

from argparse import ArgumentParser
from json import JSONDecodeError
from pathlib import Path
import json
import sys
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent


def find_project_root() -> Path:
    for path in [SCRIPT_DIR, *SCRIPT_DIR.parents]:
        if (path / "filelist.xml").is_file() and (path / "Lua").is_dir():
            return path
    raise RuntimeError("project root not found; expected filelist.xml and Lua/")


PROJECT_ROOT = find_project_root()
DEFAULT_LAYOUT = PROJECT_ROOT / "Lua/limanchel/medical_icons/ui/layouts/medical_icons_static.json"

SCHEMA = "barotrauma-ui-layout/v1"

NODE_TYPES = {
    "Button",
    "DropDown",
    "Frame",
    "Image",
    "LayoutGroup",
    "ListBox",
    "ScissorComponent",
    "ScrollBar",
    "TextBlock",
    "TickBox",
}

COMMON_FIELDS = {
    "absoluteOffset",
    "anchor",
    "canBeFocused",
    "children",
    "color",
    "fixedSize",
    "hoverColor",
    "id",
    "pivot",
    "selectedColor",
    "size",
    "style",
    "type",
}

TYPE_FIELDS = {
    "Button": {"text"},
    "DropDown": {"maxVisibleItems"},
    "Frame": set(),
    "Image": {"path", "scaleToFit", "sourceRect"},
    "LayoutGroup": {"absoluteSpacing", "childAnchor", "direction", "relativeSpacing", "stretch"},
    "ListBox": {"autoHideScrollBar", "isHorizontal", "keepSpaceForScrollBar", "spacing"},
    "ScissorComponent": set(),
    "ScrollBar": {"barSize", "range", "step"},
    "TextBlock": {"alignment", "text", "textColor", "textScale"},
    "TickBox": {"text"},
}

BANNED_FIELDS = {
    "action",
    "binding",
    "enabled",
    "items",
    "onClick",
    "openUrl",
    "placeholder",
    "selected",
    "value",
    "visible",
}

RUNTIME_PATTERNS = {
    "assets/texturepacks": "runtime texture atlas path",
    "assets/overlaypacks": "runtime overlay atlas path",
    "workspace/in": "workbench-local path",
    "D:/": "absolute Windows path",
    "\\u": "unicode escape not accepted by LuaCs json parser",
}


class ValidationError(Exception):
    pass


def parse_args() -> Any:
    parser = ArgumentParser(
        description="Validate strict Barotrauma UI layout JSON files for ui_runtime."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[DEFAULT_LAYOUT],
        help="Layout JSON file(s) to validate. Defaults to the Medical Icons static layout.",
    )
    parser.add_argument(
        "--allow-runtime-assets",
        action="store_true",
        help="Allow assets/texturepacks and assets/overlaypacks paths in JSON.",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Only print errors.",
    )
    return parser.parse_args()


def fail(path: str, message: str) -> None:
    raise ValidationError(f"{path}: {message}")


def is_number_pair(value: Any) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 2
        and isinstance(value[0], (int, float))
        and isinstance(value[1], (int, float))
    )


def is_color(value: Any) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 4
        and all(isinstance(item, (int, float)) for item in value)
    )


def validate_node(node: Any, path: str) -> None:
    if not isinstance(node, dict):
        fail(path, "node must be an object")

    node_type = node.get("type")
    if not isinstance(node_type, str) or node_type not in NODE_TYPES:
        fail(path, "unknown or missing type")

    node_id = node.get("id")
    if not isinstance(node_id, str) or node_id == "":
        fail(path, "missing id")

    allowed_fields = COMMON_FIELDS | TYPE_FIELDS[node_type]
    for key in node:
        if key in BANNED_FIELDS:
            fail(path, f"dynamic field is not allowed: {key}")
        if key not in allowed_fields:
            fail(path, f"unknown field: {key}")

    if "size" in node and "fixedSize" in node:
        fail(path, "use size or fixedSize, not both")
    if "size" in node and not is_number_pair(node["size"]):
        fail(path, "size must be [number, number]")
    if "fixedSize" in node and not is_number_pair(node["fixedSize"]):
        fail(path, "fixedSize must be [number, number]")
    if "absoluteOffset" in node and not is_number_pair(node["absoluteOffset"]):
        fail(path, "absoluteOffset must be [number, number]")
    if "range" in node and not is_number_pair(node["range"]):
        fail(path, "range must be [number, number]")

    for field in ("color", "hoverColor", "selectedColor", "textColor"):
        if field in node and not is_color(node[field]):
            fail(path, f"{field} must be [r, g, b, a]")

    children = node.get("children", [])
    if not isinstance(children, list):
        fail(path, "children must be an array")

    child_ids: set[str] = set()
    for index, child in enumerate(children, start=1):
        if not isinstance(child, dict):
            fail(f"{path}.children[{index}]", "child must be an object")
        child_id = child.get("id")
        if isinstance(child_id, str):
            if child_id in child_ids:
                fail(path, f"duplicate child id: {child_id}")
            child_ids.add(child_id)
        validate_node(child, f"{path}.{child_id or index}")


def validate_layout(value: Any) -> None:
    if not isinstance(value, dict):
        fail("$", "layout must be an object")
    if value.get("schema") != SCHEMA:
        fail("$", f"schema must be {SCHEMA}")

    allowed_top_level = {"schema", "root", "templates"}
    for key in value:
        if key not in allowed_top_level:
            fail("$", f"unknown top-level field: {key}")

    validate_node(value.get("root"), "$.root")

    templates = value.get("templates", {})
    if not isinstance(templates, dict):
        fail("$.templates", "templates must be an object")
    for name, template in templates.items():
        if not isinstance(name, str) or name == "":
            fail("$.templates", "template name must be a non-empty string")
        validate_node(template, f"$.templates.{name}")


def validate_text_content(content: str, allow_runtime_assets: bool) -> list[str]:
    warnings = []
    for pattern, reason in RUNTIME_PATTERNS.items():
        if allow_runtime_assets and pattern in {"assets/texturepacks", "assets/overlaypacks"}:
            continue
        if pattern in content:
            warnings.append(f"contains {reason}: {pattern}")
    return warnings


def validate_file(path: Path, allow_runtime_assets: bool) -> list[str]:
    try:
        content = path.read_text(encoding="utf-8-sig")
    except OSError as exc:
        raise ValidationError(f"{path}: read failed: {exc}") from exc

    try:
        value = json.loads(content)
    except JSONDecodeError as exc:
        raise ValidationError(f"{path}: json parse failed: {exc}") from exc

    validate_layout(value)
    return validate_text_content(content, allow_runtime_assets)


def main() -> int:
    args = parse_args()
    had_warnings = False

    for raw_path in args.paths:
        path = raw_path if raw_path.is_absolute() else PROJECT_ROOT / raw_path
        try:
            warnings = validate_file(path, args.allow_runtime_assets)
        except ValidationError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1

        if warnings:
            had_warnings = True
            for warning in warnings:
                print(f"WARNING: {path.relative_to(PROJECT_ROOT)}: {warning}", file=sys.stderr)

        if not args.quiet:
            print(f"OK: {path.relative_to(PROJECT_ROOT)}")

    return 2 if had_warnings else 0


if __name__ == "__main__":
    raise SystemExit(main())
