#!/usr/bin/env python3
"""Remove the empty black band from a Questa Wave window export.

Keeps the signal rows at the top and the time axis + cursor bar at the bottom,
drops the empty space in between. Accepts PNG or BMP; always writes PNG.

usage: python3 crop_wave.py <in_image> [<in_image> ...] --out <dir>
needs: Pillow  (pip install pillow)
"""
import sys, os
from PIL import Image


def is_ink(p):
    """Coloured or bright pixel = waveform/text; black background and grey grid lines are not."""
    r, g, b = p
    grey = abs(r - g) < 12 and abs(g - b) < 12 and r < 200
    return (r + g + b) > 300 and not grey


def crop(path, outdir):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    px = im.load()
    rows = [y for y in range(H)
            if sum(1 for x in range(320, W - 30, 2) if is_ink(px[x, y])) > 3]
    segs, s, p = [], rows[0], rows[0]
    for y in rows[1:]:
        if y > p + 20:
            segs.append((s, p))
            s = y
        p = y
    segs.append((s, p))
    if len(segs) < 2:
        print(f"{path}: no empty band found, copied unchanged")
        out = im
    else:
        last_signal = segs[-2][1] + 14   # bottom of the last signal row
        bottom_start = segs[-1][0] - 6   # top of the time axis / cursor bar
        top = im.crop((0, 0, W, last_signal))
        bot = im.crop((0, bottom_start, W, H))
        out = Image.new("RGB", (W, top.height + bot.height))
        out.paste(top, (0, 0))
        out.paste(bot, (0, top.height))
    name = os.path.splitext(os.path.basename(path))[0]
    if name.endswith("bmp"):             # Questa export typed without a dot: "W1_xxxbmp"
        name = name[:-3]
    dst = os.path.join(outdir, name + ".png")
    out.save(dst)
    print(f"{path} {im.size} -> {dst} {out.size}")


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--out" not in args or args.index("--out") == len(args) - 1:
        sys.exit(__doc__)
    i = args.index("--out")
    outdir, files = args[i + 1], args[:i] + args[i + 2:]
    os.makedirs(outdir, exist_ok=True)
    for f in files:
        crop(f, outdir)
