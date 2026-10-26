#!/usr/bin/env python3
"""Gera a arte original do canal Saimo TV sem depender de Pillow.

A paleta acompanha o site/apps Saimo: fundo quase preto, violeta, ciano e rosa.
"""
from pathlib import Path
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / "SaimoTV" / "images"

BG = (8, 7, 13)
BG2 = (15, 12, 25)
VIOLET = (139, 92, 246)
LILAC = (167, 139, 250)
TEAL = (79, 227, 208)
PINK = (236, 72, 153)
TEXT = (245, 241, 255)
MUTED = (154, 147, 174)

FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "É": ["00100", "00000", "11111", "10000", "11110", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "0": ["01110", "10011", "10101", "10101", "10101", "11001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "00110", "00110"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    "&": ["01100", "10010", "10100", "01000", "10101", "10010", "01101"],
}


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def save_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride:(y + 1) * stride])
    data = zlib.compress(bytes(raw), 9)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    payload += chunk(b"IDAT", data)
    payload += chunk(b"IEND", b"")
    path.write_bytes(payload)


def paeth(left, above, upper_left):
    prediction = left + above - upper_left
    distances = (abs(prediction - left), abs(prediction - above), abs(prediction - upper_left))
    if distances[0] <= distances[1] and distances[0] <= distances[2]:
        return left
    if distances[1] <= distances[2]:
        return above
    return upper_left


def load_rgba_png(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Invalid PNG signature: {path}")
    width = height = None
    image_data = bytearray()
    offset = 8
    while offset < len(data):
        chunk_size = struct.unpack(">I", data[offset:offset + 4])[0]
        chunk_type = data[offset + 4:offset + 8]
        chunk_data = data[offset + 8:offset + 8 + chunk_size]
        offset += chunk_size + 12
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunk_data)
            if (bit_depth, color_type, compression, filtering, interlace) != (8, 6, 0, 0, 0):
                raise ValueError(f"Unsupported PNG format: {path}")
        elif chunk_type == b"IDAT":
            image_data.extend(chunk_data)
        elif chunk_type == b"IEND":
            break
    if width is None or height is None:
        raise ValueError(f"PNG has no image header: {path}")

    raw = zlib.decompress(image_data)
    stride = width * 4
    pixels = bytearray(height * stride)
    raw_offset = 0
    for y in range(height):
        filter_type = raw[raw_offset]
        raw_offset += 1
        row_offset = y * stride
        for x in range(stride):
            encoded = raw[raw_offset]
            raw_offset += 1
            left = pixels[row_offset + x - 4] if x >= 4 else 0
            above = pixels[row_offset + x - stride] if y > 0 else 0
            upper_left = pixels[row_offset + x - stride - 4] if y > 0 and x >= 4 else 0
            if filter_type == 1:
                encoded += left
            elif filter_type == 2:
                encoded += above
            elif filter_type == 3:
                encoded += (left + above) // 2
            elif filter_type == 4:
                encoded += paeth(left, above, upper_left)
            elif filter_type != 0:
                raise ValueError(f"Unsupported PNG filter {filter_type}: {path}")
            pixels[row_offset + x] = encoded & 255
    return width, height, pixels


