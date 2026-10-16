#!/usr/bin/env python3
"""Classify one tester-checks screencap.

Prints a single PIXELS line. Home mosaic shots are the only ones with a
tile sample: the big top-left collage cell. A flat or cream cell there is
blank. Other screens report tile=skip.
"""

import struct
import sys
import zlib


def main() -> None:
    path, name = sys.argv[1], sys.argv[2]
    try:
        frame, body, tile, std = classify(path, name)
    except Exception as error:  # noqa: BLE001 - one line the summary can read
        kind = type(error).__name__
        print(
            f"PIXELS {name} frame=unknown body=unknown tile=skip "
            f"tile_std=0 error={kind}"
        )
        return
    print(
        f"PIXELS {name} frame={frame} body={body} tile={tile} tile_std={std}"
    )


def classify(path: str, name: str) -> tuple[str, str, str, int]:
    width, height, channels, rows = decode(path)
    dark, _mean, _std = region(rows, channels, 0, width, 0, height, 40)
    frame = "black" if dark >= 0.92 else "content"
    _mid_dark, mid_mean, mid_std = region(
        rows,
        channels,
        int(width * 0.08),
        int(width * 0.92),
        int(height * 0.22),
        int(height * 0.48),
        8,
    )
    # A Browse home frame is the photo mosaic. The loading spinner is cream.
    body = "home" if mid_std >= 45 and mid_mean < 180 else "other"
    mosaic = name.startswith("02-") or name == "03-home-mosaic"
    if not mosaic:
        return frame, body, "skip", 0
    _tile_dark, tile_mean, tile_std = region(
        rows,
        channels,
        int(width * 0.06),
        int(width * 0.58),
        int(height * 0.16),
        int(height * 0.34),
        6,
    )
    blank = tile_std < 18 or (tile_mean > 210 and tile_std < 40)
    return frame, body, "blank" if blank else "photo", round(tile_std)


def region(rows, channels, x0, x1, y0, y1, step):
    values = []
    height = len(rows)
    width = len(rows[0]) // channels if rows else 0
    for y in range(max(0, y0), min(height, y1), step):
        row = rows[y]
        for x in range(max(0, x0), min(width, x1), step):
            offset = x * channels
            red, green, blue = row[offset], row[offset + 1], row[offset + 2]
            values.append((red + green + blue) / 3)
    if not values:
        return 1.0, 0.0, 0.0
    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / len(values)
    dark = sum(value < 16 for value in values) / len(values)
    return dark, mean, variance**0.5


def decode(path: str):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a png")
    pos = 8
    width = height = color = None
    compressed = b""
    while pos + 8 <= len(data):
        length = int.from_bytes(data[pos : pos + 4], "big")
        kind = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height = struct.unpack(">II", chunk[:8])
            color = chunk[9]
            if chunk[12] != 0:
                raise ValueError("interlaced png")
        elif kind == b"IDAT":
            compressed += chunk
        elif kind == b"IEND":
            break
    if width is None or color not in (0, 2, 4, 6):
        raise ValueError("unsupported png")
    channels = {0: 1, 2: 3, 4: 2, 6: 4}[color]
    raw = zlib.decompress(compressed)
    stride = width * channels
    rows = []
    index = 0
    previous = bytearray(stride)

    def paeth(left, up, up_left):
        estimate = left + up - up_left
        left_distance = abs(estimate - left)
        up_distance = abs(estimate - up)
        up_left_distance = abs(estimate - up_left)
        if left_distance <= up_distance and left_distance <= up_left_distance:
            return left
        if up_distance <= up_left_distance:
            return up
        return up_left

    for _y in range(height):
        filter_type = raw[index]
        index += 1
        row = bytearray(raw[index : index + stride])
        index += stride
        if filter_type == 1:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                row[x] = (row[x] + left) & 255
        elif filter_type == 2:
            for x in range(stride):
                row[x] = (row[x] + previous[x]) & 255
        elif filter_type == 3:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                row[x] = (row[x] + ((left + previous[x]) // 2)) & 255
        elif filter_type == 4:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                up = previous[x]
                up_left = previous[x - channels] if x >= channels else 0
                row[x] = (row[x] + paeth(left, up, up_left)) & 255
        elif filter_type != 0:
            raise ValueError(f"filter {filter_type}")
        previous = row
        rows.append(row)
    return width, height, channels, rows


if __name__ == "__main__":
    main()
