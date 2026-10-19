#!/usr/bin/env python3
"""Find a tap point in a uiautomator dump.

Flutter exposes Semantics identifiers as resource-id and widget text as
text or content-desc. The smallest matching node wins so a chip is
preferred over a paragraph that merely contains the same word.
"""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET


def _bounds(raw: str) -> tuple[int, int, int, int] | None:
    # [x1,y1][x2,y2]
    try:
        left, rest = raw.split("][", 1)
        x1s, y1s = left[1:].split(",")
        x2s, y2s = rest[:-1].split(",")
        x1, y1, x2, y2 = int(x1s), int(y1s), int(x2s), int(y2s)
    except (ValueError, IndexError):
        return None
    if x2 <= x1 or y2 <= y1:
        return None
    return x1, y1, x2, y2


def _score(node: ET.Element, needle: str) -> int | None:
    text = (node.attrib.get("text") or "").strip()
    desc = (node.attrib.get("content-desc") or "").strip()
    rid = (node.attrib.get("resource-id") or "").strip()
    low_text = text.lower()
    low_desc = desc.lower()
    low_rid = rid.lower()
    low = needle.lower()
    if low_text == low:
        return 0
    if low_text.startswith(low + " ") or low_text.startswith(low + "\n"):
        return 1
    if low_desc == low:
        return 2
    rid_tail = low_rid.rsplit("/", 1)[-1]
    if rid_tail == low or low_rid == low:
        return 3
    if low_text.startswith(low):
        return 4
    if low in low_text:
        return 5
    if low in low_desc:
        return 6
    if low in low_rid:
        return 7
    return None


def find_tap(path: str, needle: str) -> tuple[int, int] | None:
    try:
        tree = ET.parse(path)
    except ET.ParseError:
        return None
    best: tuple[int, int, int, int] | None = None
    for node in tree.iter("node"):
        score = _score(node, needle)
        if score is None:
            continue
        box = _bounds(node.attrib.get("bounds", ""))
        if box is None:
            continue
        x1, y1, x2, y2 = box
        area = (x2 - x1) * (y2 - y1)
        cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
        if cx < 0 or cy < 0 or cx > 1400 or cy > 2800:
            continue
        rank = (score, area, cx, cy)
        if best is None or rank < best:
            best = rank
    if best is None:
        return None
    return best[2], best[3]


def main(argv: list[str]) -> int:
    if len(argv) != 4 or argv[1] not in {"find", "has"}:
        print("usage: demo_ui.py find|has DUMP.xml NEEDLE", file=sys.stderr)
        return 2
    hit = find_tap(argv[2], argv[3])
    if hit is None:
        return 1
    if argv[1] == "find":
        print(f"{hit[0]} {hit[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