def paste_brand_logo(pixels, width, height, size, center_y):
    source_width, source_height, source_pixels = load_rgba_png(IMAGES / "logo.png")
    left = (width - size) // 2
    top = center_y - size // 2
    for y in range(size):
        source_y = min(source_height - 1, y * source_height // size)
        for x in range(size):
            source_x = min(source_width - 1, x * source_width // size)
            index = (source_y * source_width + source_x) * 4
            red, green, blue, alpha = source_pixels[index:index + 4]
            if alpha > 0:
                blend(pixels, width, left + x, top + y, (red, green, blue, alpha), alpha / 255.0)


def canvas(width, height, color=(0, 0, 0, 0)):
    return bytearray(bytes(color) * (width * height))


def blend(pixels, width, x, y, color, alpha=1.0):
    if alpha <= 0:
        return
    if alpha > 1:
        alpha = 1.0
    i = (y * width + x) * 4
    a = pixels[i + 3] / 255.0
    out_a = alpha + a * (1 - alpha)
    if out_a <= 0:
        pixels[i:i + 4] = bytes((0, 0, 0, 0))
        return
    for c in range(3):
        value = (color[c] * alpha + pixels[i + c] * a * (1 - alpha)) / out_a
        pixels[i + c] = max(0, min(255, int(value)))
    pixels[i + 3] = max(0, min(255, int(out_a * 255)))


def mix(a, b, t):
    return (int(a[0] + (b[0] - a[0]) * t),
            int(a[1] + (b[1] - a[1]) * t),
            int(a[2] + (b[2] - a[2]) * t))


def gradient(width, height, top, bottom, glows):
    pixels = canvas(width, height)
    for y in range(height):
        base = mix(top, bottom, y / max(1, height - 1))
        for x in range(width):
            r, g, b = base
            for cx, cy, radius, color, strength in glows:
                dx = (x - cx * width) / (radius * width)
                dy = (y - cy * height) / (radius * width)
                d2 = dx * dx + dy * dy
                if d2 < 1:
                    a = (1 - d2) ** 2 * strength
                    r = int(r + (color[0] - r) * a)
                    g = int(g + (color[1] - g) * a)
                    b = int(b + (color[2] - b) * a)
            i = (y * width + x) * 4
            pixels[i:i + 4] = bytes((max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), 255))
    return pixels


def rounded_contains(x, y, x0, y0, x1, y1, radius):
    cx = min(max(x, x0 + radius), x1 - radius)
    cy = min(max(y, y0 + radius), y1 - radius)
    return (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius


def rounded_fill(pixels, width, height, x0, y0, x1, y1, radius, color):
    for y in range(max(0, y0), min(height, y1 + 1)):
        for x in range(max(0, x0), min(width, x1 + 1)):
            if rounded_contains(x, y, x0, y0, x1, y1, radius):
                blend(pixels, width, x, y, color, color[3] / 255.0)


def rounded_outline(pixels, width, height, x0, y0, x1, y1, radius, color, thickness=2):
    for y in range(max(0, y0), min(height, y1 + 1)):
        for x in range(max(0, x0), min(width, x1 + 1)):
            inside = rounded_contains(x, y, x0, y0, x1, y1, radius)
            inner = rounded_contains(x, y, x0 + thickness, y0 + thickness,
                                     x1 - thickness, y1 - thickness, max(1, radius - thickness))
            if inside and not inner:
                blend(pixels, width, x, y, color, color[3] / 255.0)


def circle_fill(pixels, width, height, cx, cy, radius, color):
    for y in range(max(0, cy - radius), min(height, cy + radius + 1)):
        for x in range(max(0, cx - radius), min(width, cx + radius + 1)):
            dist = (x - cx) ** 2 + (y - cy) ** 2
            if dist <= radius * radius:
                inner = (radius - 2) ** 2
                alpha = color[3] / 255.0
                if dist > inner:
                    alpha *= max(0.0, (radius * radius - dist) / (radius * radius - inner))
                blend(pixels, width, x, y, color, alpha)


def circle_outline(pixels, width, height, cx, cy, radius, color, thickness=2):
    outer = radius * radius
    inner = max(0, radius - thickness) ** 2
    for y in range(max(0, cy - radius), min(height, cy + radius + 1)):
        for x in range(max(0, cx - radius), min(width, cx + radius + 1)):
            dist = (x - cx) ** 2 + (y - cy) ** 2
            if inner <= dist <= outer:
                blend(pixels, width, x, y, color, color[3] / 255.0)


def line(pixels, width, height, x0, y0, x1, y1, color, thickness=2):
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        for oy in range(-(thickness // 2), thickness // 2 + 1):
            for ox in range(-(thickness // 2), thickness // 2 + 1):
                x = x0 + ox
                y = y0 + oy
                if 0 <= x < width and 0 <= y < height:
                    blend(pixels, width, x, y, color, color[3] / 255.0)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy


def triangle(pixels, width, height, points, color):
    (x1, y1), (x2, y2), (x3, y3) = points
    min_x = max(0, min(x1, x2, x3))
    max_x = min(width - 1, max(x1, x2, x3))
    min_y = max(0, min(y1, y2, y3))
    max_y = min(height - 1, max(y1, y2, y3))
    area = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
    if area == 0:
        return
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / area
            b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / area
            c = 1 - a - b
            if a >= 0 and b >= 0 and c >= 0:
                blend(pixels, width, x, y, color, color[3] / 255.0)


def text(pixels, width, height, value, x, y, scale, color, spacing=1):
    cursor = x
    for char in value.upper():
        glyph = FONT.get(char, FONT[" "])
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    for sy in range(scale):
                        for sx in range(scale):
                            px = cursor + gx * scale + sx
                            py = y + gy * scale + sy
                            if 0 <= px < width and 0 <= py < height:
                                blend(pixels, width, px, py, color, color[3] / 255.0)
        cursor += (5 + spacing) * scale


def text_width(value, scale, spacing=1):
    return len(value) * (5 + spacing) * scale


def badge(pixels, width, height, cx, cy, size):
    radius = int(size * 0.26)
    x0, y0 = cx - size // 2, cy - size // 2
    x1, y1 = x0 + size, y0 + size
    for y in range(max(0, y0), min(height, y1 + 1)):
        for x in range(max(0, x0), min(width, x1 + 1)):
            if rounded_contains(x, y, x0, y0, x1, y1, radius):
                t = (x - x0 + y - y0) / max(1, (x1 - x0) + (y1 - y0))
                color = mix(VIOLET, PINK, t)
                blend(pixels, width, x, y, color + (255,), 1.0)
    rounded_outline(pixels, width, height, x0, y0, x1, y1, radius, LILAC + (150,), max(2, size // 64))
    inner = int(size * 0.46)
    triangle(pixels, width, height,
             ((cx - inner // 3, cy - inner // 2),
              (cx + inner // 2, cy),
              (cx - inner // 3, cy + inner // 2)),
             TEAL + (255,))


BLUE = (51, 77, 255)  # faixa azul do aurora (meio)

def make_bg_app():
    """Aurora 1920x1080: base quase preto azulado (#0b0e14),
    brilho teal (#4fe3d0) no canto superior direito, faixa azul
    no meio, faixa roxa/violeta no quadrante inferior esquerdo.
    Alvo: android-ref/apk-art/fundo_app.jpg"""
    width, height = 1920, 1080
    pixels = canvas(width, height, (11, 14, 20, 255))  # base #0b0e14
    # Brilho teal no canto superior direito (gradiente radial)
    cx, cy = width * 0.85, height * 0.15
    max_r = math.hypot(width * 0.45, height * 0.45)
    for y in range(height):
        for x in range(width):
            r = math.hypot(x - cx, y - cy)
            strength = max(0.0, 1.0 - r / max_r) ** 1.5
            blend(pixels, width, x, y, TEAL + (255,), strength * 0.35)
    # Faixa azul na altura do meio (brilho horizontal suave)
    band_y = height * 0.52
    band_h = height * 0.11
    for y in range(height):
        band = max(0.0, 1.0 - abs(y - band_y) / band_h) ** 2
        if band <= 0:
            continue
        for x in range(width):
            horizontal = 0.55 + 0.45 * math.sin(math.pi * x / (width - 1))
            blend(pixels, width, x, y, BLUE + (255,), band * horizontal * 0.14)
    # Faixa roxa no quadrante inferior esquerdo (gradiente radial)
    cx, cy = width * 0.18, height * 0.82
    max_r = math.hypot(width * 0.30, height * 0.34)
    for y in range(height):
        for x in range(width):
            r = math.hypot(x - cx, y - cy)
            strength = max(0.0, 1.0 - r / max_r) ** 1.6
            blend(pixels, width, x, y, VIOLET + (255,), strength * 0.30)
    save_png(IMAGES / "bg_app.png", width, height, pixels)


def make_bg_sidebar():
    """Superfície escura da sidebar: #0b0e14 sem gradiente colorido
    (deixa a cor flat, como o Android)."""
    width, height = 400, 1080
    pixels = canvas(width, height, (11, 14, 20, 255))  # #0b0e14
    save_png(IMAGES / "bg_sidebar.png", width, height, pixels)


def make_player_veils():
    width, height = 1920, 260
    top_pixels = canvas(width, height)
    bottom_pixels = canvas(width, height)
    for y in range(height):
        top_strength = (1 - y / (height - 1)) ** 1.5 * 0.82
        bottom_strength = (y / (height - 1)) ** 1.5 * 0.88
        for x in range(width):
            blend(top_pixels, width, x, y, BG + (255,), top_strength)
            blend(bottom_pixels, width, x, y, BG + (255,), bottom_strength)
    save_png(IMAGES / "player_veil_top.png", width, height, top_pixels)
    save_png(IMAGES / "player_veil_bottom.png", width, height, bottom_pixels)


def make_ficha_veils():
    """Véus da ficha com as direções do Android (bg_ficha_lado / bg_ficha_baixo).

    Lateral (1520x1080): horizontal, opaco #f50b0e14 na borda ESQUERDA,
    passa por #c80b0e14 no meio e chega a #200b0e14 na borda DIREITA
    (bg_ficha_lado, ângulo 0: startColor à esquerda).
    Inferior (1520x520): vertical, opaco #ff0b0e14 na borda INFERIOR,
    passa por #b30b0e14 no meio e chega a #000b0e14 na borda SUPERIOR
    (bg_ficha_baixo, ângulo 90: startColor embaixo).
    """
    width, height = 1520, 1080
    side_pixels = canvas(width, height)
    for x in range(width):
        t = x / (width - 1)
        if t <= 0.5:
            alpha = round(0xF5 + (0xC8 - 0xF5) * (t / 0.5))
        else:
            alpha = round(0xC8 + (0x20 - 0xC8) * ((t - 0.5) / 0.5))
        color = (0x0B, 0x0E, 0x14, alpha)
        for y in range(height):
            blend(side_pixels, width, x, y, color, alpha / 255.0)
    save_png(IMAGES / "ficha_veil_side.png", width, height, side_pixels)

    strip_height = 520
    bottom_pixels = canvas(width, strip_height)
    for y in range(strip_height):
        u = y / (strip_height - 1)
        if u <= 0.5:
            alpha = round(0x00 + 0xB3 * (u / 0.5))
        else:
            alpha = round(0xB3 + (0xFF - 0xB3) * ((u - 0.5) / 0.5))
        color = (0x0B, 0x0E, 0x14, alpha)
        for x in range(width):
            blend(bottom_pixels, width, x, y, color, alpha / 255.0)
    save_png(IMAGES / "ficha_veil_bottom.png", width, strip_height, bottom_pixels)


def make_spinner():
    size = 96
    center = (size - 1) / 2
    pixels = canvas(size, size)
    for y in range(size):
        for x in range(size):
            dx = x - center
            dy = y - center
            radius = math.sqrt(dx * dx + dy * dy)
            if 34 <= radius <= 43:
                angle = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
                color = mix(VIOLET, TEAL, angle)
                blend(pixels, size, x, y, color + (255,), 0.2 + angle * 0.8)
    save_png(IMAGES / "player_spinner.png", size, size, pixels)


def make_icon(path, width, height):
    pixels = gradient(width, height, (10, 8, 17), (6, 5, 10), [
        (0.20, 0.10, 0.60, VIOLET, 0.22),
        (0.82, 0.90, 0.55, TEAL, 0.12),
    ])
    paste_brand_logo(pixels, width, height, int(height * 0.68), int(height * 0.42))
    save_png(path, width, height, pixels)


def make_splash(path, width, height):
    pixels = gradient(width, height, (9, 8, 15), (5, 4, 9), [
        (0.18, 0.02, 0.62, VIOLET, 0.20),
        (0.62, 0.18, 0.65, PINK, 0.06),
        (0.86, 0.98, 0.55, TEAL, 0.07),
    ])
    paste_brand_logo(pixels, width, height, int(height * 0.40), int(height * 0.42))
    save_png(path, width, height, pixels)


def make_placeholder(path, width, height):
    pixels = gradient(width, height, (14, 11, 24), (7, 6, 12), [
        (0.50, 0.28, 0.70, VIOLET, 0.16),
        (0.50, 0.92, 0.55, TEAL, 0.05),
    ])
    rounded_outline(pixels, width, height, 10, 10, width - 11, height - 11,
                    max(18, width // 12), LILAC + (70,), 3)
    badge(pixels, width, height, width // 2, int(height * 0.42), int(width * 0.34))
    scale = max(2, width // 190)
    label = "SAIMO"
    text(pixels, width, height, label, (width - text_width(label, scale)) // 2,
         int(height * 0.64), scale, MUTED + (255,))
    save_png(path, width, height, pixels)


def make_nav_focus(path, width, height, active):
    color = VIOLET + ((58 if active else 24),)
    border = LILAC + ((150 if active else 58),)
    pixels = canvas(width, height)
    rounded_fill(pixels, width, height, 1, 1, width - 2, height - 2, 10, color)
    rounded_outline(pixels, width, height, 1, 1, width - 2, height - 2, 10, border, 2)
    save_png(path, width, height, pixels)


def make_grid_focus(path, width, height, active):
    alpha = 210 if active else 90
    pixels = canvas(width, height)
    rounded_outline(pixels, width, height, 4, 4, width - 5, height - 5, 16,
                    TEAL + (alpha,), 5)
    rounded_outline(pixels, width, height, 1, 1, width - 2, height - 2, 18,
                    VIOLET + ((80 if active else 34),), 2)
    save_png(path, width, height, pixels)


def make_row_focus(path, width, height):
    """Foco no estilo Android row_focus: preenchimento #26ffffff, borda 3px
    accent e raio 14. Cobre episódios, chips, fileiras e a grade de capas."""
    pixels = canvas(width, height)
    rounded_fill(pixels, width, height, 0, 0, width - 1, height - 1, 14,
                 (255, 255, 255, 0x26))
    rounded_outline(pixels, width, height, 0, 0, width - 1, height - 1, 14,
                    TEAL + (255,), 3)
    save_png(path, width, height, pixels)


def make_action_pill(path, width, height, focused):
    """Pílula da ficha (botao_ficha): raio 20px, repouso #26ffffff, foco branco."""
    pixels = canvas(width, height)
    color = (255, 255, 255, 255) if focused else (255, 255, 255, 0x26)
    rounded_fill(pixels, width, height, 0, 0, width - 1, height - 1, 20, color)
    save_png(path, width, height, pixels)


def nav_icon(path, kind):
    size = 36
    pixels = canvas(size, size)
    color = TEAL + (255,) if kind == "live" else (201, 191, 227, 255)
    muted = (120, 111, 143, 255)
    if kind == "live":
        circle_outline(pixels, size, size, 18, 18, 13, color, 2)
        triangle(pixels, size, size, ((14, 11), (26, 18), (14, 25)), color)
    elif kind == "discover":
        triangle(pixels, size, size, ((18, 5), (23, 18), (13, 18)), color)
        triangle(pixels, size, size, ((18, 31), (23, 18), (13, 18)), color)
        triangle(pixels, size, size, ((5, 18), (18, 13), (18, 23)), color)
        triangle(pixels, size, size, ((31, 18), (18, 13), (18, 23)), color)
    elif kind == "catalog":
        for x0, y0 in ((7, 7), (20, 7), (7, 20), (20, 20)):
            rounded_outline(pixels, size, size, x0, y0, x0 + 9, y0 + 9, 2, color, 2)
    elif kind == "movies":
        rounded_outline(pixels, size, size, 6, 9, 30, 27, 4, color, 2)
        triangle(pixels, size, size, ((15, 13), (24, 18), (15, 23)), color)
    elif kind == "series":
        rounded_outline(pixels, size, size, 7, 6, 27, 22, 3, color, 2)
        line(pixels, size, size, 11, 27, 29, 27, color, 2)
        line(pixels, size, size, 11, 30, 24, 30, muted, 2)
        triangle(pixels, size, size, ((14, 10), (23, 14), (14, 18)), color)
    elif kind == "favorites":
        circle_fill(pixels, size, size, 13, 14, 6, color)
        circle_fill(pixels, size, size, 23, 14, 6, color)
        triangle(pixels, size, size, ((7, 16), (29, 16), (18, 30)), color)
    elif kind == "search":
        circle_outline(pixels, size, size, 15, 15, 8, color, 2)
        line(pixels, size, size, 21, 21, 29, 29, color, 3)
    elif kind == "guide":
        rounded_outline(pixels, size, size, 6, 9, 30, 29, 3, color, 2)
        line(pixels, size, size, 7, 15, 29, 15, color, 2)
        for x in (11, 17, 23):
            circle_fill(pixels, size, size, x, 21, 1, color)
            circle_fill(pixels, size, size, x, 25, 1, muted)
    elif kind == "settings":
        circle_outline(pixels, size, size, 18, 18, 7, color, 2)
        for angle in range(0, 360, 45):
            rad = math.radians(angle)
            x0 = int(18 + math.cos(rad) * 10)
            y0 = int(18 + math.sin(rad) * 10)
            x1 = int(18 + math.cos(rad) * 14)
            y1 = int(18 + math.sin(rad) * 14)
            line(pixels, size, size, x0, y0, x1, y1, color, 2)
    elif kind == "sync":
        line(pixels, size, size, 8, 14, 26, 14, color, 2)
        triangle(pixels, size, size, ((26, 9), (31, 14), (26, 19)), color)
        line(pixels, size, size, 28, 23, 10, 23, color, 2)
        triangle(pixels, size, size, ((10, 18), (5, 23), (10, 28)), color)
    elif kind == "group":
        for y in (10, 18, 26):
            circle_fill(pixels, size, size, 8, y, 2, color)
            line(pixels, size, size, 14, y, 29, y, muted, 2)
    else:
        rounded_outline(pixels, size, size, 9, 9, 27, 27, 3, muted, 2)
    save_png(path, size, size, pixels)


def main():
    IMAGES.mkdir(parents=True, exist_ok=True)
    make_bg_app()
    make_bg_sidebar()
    make_player_veils()
    make_ficha_veils()
    make_spinner()
    make_icon(IMAGES / "icon_focus_fhd.png", 540, 405)
    make_icon(IMAGES / "icon_focus_hd.png", 290, 218)
    make_icon(IMAGES / "icon_focus_sd.png", 214, 144)
    make_splash(IMAGES / "splash_fhd.png", 1920, 1080)
    make_splash(IMAGES / "splash_hd.png", 1280, 720)
    make_splash(IMAGES / "splash_sd.png", 720, 480)
    make_placeholder(IMAGES / "placeholder.png", 600, 900)
    make_nav_focus(IMAGES / "nav_focus.png", 338, 48, True)
    make_nav_focus(IMAGES / "nav_focus_idle.png", 338, 48, False)
    make_nav_focus(IMAGES / "list_focus.png", 1220, 54, True)
    make_nav_focus(IMAGES / "list_focus_idle.png", 1220, 54, False)
    make_nav_focus(IMAGES / "item_focus.png", 730, 58, True)
    make_nav_focus(IMAGES / "item_focus_idle.png", 730, 58, False)
    make_nav_focus(IMAGES / "guide_focus.png", 1720, 54, True)
    make_nav_focus(IMAGES / "guide_focus_idle.png", 1720, 54, False)
    make_row_focus(IMAGES / "focus_episode.png", 396, 310)
    make_row_focus(IMAGES / "focus_chip.png", 280, 80)
    make_row_focus(IMAGES / "focus_grid.png", 210, 315)
    make_row_focus(IMAGES / "focus_shelf.png", 168, 248)
    make_row_focus(IMAGES / "focus_grid_idle.png", 210, 315)
    make_action_pill(IMAGES / "action_pill_normal.png", 296, 104, False)
    make_action_pill(IMAGES / "action_pill_focus.png", 296, 104, True)
    for kind in ("live", "discover", "catalog", "movies", "series", "favorites",
                 "search", "guide", "settings", "sync", "group", "blank"):
        nav_icon(IMAGES / ("nav_" + kind + ".png"), kind)
    print("Arte gerada em", IMAGES)


if __name__ == "__main__":
    main()
