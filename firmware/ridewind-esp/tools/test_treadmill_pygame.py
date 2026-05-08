#!/usr/bin/env python3
"""
Treadmill UI8 — pygame visual prototype for the ESP32 GC9A01 240x240 screen.

This script mirrors the *exact* C rendering pipeline used in
    main/ui/ui_treadmill.c
so what you see here is what the ESP32 will draw, pixel for pixel.
No anti-aliasing, no transparent layers — every primitive uses the same
formula and integer rounding as the firmware.

Geometry (must match ui_treadmill.c):
    CX=120, CY=120
    ARC_R=100, ARC_THICK=12, half_width=6
    ARC_START_DEG=250 (7-8 o'clock, lower-left)
    ARC_END_DEG=290  (4-5 o'clock, lower-right)
    ARC_SWEEP_DEG=320 (arc goes upper, gap at 6 o'clock bottom)
    Speed max: 999, Table max: 480 km/h
    Ticks every 20 km/h, Labels every 80 km/h

Controls:
    Mouse wheel    +/- 10 speed
    Left click     quick stop (speed=0)
    Up/Down arrow  +/- 50 speed
    Space          toggle (0 <-> 500)
    R              reset to 0
    Esc / Q        quit

Run:
    pip install pygame
    python tools/test_treadmill_pygame.py
"""

import math
import sys

import pygame
import pygame.gfxdraw

# ── Geometry (must match ui_treadmill.c constants) ──────────────────────────
SCREEN_W, SCREEN_H = 240, 240
CX, CY             = 120, 120
ARC_R              = 100
ARC_THICK          = 12
_HW                = ARC_THICK // 2    # = 6

ARC_START_DEG      = 250.0    # arc start (7-8 o'clock, lower-left)
ARC_END_DEG        = 290.0    # arc end   (4-5 o'clock, lower-right)
ARC_SWEEP_DEG      = 320.0    # total sweep

TREAD_SPEED_MAX    = 999
KMH_MAX            = 480

# Colors (RGB triples, RGB565-rounded so screen preview matches HW)
def rgb565_round(r, g, b):
    """Quantize a 24-bit RGB color to RGB565 then back to 24-bit."""
    r5 = (r >> 3) & 0x1F
    g6 = (g >> 2) & 0x3F
    b5 = (b >> 3) & 0x1F
    R = (r5 << 3) | (r5 >> 2)
    G = (g6 << 2) | (g6 >> 4)
    B = (b5 << 3) | (b5 >> 2)
    return (R, G, B)

COLOR_BG       = (0,   0,   0)   # black background
COLOR_ARC_BG   = rgb565_round(22,  22,  26)   # 0x2945 dim arc
COLOR_TICK_DK  = rgb565_round(20,  20,  22)   # 0x2104 inactive tick


def grad888(t):
    """3-stop gradient cyan(0,180,255) -> gold(255,210,80) -> red(255,40,30)."""
    t = max(0.0, min(1.0, t))
    if t < 0.5:
        s = t * 2.0
        r = 0   + (255 - 0)   * s
        g = 180 + (210 - 180) * s
        b = 255 + ( 80 - 255) * s
    else:
        s = (t - 0.5) * 2.0
        r = 255
        g = 210 + ( 40 - 210) * s
        b =  80 + ( 30 -  80) * s
    return (int(r), int(g), int(b))


def grad(t):
    """Full-brightness gradient, RGB565-rounded (used for the arc fill)."""
    return rgb565_round(*grad888(t))


def grad_dim(t, k):
    """Gradient at brightness k (0..1), RGB565-rounded.
    Tixing uses k=0.8 for ticks and k=0.6 for labels."""
    r, g, b = grad888(t)
    return rgb565_round(int(r * k), int(g * k), int(b * k))


# ──────────────────────────────────────────────────────────────────
#  Helpers (mirror ui_treadmill.c)
# ──────────────────────────────────────────────────────────────────

def norm_deg(deg):
    """Normalize angle to [0, 360)."""
    while deg <   0.0: deg += 360.0
    while deg >= 360.0: deg -= 360.0
    return deg


def deg_to_xy(deg, r):
    """Angle (degrees) → screen pixel (x, y).
    Uses +sin so the arc goes upper (positive sin = downward y = bottom).
    With start=250°, end=290°, sweep=320°, the arc goes upper. """
    rad = math.radians(deg)
    x = int(CX + r * math.cos(rad))
    y = int(CY + r * math.sin(rad))
    return x, y


def frac_to_deg(frac):
    """Speed fraction [0,1] → arc angle (incremental direction: 250° + t*320°)."""
    if frac <= 0.0: return ARC_START_DEG
    if frac >= 1.0: return ARC_END_DEG
    return norm_deg(ARC_START_DEG + frac * ARC_SWEEP_DEG)


