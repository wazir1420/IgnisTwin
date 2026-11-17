#!/usr/bin/env python3
"""
IgnisTwin app icon generator — koi external library nahi (sirf zlib/struct).

Banata hai:
  assets/icon/icon.png             1024x1024  (Android + iOS ke liye, dark bg)
  assets/icon/icon_foreground.png  1024x1024  (adaptive icon foreground, transparent)

Design: dark rounded look + cyan shield outline + orange/red flame — wahi
iconography jo app ki splash screen par hai.
"""

import math
import os
import struct
import zlib

# ---------- render settings ----------
R = 512          # render resolution (baad mein 2x upscale)
SS = 2           # supersampling (anti-aliasing)
FINAL = 1024

# ---------- colors ----------
BG_TOP = (10, 15, 21)
BG_BOTTOM = (18, 26, 34)
GLOW = (26, 62, 78)
CYAN = (64, 200, 232)
FLAME_TOP = (242, 174, 72)
FLAME_BOTTOM = (239, 51, 64)


# ---------- geometry (normalized 0..1) ----------
def shield_outline():
    """Shield ki outline polyline."""
    L, Rt = 0.28, 0.72
    top, side_end, tip_y = 0.205, 0.545, 0.835
    ctrl_y = 0.745
    r = 0.05
    pts = [(L + r, top), (Rt - r, top)]
    # top-right rounded corner (right side ki taraf)
    for i in range(1, 6):
        a = (math.pi / 2) * i / 5
        pts.append((Rt - r + r * math.sin(a), top + r - r * math.cos(a)))
    pts.append((Rt, side_end))
    for i in range(1, 21):                       # right curve -> tip
        t = i / 20
        x = (1 - t) ** 2 * Rt + 2 * (1 - t) * t * Rt + t ** 2 * 0.5
        y = (1 - t) ** 2 * side_end + 2 * (1 - t) * t * ctrl_y + t ** 2 * tip_y
        pts.append((x, y))
    for i in range(19, -1, -1):                  # left curve -> back up
        t = i / 20
        x = (1 - t) ** 2 * L + 2 * (1 - t) * t * L + t ** 2 * 0.5
        y = (1 - t) ** 2 * side_end + 2 * (1 - t) * t * ctrl_y + t ** 2 * tip_y
        pts.append((x, y))
    pts.append((L, side_end))
    pts.append((L, top + r))
    # top-left rounded corner (wapas top edge par)
    for i in range(1, 6):
        a = (math.pi / 2) * i / 5
        pts.append((L + r - r * math.cos(a), top + r - r * math.sin(a)))
    return pts


def flame_polygon():
    """Flame ka filled polygon (tip oopar, neeche gol)."""
    pts = [(0.5, 0.315)]
    # right side: tip -> (0.605, 0.635)
    for i in range(1, 15):
        t = i / 14
        x = (1 - t) ** 2 * 0.5 + 2 * (1 - t) * t * 0.645 + t ** 2 * 0.605
        y = (1 - t) ** 2 * 0.315 + 2 * (1 - t) * t * 0.475 + t ** 2 * 0.635
        pts.append((x, y))
    # bottom arc
    for i in range(0, 19):
        a = math.pi * i / 18
        pts.append((0.5 + 0.105 * math.cos(a), 0.635 + 0.098 * math.sin(a)))
    # left side back to tip
    for i in range(13, 0, -1):
        t = i / 14
        x = (1 - t) ** 2 * 0.5 + 2 * (1 - t) * t * 0.355 + t ** 2 * 0.395
        y = (1 - t) ** 2 * 0.315 + 2 * (1 - t) * t * 0.475 + t ** 2 * 0.635
        pts.append((x, y))
    return pts


def inside_poly(x, y, poly):
    """Ray-casting point-in-polygon."""
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi:
            inside = not inside
        j = i
    return inside


