#!/usr/bin/env python3
import struct
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
SOURCE_PATH = ROOT / "Resources" / "AppIcon.png"
OUTPUT_PATH = ROOT / "Resources" / "AppIcon.icns"


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def make_small_icon(size):
    scale = size / 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if size <= 16:
        draw = ImageDraw.Draw(img)
        rounded(draw, [1, 1, size - 2, size - 2], 3, (24, 27, 31, 255), (79, 87, 96, 255))
        draw.rectangle([3, 6, 4, 7], fill=(57, 227, 214, 255))
        draw.rounded_rectangle([7, 5, 13, 7], radius=1, fill=(128, 255, 37, 255))
        draw.rounded_rectangle([7, 9, 13, 11], radius=1, fill=(128, 255, 37, 255))
        return img

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)

    def p(value):
        return int(round(value * scale))

    outer = [p(5), p(5), size - p(5), size - p(5)]
    shadow_box = [outer[0], outer[1] + p(2), outer[2], outer[3] + p(2)]
    rounded(shadow_draw, shadow_box, p(14), (0, 0, 0, 145))
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(0.5, 2 * scale)))
    img.alpha_composite(shadow)

    draw = ImageDraw.Draw(img)
    rounded(draw, outer, p(14), (24, 27, 31, 255), (79, 87, 96, 255), max(1, p(1.4)))

    panel = [p(10), p(19), size - p(10), size - p(14)]
    rounded(draw, panel, p(10), (5, 7, 9, 255), (87, 94, 103, 255), max(1, p(1)))

    dot_radius = max(1, p(3))
    dot_center = (p(18), p(31))
    dot = [
        dot_center[0] - dot_radius,
        dot_center[1] - dot_radius,
        dot_center[0] + dot_radius,
        dot_center[1] + dot_radius,
    ]
    draw.ellipse(dot, fill=(57, 227, 214, 255))

    bar_start = p(27)
    bar_end = size - p(15)
    bar_height = max(2, p(5))
    rows = [p(26), p(36)]
    segment_gap = max(1, p(2))
    segment_count = 4 if size <= 16 else 5
    segment_width = max(2, (bar_end - bar_start - segment_gap * (segment_count - 1)) // segment_count)

    for row_y in rows:
        track = [bar_start - p(2), row_y - p(2), bar_end + p(2), row_y + bar_height + p(2)]
        rounded(draw, track, max(2, p(4)), (14, 17, 19, 255), (92, 102, 112, 255), max(1, p(1)))
        x = bar_start
        for _ in range(segment_count):
            seg = [x, row_y, x + segment_width, row_y + bar_height]
            rounded(draw, seg, max(1, p(2)), (128, 255, 37, 255))
            x += segment_width + segment_gap

    return img


def resize_source(size):
    source = Image.open(SOURCE_PATH).convert("RGBA")
    return source.resize((size, size), Image.Resampling.LANCZOS)


def write_icns(png_entries):
    chunks = []
    for code, image in png_entries:
        with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
            image.save(tmp.name, "PNG", optimize=True)
            chunks.append((code.encode("ascii"), Path(tmp.name).read_bytes()))

    total_length = 8 + sum(8 + len(data) for _, data in chunks)
    with OUTPUT_PATH.open("wb") as output:
        output.write(b"icns")
        output.write(struct.pack(">I", total_length))
        for code, data in chunks:
            output.write(code)
            output.write(struct.pack(">I", 8 + len(data)))
            output.write(data)


def main():
    entries = [
        ("icp4", make_small_icon(16)),
        ("icp5", make_small_icon(32)),
        ("icp6", make_small_icon(64)),
        ("ic07", resize_source(128)),
        ("ic08", resize_source(256)),
        ("ic09", resize_source(512)),
        ("ic10", resize_source(1024)),
    ]
    write_icns(entries)
    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