def arc_pt(pixels, x, y, color, hw):
    """Draw one arc pixel: horizontal bar.
    Mirrors arc_pt() in ui_treadmill.c exactly:
      left = x - hw; clamp to 0
      right = x + hw; no clamp needed
      w = hw * 2  (may exceed right edge, clamped by range)
    """
    left = x - hw
    if left < 0:
        left = 0
    w = hw * 2
    # x is always >=0 and <SCREEN_W here (already checked in caller)
    if 0 <= y < SCREEN_H:
        for xi in range(left, left + w):
            if 0 <= xi < SCREEN_W:
                pixels[xi, y] = color


# ──────────────────────────────────────────────────────────────────
#  Arc rendering (pixel-by-pixel mirror of draw_bg_arc + draw_fg_arc)
# ──────────────────────────────────────────────────────────────────

def render_arc(pixels, ratio):
    """Draw full arc (bg) + foreground colored portion."""
    step = 0.5
    frac_deg = frac_to_deg(ratio)
    end_d = norm_deg(frac_deg)

    px_x, px_y = -1, -1
    for deg in [ARC_START_DEG + i * step for i in range(int(ARC_SWEEP_DEG / step) + 2)]:
        deg = norm_deg(deg)
        x, y = deg_to_xy(ARC_R, deg)
        # Deduplicate (same pixel at boundary between steps)
        if x == px_x and y == px_y:
            continue
        px_x, px_y = x, y

        # Determine if this point is in the active portion
        d = norm_deg(deg)
        if end_d >= ARC_START_DEG:
            active = (d >= ARC_START_DEG and d <= end_d)
        else:
            active = (d >= ARC_START_DEG or d <= end_d)

        if active and ratio > 0:
            # Color based on position along arc (0..1)
            if end_d >= ARC_START_DEG:
                span = end_d - ARC_START_DEG
                offset = norm_deg(d - ARC_START_DEG)
                pt_frac = offset / span if span > 0 else 0.0
            else:
                offset = norm_deg(d - ARC_START_DEG)
                pt_frac = offset / ARC_SWEEP_DEG
            pt_frac = min(1.0, pt_frac)
            color = grad(pt_frac)
        else:
            color = COLOR_ARC_BG

        arc_pt(pixels, x, y, color, _HW)


# ──────────────────────────────────────────────────────────────────
#  Tick rendering (mirror draw_ticks)
# ──────────────────────────────────────────────────────────────────

_tick_label_font = None


def render_ticks(pixels, ratio):
    """Draw ticks: every 20 km/h (minor, 5px), every 40 km/h (major, 10px)."""
    global _tick_label_font
    if _tick_label_font is None:
        _tick_label_font = pygame.font.SysFont('arial', 11, bold=True)

    frac_deg = frac_to_deg(ratio)
    end_d = norm_deg(frac_deg)

    rs = ARC_R - _HW - 1   # tick base (inner edge of arc)

    for kmh in range(20, KMH_MAX + 1, 20):
        t = kmh / KMH_MAX
        deg = frac_to_deg(t)

        major = 1 if kmh % 40 == 0 else 0
        tl = 10 if major else 5
        re = rs - tl

        x0, y0 = deg_to_xy(rs, deg)
        x1, y1 = deg_to_xy(re, deg)

        # Determine active
        d = norm_deg(deg)
        if end_d >= ARC_START_DEG:
            active = (d >= ARC_START_DEG and d <= end_d)
        else:
            active = (d >= ARC_START_DEG or d <= end_d)

        if active and ratio > 0:
            color = grad_dim(t, 0.8)
        else:
            color = COLOR_TICK_DK

        # Draw line (Bresenham mirror)
        _draw_line_bres(pixels, x0, y0, x1, y1, color)
        if major:
            # Extra offset line for double-width
            _draw_line_bres(pixels, x0 + 1, y0, x1 + 1, y1, color)


def _draw_line_bres(pixels, x0, y0, x1, y1, color):
    """Bresenham's line algorithm, mirrors tick_line() in C."""
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    x, y = x0, y0
    while True:
        if 0 <= x < SCREEN_W and 0 <= y < SCREEN_H:
            pixels[x, y] = color
            if x + 1 < SCREEN_W:
                pixels[x + 1, y] = color   # 2px wide tick (C code: fb[y*W+x+1])
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy


# ──────────────────────────────────────────────────────────────────
#  Labels rendering (mirror draw_labels)
# ──────────────────────────────────────────────────────────────────

_label_font = None