def dist_to_polyline(x, y, pts):
    """Polyline se doori — closed shape, aakhri point pehle se juda hai."""
    best = 1e9
    n = len(pts)
    for i in range(n):
        ax, ay = pts[i]
        bx, by = pts[(i + 1) % n]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / L2))
        px, py = ax + t * dx, ay + t * dy
        d = math.hypot(x - px, y - py)
        if d < best:
            best = d
    return best


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def render(with_bg=True, scale=1.0, shift_y=0.0):
    """RGBA buffer (R x R) float list."""
    shield = shield_outline()
    flame = flame_polygon()
    stroke = 0.052                       # shield line thickness

    def tx(v):
        return (v - 0.5) * scale + 0.5

    def ty(v):
        return (v - 0.5) * scale + 0.5 + shift_y

    buf = []
    for py in range(R):
        row = []
        for px in range(R):
            # background (sirf legacy icon mein)
            if with_bg:
                ny = py / (R - 1)
                base = lerp(BG_TOP, BG_BOTTOM, ny)
                d = math.hypot(px / R - 0.5, py / R - 0.44)
                g = max(0.0, 1.0 - d / 0.62) ** 2 * 0.85
                bg = lerp(base, GLOW, g)
            else:
                bg = (0, 0, 0)

            shield_cov = 0.0
            flame_cov = 0.0
            for sy in range(SS):
                for sx in range(SS):
                    x = tx((px + (sx + 0.5) / SS) / R)
                    y = ty((py + (sy + 0.5) / SS) / R)
                    if dist_to_polyline(x, y, shield) <= stroke / 2:
                        shield_cov += 1
                    if inside_poly(x, y, flame):
                        flame_cov += 1
            n = SS * SS
            shield_cov /= n
            flame_cov /= n

            col = bg
            # flame pehle (shield line ke neeche), phir shield outline
            if flame_cov > 0:
                fc = lerp(FLAME_TOP, FLAME_BOTTOM, min(1.0, max(0.0, (py / R - 0.3) / 0.45)))
                col = lerp(col, fc, flame_cov)
            if shield_cov > 0:
                col = lerp(col, CYAN, shield_cov)

            alpha = 255
            if not with_bg:
                alpha = int(255 * max(shield_cov, flame_cov))
            row.append((int(col[0]), int(col[1]), int(col[2]), alpha))
        buf.append(row)
    return buf


def upscale(buf, factor=2):
    """Bilinear upscale."""
    h = len(buf)
    w = len(buf[0])
    out = []
    for y in range(h * factor):
        row = []
        sy = (y + 0.5) / factor - 0.5
        y0 = max(0, min(h - 1, int(math.floor(sy))))
        y1 = min(h - 1, y0 + 1)
        fy = max(0.0, min(1.0, sy - y0))
        for x in range(w * factor):
            sx = (x + 0.5) / factor - 0.5
            x0 = max(0, min(w - 1, int(math.floor(sx))))
            x1 = min(w - 1, x0 + 1)
            fx = max(0.0, min(1.0, sx - x0))
            p = []
            for c in range(4):
                top = buf[y0][x0][c] * (1 - fx) + buf[y0][x1][c] * fx
                bot = buf[y1][x0][c] * (1 - fx) + buf[y1][x1][c] * fx
                p.append(int(round(top * (1 - fy) + bot * fy)))
            row.append(tuple(p))
        out.append(row)
    return out


def write_png(path, pixels):
    h = len(pixels)
    w = len(pixels[0])
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in pixels)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)
    print(f"  -> {path} ({w}x{h})")


def main():
    out_dir = os.path.join("assets", "icon")
    os.makedirs(out_dir, exist_ok=True)

    print("Legacy icon (dark bg + logo)...")
    write_png(os.path.join(out_dir, "icon.png"), upscale(render(with_bg=True)))

    print("Adaptive foreground (transparent, logo 74% + safe padding)...")
    write_png(
        os.path.join(out_dir, "icon_foreground.png"),
        upscale(render(with_bg=False, scale=0.74)),
    )


if __name__ == "__main__":
    main()
