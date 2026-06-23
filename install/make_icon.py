"""Generate install/icon.ico (a simple Markdown-document icon) using only the
Python standard library. Produces 16x16, 32x32 and 48x48 32-bit BGRA images
packed into a single .ico. Run once: `python make_icon.py`."""

import os
import struct

# Palette (R, G, B)
PAGE = (255, 255, 255)
PAGE_EDGE = (208, 215, 222)
ACCENT = (9, 105, 218)      # GitHub blue header bar
LINE = (175, 184, 193)      # grey text lines


def render(size):
    """Return a list of (r, g, b, a) pixels, row-major top-to-bottom."""
    px = [(0, 0, 0, 0)] * (size * size)

    def put(x, y, rgb, a=255):
        if 0 <= x < size and 0 <= y < size:
            px[y * size + x] = (rgb[0], rgb[1], rgb[2], a)

    s = size / 32.0
    left = round(6 * s)
    right = round(26 * s)
    top = round(3 * s)
    bottom = round(29 * s)

    # Page body + 1px edge.
    for y in range(top, bottom):
        for x in range(left, right):
            edge = x in (left, right - 1) or y in (top, bottom - 1)
            put(x, y, PAGE_EDGE if edge else PAGE)

    # Accent header bar.
    bar_bottom = round(10 * s)
    for y in range(top + 1, bar_bottom):
        for x in range(left + 1, right - 1):
            put(x, y, ACCENT)

    # Text lines.
    line_x0 = left + max(1, round(2 * s))
    line_x1 = right - max(1, round(2 * s))
    for i in range(3):
        ly = round((14 + i * 4) * s)
        x1 = line_x1 if i < 2 else (line_x0 + (line_x1 - line_x0) // 2)
        for x in range(line_x0, x1):
            put(x, ly, LINE)
            put(x, ly + 1 if 1 * s >= 1.5 else ly, LINE)

    return px


def ico_image(size):
    """Build one BITMAPINFOHEADER DIB (XOR BGRA + AND mask) for the .ico."""
    px = render(size)

    # XOR data: bottom-up rows, BGRA.
    xor = bytearray()
    for y in range(size - 1, -1, -1):
        for x in range(size):
            r, g, b, a = px[y * size + x]
            xor += bytes((b, g, r, a))

    # AND mask: 1 bpp, rows padded to 32-bit boundary, bottom-up.
    row_bytes = ((size + 31) // 32) * 4
    and_mask = bytearray()
    for y in range(size - 1, -1, -1):
        bits = bytearray(row_bytes)
        for x in range(size):
            a = px[y * size + x][3]
            if a == 0:  # transparent -> mask bit set
                bits[x // 8] |= 0x80 >> (x % 8)
        and_mask += bits

    header = struct.pack(
        "<IiiHHIIiiII",
        40,            # biSize
        size,          # biWidth
        size * 2,      # biHeight (XOR + AND)
        1,             # biPlanes
        32,            # biBitCount
        0,             # biCompression
        len(xor) + len(and_mask),
        0, 0, 0, 0,
    )
    return bytes(header) + bytes(xor) + bytes(and_mask)


def build(path, sizes=(16, 32, 48)):
    images = [ico_image(s) for s in sizes]

    out = bytearray()
    out += struct.pack("<HHH", 0, 1, len(images))  # ICONDIR

    offset = 6 + 16 * len(images)
    for s, data in zip(sizes, images):
        out += struct.pack(
            "<BBBBHHII",
            s if s < 256 else 0,
            s if s < 256 else 0,
            0, 0,
            1, 32,
            len(data),
            offset,
        )
        offset += len(data)

    for data in images:
        out += data

    with open(path, "wb") as f:
        f.write(out)
    print(f"wrote {path} ({len(out)} bytes)")


if __name__ == "__main__":
    target = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.ico")
    build(target)
