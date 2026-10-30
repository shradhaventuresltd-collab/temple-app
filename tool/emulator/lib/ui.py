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


def cmd_chip_bar(args: argparse.Namespace) -> int:
    """Print the chip scroller's usable span: left right cy signature.

    The scroller is the row of filter-chip-* nodes. filter-clear is pinned
    outside it (#123), so the span stops at its left edge. A swipe that
    starts on that button, or past the drawer's edge, never scrolls the
    row, and in the drawer it closes the drawer instead.
    The signature lists each visible chip id with its x1, so a caller can
    tell whether a swipe actually moved the row.
    """
    try:
        root = _load(args.dump)
    except (ET.ParseError, OSError, ValueError) as exc:
        print(f"dump unreadable: {exc}", file=sys.stderr)
        return 1
    chips = []
    pinned = None
    for node in _iter_nodes(root):
        short = _resource_id(node).split("/")[-1]
        box = _bounds(node.attrib.get("bounds", ""))
        if box is None:
            continue
        if args.max_top is not None and box[1] > args.max_top:
            continue
        if short == "filter-clear":
            pinned = box
        elif short.startswith("filter-chip-"):
            chips.append((short, box))
    if not chips:
        return 1
    # The row is the band of the first chip. Ignore chips on other rows.
    _, first = chips[0]
    cy = (first[1] + first[3]) // 2
    row = [(n, b) for n, b in chips if b[1] <= cy <= b[3]]
    left = min(b[0] for _, b in row)
    right = max(b[2] for _, b in row)
    if pinned is not None and pinned[1] <= cy <= pinned[3] and pinned[0] > left:
        right = min(right, pinned[0])
    # Stay off both edges so the finger lands on the scroller itself.
    left += 6
    right -= 6
    if right - left < 24:
        return 1
    sig = ",".join(f"{n}@{b[0]}" for n, b in row)
    print(f"{left} {right} {cy} {sig}")
    return 0


_KINDS = ("state", "district", "deity")
_HEADERS = {"STATE": "state", "DISTRICT": "district", "DEITY": "deity"}


def _dart_key(value: str) -> bytes:
    # directoryStatesFrom, directoryDeitiesFrom, and directoryDistrictsFrom
    # (lib/utils/directory_filters.dart) sort with Dart's List.sort, and
    # String.compareTo orders UTF-16 code units. Python's code-point order
    # disagrees for non-BMP names, so compare UTF-16 code units here too.
    return value.encode("utf-16-be")


def _sheet_rows(root: ET.Element) -> list[tuple[str, str, tuple[int, int, int, int], ET.Element]]:
    """Visible option chips and section headers, top to bottom.

    Each row is (kind, name, bounds, node). A section header has name "".
    The sheet's chips carry resource-id filter-option-<kind>-<name>; the
    headers are plain Views whose content-desc is STATE, DISTRICT or DEITY.
    """
    rows = []
    for node in _iter_nodes(root):
        box = _bounds(node.attrib.get("bounds", ""))
        if box is None:
            continue
        short = _resource_id(node).split("/")[-1]
        kind = name = None
        for k in _KINDS:
            prefix = f"filter-option-{k}-"
            if short.startswith(prefix):
                kind, name = k, short[len(prefix):]
                break
        if kind is None:
            label = _flat(node.attrib.get("content-desc")) or _flat(node.attrib.get("text"))
            if label in _HEADERS and not short:
                kind, name = _HEADERS[label], ""
        if kind is not None:
            rows.append((kind, name, box, node))
    rows.sort(key=lambda row: (row[2][1], row[2][0]))
    return rows


def cmd_sheet_kinds(args: argparse.Namespace) -> int:
    """Print the picker sections visible in a dump, top to bottom, one line.

    The sheet opens scrolled to the top with the tapped section first
    (_sections in lib/widgets/directory_filter_bar.dart), so the first kind
    of the first dump is the section order's head.
    """
    try:
        root = _load(args.dump)
    except (ET.ParseError, OSError, ValueError) as exc:
        print(f"dump unreadable: {exc}", file=sys.stderr)
        return 1
    seen: list[str] = []
    for kind, _name, _box, _node in _sheet_rows(root):
        if kind not in seen:
            seen.append(kind)
    if not seen:
        return 1
    print(" ".join(seen))
    return 0


def _letter_gap(a: str, b: str) -> int:
    first_a = (a[:1] or " ").upper()
    first_b = (b[:1] or " ").upper()
    return abs(ord(first_a) - ord(first_b))


