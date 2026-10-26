#!/usr/bin/env python3
"""Query a uiautomator dump. Prints one match line or exits 1.

Match line: cx cy x1 y1 x2 y2 <visible text>
Coordinates come from the node's bounds. Callers tap those, not a fixed pixel.
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET

_BOUNDS = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def _bounds(raw: str) -> tuple[int, int, int, int] | None:
    match = _BOUNDS.match(raw or "")
    if not match:
        return None
    x1, y1, x2, y2 = (int(part) for part in match.groups())
    if x2 <= x1 or y2 <= y1:
        return None
    return x1, y1, x2, y2


def _flat(value: str | None) -> str:
    """Collapse newlines and repeated spaces so a multi-line label matches a substring."""
    return " ".join((value or "").split())


def _own_bits(node: ET.Element) -> list[str]:
    bits = []
    for key in ("text", "content-desc"):
        value = _flat(node.attrib.get(key))
        if value and value not in bits:
            bits.append(value)
    return bits


def _combined(node: ET.Element) -> str:
    parts: list[str] = []

    def walk(current: ET.Element) -> None:
        for bit in _own_bits(current):
            if bit not in parts:
                parts.append(bit)
        for child in list(current):
            walk(child)

    walk(node)
    return " ".join(parts)


def _resource_id(node: ET.Element) -> str:
    return (node.attrib.get("resource-id") or "").strip()


def _id_matches(actual: str, expected: str) -> bool:
    if not expected:
        return True
    if not actual:
        return False
    return actual == expected or actual.endswith("/" + expected)


def _regex_ok(pattern: str | None, haystack: str) -> bool:
    if not pattern:
        return True
    return re.search(pattern, haystack) is not None


def _contains_ok(needle: str | None, haystack: str) -> bool:
    if not needle:
        return True
    return needle in haystack


def _node_matches(node: ET.Element, args: argparse.Namespace, text: str) -> bool:
    resource_id = _resource_id(node)
    content = _flat(node.attrib.get("content-desc"))
    own = _flat(node.attrib.get("text"))
    text = _flat(text)
    package = (node.attrib.get("package") or "").strip()
    clazz = (node.attrib.get("class") or "").strip()
    blob = " ".join(bit for bit in (own, content, text) if bit)

    if args.resource_id and not _id_matches(resource_id, args.resource_id):
        return False
    if args.resource_id_regex:
        short = resource_id.split("/")[-1] if resource_id else ""
        if re.search(args.resource_id_regex, short) is None and re.search(
            args.resource_id_regex, resource_id or ""
        ) is None:
            return False
    if args.package_contains and args.package_contains not in package:
        return False
    if args.class_contains and args.class_contains not in clazz:
        return False
    if args.clickable and node.attrib.get("clickable") != "true":
        return False

    checks = [
        _contains_ok(args.text, own) or _contains_ok(args.text, text),
        _contains_ok(args.text_contains, blob),
        _regex_ok(args.text_regex, own) or _regex_ok(args.text_regex, text),
        _contains_ok(args.content_desc, content),
        _contains_ok(args.content_desc_contains, content),
        _regex_ok(args.content_desc_regex, content),
    ]
    # A criterion that was not set does not constrain. One that was set must hit.
    required = []
    if args.text:
        required.append(_contains_ok(args.text, own) or _contains_ok(args.text, text))
    if args.text_contains:
        required.append(_contains_ok(args.text_contains, blob))
    if args.text_regex:
        required.append(
            _regex_ok(args.text_regex, own) or _regex_ok(args.text_regex, text)
        )
    if args.content_desc:
        required.append(_contains_ok(args.content_desc, content))
    if args.content_desc_contains:
        required.append(_contains_ok(args.content_desc_contains, content))
    if args.content_desc_regex:
        required.append(_regex_ok(args.content_desc_regex, content))
    if (args.resource_id or args.resource_id_regex) and not (
        args.text
        or args.text_contains
        or args.text_regex
        or args.content_desc
        or args.content_desc_contains
        or args.content_desc_regex
    ):
        return True
    if not required:
        return bool(args.package_contains or args.class_contains or args.clickable)
    return all(required) and all(checks)


def _iter_nodes(root: ET.Element):
    for node in root.iter("node"):
        yield node


def _load(path: str) -> ET.Element:
    raw = open(path, "rb").read()
    start = raw.find(b"<")
    if start < 0:
        raise ValueError("dump has no xml")
    return ET.fromstring(raw[start:])


def _candidates(root: ET.Element, args: argparse.Namespace):
    found = []
    for node in _iter_nodes(root):
        box = _bounds(node.attrib.get("bounds", ""))
        if box is None:
            continue
        x1, y1, x2, y2 = box
        if args.min_top is not None and y1 < args.min_top:
            continue
        if args.max_top is not None and y1 > args.max_top:
            continue
        text = _combined(node)
        if not _node_matches(node, args, text):
            continue
        area = (x2 - x1) * (y2 - y1)
        found.append((area, y1, x1, y1, x2, y2, text, node))
    return found


def _choose(found: list, prefer: str):
    if not found:
        return None
    # Smallest area is the most specific node. Ties go up or down the screen.
    found.sort(key=lambda item: (item[0], item[1] if prefer == "upper" else -item[1]))
    return found[0]


def cmd_find(args: argparse.Namespace) -> int:
    try:
        root = _load(args.dump)
    except (ET.ParseError, OSError, ValueError) as exc:
        print(f"dump unreadable: {exc}", file=sys.stderr)
        return 1
    chosen = _choose(_candidates(root, args), args.prefer)
    if chosen is None:
        return 1
    _area, _y, x1, y1, x2, y2, text, _node = chosen
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    visible = " ".join(text.split())
    print(f"{cx} {cy} {x1} {y1} {x2} {y2} {visible}")
    return 0


def cmd_bright(args: argparse.Namespace) -> int:
    """Exit 0 when a screencap is not a black frame.

    A resize leaves the framebuffer black for a moment. Callers wait and
    capture again instead of storing that frame.
    """
    import struct
    import zlib

    data = open(args.path, "rb").read()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        return 1
    pos = 8
    width = height = color = 0
    idat = bytearray()
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, _bit, color = struct.unpack(">IIBB", chunk[:10])
        elif kind == b"IDAT":
            idat.extend(chunk)
        elif kind == b"IEND":
            break
    if width <= 0 or height <= 0:
        return 1
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color)
    if channels is None or channels < 3:
        return 1
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    total = 0
    count = 0
    index = 0
    for y in range(height):
        index += 1
        row = raw[index : index + stride]
        index += stride
        if y % 40:
            continue
        for x in range(0, width, 40):
            pixel = x * channels
            if pixel + 2 >= len(row):
                break
            total += row[pixel] + row[pixel + 1] + row[pixel + 2]
            count += 3
    if count == 0:
        return 1
    mean = total / count
    return 0 if mean >= 12 else 1


def cmd_resource_ids(args: argparse.Namespace) -> int:
    try:
        root = _load(args.dump)
    except (ET.ParseError, OSError, ValueError) as exc:
        print(f"dump unreadable: {exc}", file=sys.stderr)
        return 1
    seen: list[str] = []
    prefix = args.prefix or ""
    for node in _iter_nodes(root):
        resource_id = _resource_id(node)
        if not resource_id:
            continue
        short = resource_id.split("/")[-1]
        if prefix and not short.startswith(prefix):
            continue
        if short not in seen:
            seen.append(short)
    for item in seen:
        print(item)
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    find = sub.add_parser("find")
    find.add_argument("dump")
    find.add_argument("--resource-id", default="")
    find.add_argument("--resource-id-regex", default="")
    find.add_argument("--text", default="")
    find.add_argument("--text-contains", default="")
    find.add_argument("--text-regex", default="")
    find.add_argument("--content-desc", default="")
    find.add_argument("--content-desc-contains", default="")
    find.add_argument("--content-desc-regex", default="")
    find.add_argument("--package-contains", default="")
    find.add_argument("--class-contains", default="")
    find.add_argument("--clickable", action="store_true")
    find.add_argument("--min-top", type=int)
    find.add_argument("--max-top", type=int)
    find.add_argument("--prefer", choices=("upper", "lower"), default="upper")
    find.set_defaults(func=cmd_find)

    ids = sub.add_parser("resource-ids")
    ids.add_argument("dump")
    ids.add_argument("--prefix", default="")
    ids.set_defaults(func=cmd_resource_ids)

    bright = sub.add_parser("bright")
    bright.add_argument("path")
    bright.set_defaults(func=cmd_bright)
    return parser


def main() -> int:
    parser = _parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