def render_labels(surface, ratio):
    """Draw numeric labels every 80 km/h."""
    global _label_font
    if _label_font is None:
        _label_font = pygame.font.SysFont('arial', 10, bold=True)

    frac_deg = frac_to_deg(ratio)
    end_d = norm_deg(frac_deg)

    # Label radius: inner edge - ticks - gap - half font height
    rl = ARC_R - _HW - 1 - 10 - 2 - 16   # = 65

    for kmh in range(0, KMH_MAX + 1, 80):
        t = kmh / KMH_MAX
        deg = frac_to_deg(t)
        lx, ly = deg_to_xy(rl, deg)

        # Determine active
        d = norm_deg(deg)
        if end_d >= ARC_START_DEG:
            active = (d >= ARC_START_DEG and d <= end_d)
        else:
            active = (d >= ARC_START_DEG or d <= end_d)

        if active and ratio > 0:
            color = grad_dim(t, 0.6)
        else:
            color = rgb565_round(35, 35, 38)

        txt = _label_font.render(str(kmh), True, color)
        rect = txt.get_rect(center=(lx, ly))
        surface.blit(txt, rect)


# ──────────────────────────────────────────────────────────────────
#  Center number (mirror draw_center_number)
# ──────────────────────────────────────────────────────────────────

_speed_font = None


def render_center_number(surface, speed, ratio):
    """Draw speed number centered, color follows arc gradient."""
    global _speed_font
    if _speed_font is None:
        _speed_font = pygame.font.SysFont('arial', 54, bold=True)

    color = grad(ratio)
    txt = _speed_font.render(str(speed), True, color)
    rect = txt.get_rect(center=(CX, CY))
    surface.blit(txt, rect)


# ──────────────────────────────────────────────────────────────────
#  Frame composition
# ──────────────────────────────────────────────────────────────────

def render_frame(surface, speed):
    ratio = max(0.0, min(1.0, speed / TREAD_SPEED_MAX))
    surface.fill(COLOR_BG)

    pixels = pygame.PixelArray(surface)

    # Arc (background + foreground)
    render_arc(pixels, ratio)

    # Ticks (write to pixel array)
    render_ticks(pixels, ratio)

    del pixels  # release lock before blit

    # Labels (font rendering needs surface unlocked)
    render_labels(surface, ratio)

    # Center speed number
    render_center_number(surface, speed, ratio)


# ──────────────────────────────────────────────────────────────────
#  pygame app — interactive harness
# ──────────────────────────────────────────────────────────────────

def main():
    pygame.init()
    pygame.display.set_caption('UI8 Treadmill — ESP32 visual prototype')

    SCALE = 3
    win = pygame.display.set_mode((SCREEN_W * SCALE, SCREEN_H * SCALE))
    canvas = pygame.Surface((SCREEN_W, SCREEN_H))

    speed = 0
    clock = pygame.time.Clock()
    last_frame_ms = 0.0
    dirty = True

    info_font = pygame.font.SysFont('consolas', 12)

    while True:
        for ev in pygame.event.get():
            if ev.type == pygame.QUIT:
                pygame.quit()
                return
            elif ev.type == pygame.KEYDOWN:
                if ev.key in (pygame.K_ESCAPE, pygame.K_q):
                    pygame.quit()
                    return
                elif ev.key == pygame.K_UP:
                    speed = min(TREAD_SPEED_MAX, speed + 50)
                    dirty = True
                elif ev.key == pygame.K_DOWN:
                    speed = max(0, speed - 50)
                    dirty = True
                elif ev.key == pygame.K_SPACE:
                    speed = 0 if speed > 0 else 500
                    dirty = True
                elif ev.key == pygame.K_r:
                    speed = 0
                    dirty = True
            elif ev.type == pygame.MOUSEBUTTONDOWN:
                if ev.button == 1:           # left click → quick stop
                    speed = 0
                    dirty = True
                elif ev.button == 4:         # wheel up
                    speed = min(TREAD_SPEED_MAX, speed + 10)
                    dirty = True
                elif ev.button == 5:         # wheel down
                    speed = max(0, speed - 10)
                    dirty = True
            elif ev.type == pygame.MOUSEWHEEL:
                speed = max(0, min(TREAD_SPEED_MAX, speed + ev.y * 10))
                dirty = True

        if dirty:
            t0 = pygame.time.get_ticks()
            render_frame(canvas, speed)
            last_frame_ms = pygame.time.get_ticks() - t0
            dirty = False

        # Upscale to window
        scaled = pygame.transform.scale(
            canvas, (SCREEN_W * SCALE, SCREEN_H * SCALE))
        win.blit(scaled, (0, 0))

        # Info bar
        ratio_pct = speed / TREAD_SPEED_MAX
        info = info_font.render(
            f'speed={speed:3d}  ratio={ratio_pct:4.2f}  '
            f'frame={last_frame_ms:.0f}ms  '
            f'arc_start=250° arc_end=290° sweep=320° '
            f'R=100 thick=12',
            True, (230, 230, 230), (10, 10, 10))
        win.blit(info, (4, 4))

        pygame.display.flip()
        clock.tick(60)


if __name__ == '__main__':
    sys.exit(main())