def cmd_option_seek(args: argparse.Namespace) -> int:
    """Say where option NAME of a sorted picker section is.

    The sheet lists every section in one scroller: the tapped section first,
    then state, district, deity (DirectoryFilterSheet._sections). Each
    section is in Dart's default String order and every chip carries
    resource-id filter-option-<kind>-<name>. Run 40916686359 failed 60+
    picks because a fling from the top of STATE landed in DISTRICT or DEITY,
    where no state chip is visible; the old answer was "none" and the
    caller gave up. With --order the answer is the section's direction.

    Prints one of:
      tap CX CY TEXT   the option is inside [min-top, max-top]
      up far|near      it is below the screen (scroll the list up)
      down far|near    it is above the screen (scroll the list down)
      absent           visible names bracket NAME but it is not listed
      none             no picker option or section header is on screen
    "far" means a full fling is safe (another section, or two or more
    initial letters away in a long section); "mid" a short fling (next
    initial, or the first differing letter 3+ away); "near" means
    step without momentum. STATE (36 options) is always "near".
    """
    try:
        root = _load(args.dump)
    except (ET.ParseError, OSError, ValueError) as exc:
        print(f"dump unreadable: {exc}", file=sys.stderr)
        return 1
    order = [k for k in (args.order or "").split(",") if k]
    for k in _KINDS:
        if k not in order:
            order.append(k)
    rows = _sheet_rows(root)
    names = []
    header_here = False
    other_kinds = []
    for kind, name, box, node in rows:
        if kind != args.kind:
            other_kinds.append(kind)
            continue
        if not name:
            header_here = True
            continue
        if name == "any":
            names.append(("", box))
            continue
        if name == args.name or (args.prefix and name.startswith(args.name)):
            x1, y1, x2, y2 = box
            if args.min_top is not None and y1 < args.min_top:
                print("down near")
                return 0
            if args.max_top is not None and y1 > args.max_top:
                print("up near")
                return 0
            text = " ".join(_flat(node.attrib.get("content-desc")).split()) \
                or " ".join(_flat(node.attrib.get("text")).split()) or name
            print(f"tap {(x1 + x2) // 2} {(y1 + y2) // 2} {text}")
            return 0
        names.append((name, box))
    real = [n for n, _ in names if n]
    if real:
        target = _dart_key(args.name)
        hi = max(real, key=_dart_key)
        lo = min(real, key=_dart_key)
        # A short section (state) never needs a fling; a fling there lands
        # in the next section (run 40916686359, flows 29a/29d/29g/30a).
        def reach(edge: str) -> str:
            if args.kind == "state":
                return "near"
            if _letter_gap(args.name, edge) >= 2:
                return "far"
            if _letter_gap(args.name, edge) == 1:
                return "mid"
            # Same initial: look at the first letter that differs.
            a, b = args.name.upper(), edge.upper()
            i = 0
            while i < min(len(a), len(b)) and a[i] == b[i]:
                i += 1
            if i < min(len(a), len(b)) and abs(ord(a[i]) - ord(b[i])) >= 3:
                return "mid"
            # NAME is a strict prefix of the edge ("Shiva" vs "Shiva
            # (Baneswar)"): every "Shiva (...)" row lies between them, and
            # the live list has dozens (run 40992967143 crept through them
            # one slow drag at a time until the 45s ran out).
            # Rows sort by what follows the prefix, so measure from "A":
            # "Shiva (Baneswar)" is a few rows past Shiva, "Shiva (Somnath)"
            # dozens.
            if i == len(a) < len(b):
                rest = [c for c in b[i:] if c.isalpha()]
                if rest and ord(rest[0]) - ord("A") >= 3:
                    return "mid"
            return "near"
        mine = order.index(args.kind)
        mine_ys = [b[1] for n, b in names if n]
        # Another section's rows right after ours (or before) on screen
        # close the section: the name would sit between them.
        later_below = any(
            k != args.kind and order.index(k) > mine and b[1] > max(mine_ys)
            for k, _n, b, _node in rows
        )
        earlier_above = any(
            k != args.kind and order.index(k) < mine and b[1] < min(mine_ys)
            for k, _n, b, _node in rows
        )
        if target > _dart_key(hi):
            print("absent" if later_below else f"up {reach(hi)}")
        elif target < _dart_key(lo):
            print("absent" if earlier_above else f"down {reach(lo)}")
        else:
            print("absent")
        return 0
    if names:
        # Only the any/all chip: the section head. Every name is below it.
        print("up near")
        return 0
    if other_kinds:
        mine = order.index(args.kind)
        before = any(order.index(k) < mine for k in other_kinds)
        after = any(order.index(k) > mine for k in other_kinds)
        reach = "near" if header_here else "far"
        if before and not after:
            print(f"up {reach}")
            return 0
        if after and not before:
            print(f"down {reach}")
            return 0
        # Sections on both sides with none of ours between: it is empty.
        print("absent")
        return 0
    if header_here:
        print("up near")
        return 0
    print("none")
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

    bar = sub.add_parser("chip-bar")
    bar.add_argument("dump")
    bar.add_argument("--max-top", type=int)
    bar.set_defaults(func=cmd_chip_bar)

    seek = sub.add_parser("option-seek")
    seek.add_argument("dump")
    seek.add_argument("--kind", required=True)
    seek.add_argument("--name", required=True)
    seek.add_argument("--min-top", type=int)
    seek.add_argument("--max-top", type=int)
    seek.add_argument("--prefix", action="store_true", help="any option whose name starts with NAME")
    seek.add_argument("--order", default="", help="section kinds top to bottom, e.g. state,district,deity")
    seek.set_defaults(func=cmd_option_seek)

    kinds = sub.add_parser("sheet-kinds")
    kinds.add_argument("dump")
    kinds.set_defaults(func=cmd_sheet_kinds)

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
