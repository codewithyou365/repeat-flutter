#!/usr/bin/env python3
"""Generate launcher icon PNGs from the app_icon.svg design.

Outputs (1024x1024, drawn at 2x and downsampled):
  app_icon.png         rounded-square preview / legacy Android icon
  icon_ios.png         full-bleed square, no alpha (iOS)
  icon_android_bg.png  adaptive icon background layer (gradient + ripples)
  icon_android_fg.png  adaptive icon foreground layer (R on transparency)
  icon_android_mono.png adaptive monochrome layer (Android 13 themed icons)
"""
from PIL import Image, ImageDraw, ImageFilter

N = 2048  # supersampled canvas, downscaled to 1024
S = 2     # scale factor vs the SVG's 1024 viewBox
OUT = 1024

C0 = (46, 107, 240)   # #2E6BF0
C1 = (123, 47, 227)   # #7B2FE3
SHADOW = (11, 27, 74) # #0B1B4A


def gradient_bg():
    img = Image.new("RGB", (N, N))
    px = img.load()
    for y in range(N):
        for x in range(N):
            t = (x + y) / (2 * (N - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(C0, C1))
    # radial glow, center (0.30, 0.22), r = 0.95, fades out at offset 0.55
    glow = Image.new("L", (N, N), 0)
    gp = glow.load()
    cx, cy, r = 0.30 * N, 0.22 * N, 0.95 * N
    for y in range(N):
        for x in range(N):
            t = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r
            a = 0.20 * (1 - t / 0.55) if t < 0.55 else 0.0
            gp[x, y] = round(a * 255)
    img.paste(Image.new("RGB", (N, N), (255, 255, 255)), (0, 0), glow)
    return img


def ripples():
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for r, op in ((250, 0.16), (350, 0.11), (460, 0.07), (580, 0.04)):
        r *= S
        d.ellipse([N / 2 - r, N / 2 - r, N / 2 + r, N / 2 + r],
                  outline=(255, 255, 255, round(op * 255)), width=4 * S)
    return layer


def letter_r(color=(255, 255, 255, 255)):
    """Monoline R: stroke width 92, round caps, same geometry as the SVG."""
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w = 92 * S
    half = w // 2

    def line(x1, y1, x2, y2):
        d.line([(x1 * S, y1 * S), (x2 * S, y2 * S)], fill=color, width=w)

    def cap(x, y):
        d.ellipse([x * S - half, y * S - half, x * S + half, y * S + half], fill=color)

    line(372, 320, 372, 704)        # stem
    line(372, 320, 510, 320)        # top bar
    line(372, 560, 510, 560)        # bowl bottom bar
    line(500, 560, 660, 704)        # leg
    # bowl arc: center (510, 440), radius 120, right half
    r_out = (120 + 46) * S
    cx, cy = 510 * S, 440 * S
    d.arc([cx - r_out, cy - r_out, cx + r_out, cy + r_out], start=-90, end=90,
          fill=color, width=w)
    for p in ((372, 320), (372, 704), (372, 560), (500, 560), (660, 704),
              (510, 320), (510, 560)):
        cap(*p)
    return layer


def with_shadow(r_layer):
    """Drop shadow under the R: dy 16, blur ~24, #0B1B4A at 35%."""
    alpha = r_layer.split()[3]
    shadow_alpha = Image.new("L", (N, N), 0)
    shadow_alpha.paste(alpha, (0, 16 * S))
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(24 * S))
    shadow_alpha = shadow_alpha.point(lambda v: round(v * 0.35))
    shadow = Image.new("RGBA", (N, N), SHADOW + (0,))
    shadow.putalpha(shadow_alpha)
    out = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    out.alpha_composite(shadow)
    out.alpha_composite(r_layer)
    return out


def rounded_mask():
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, N - 1, N - 1], radius=230 * S, fill=255)
    return mask


def save(img, name):
    img.resize((OUT, OUT), Image.LANCZOS).save(name)
    print("wrote", name)


def main():
    bg = gradient_bg().convert("RGBA")
    bg.alpha_composite(ripples())
    r = with_shadow(letter_r())

    full = bg.copy()
    full.alpha_composite(r)

    save(bg.convert("RGB"), "icon_android_bg.png")
    save(r, "icon_android_fg.png")
    save(letter_r(), "icon_android_mono.png")
    save(full.convert("RGB"), "icon_ios.png")

    rounded = full.copy()
    rounded.putalpha(rounded_mask())
    save(rounded, "app_icon.png")


if __name__ == "__main__":
    main()
