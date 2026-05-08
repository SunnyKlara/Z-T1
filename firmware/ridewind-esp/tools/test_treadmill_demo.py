#!/usr/bin/env python3
"""
Treadmill HUD v2 — Fusion Design Preview
GC9A01 240×240 circular screen

Design:
  - Double arc: dim background arc (always visible) + gradient foreground arc
  - 320° sweep, gap at BOTTOM (6 o'clock)
  - Gear number in the gap at bottom
  - Speed number centered, large, gradient-colored
  - Ticks every 20 (minor) / 80 (major + label)
  - NO pointer — arc fill end = indicator
  - Pure black background

Controls:
  MouseWheel: +/- 10 speed    Click: start/stop
  Space: toggle               q/ESC: quit
"""

import tkinter as tk
import math
import random

SW, SH = 240, 240
CX, CY = 120, 120

ARC_R     = 110
ARC_THICK = 8    # was 8 (fixed to match ESP32)
ARC_SWEEP = 320     # degrees of visible arc
GAP_DEG   = 90      # gap center at bottom (tkinter: 0=right, 90=down)

# Arc: gap_center ± sweep/2
# -70° → through 0° → 90°(gap) → through 180° → 250°
ARC_START = math.radians(GAP_DEG - ARC_SWEEP / 2)   # -70° = 290°
ARC_END   = math.radians(GAP_DEG + ARC_SWEEP / 2)   # 250°
ARC_SPAN  = ARC_END - ARC_START                     # 320° in radians

MAX_KMH       = 700
TICK_MINOR    = 20
TICK_MAJOR    = 80
MAX_PACE      = 999

# Colors — Tixing 3-stop gradient
LO  = (0,   200, 220)
MID = (255, 190,  50)
HI  = (240,  50,  30)

BG_DIM   = '#252530'   # background arc
TICK_DIM = '#2A2A2A'   # inactive tick
LBL_DIM  = '#1A1A1A'   # inactive label
BG       = '#000000'

def lerp(a, b, t):
    t = max(0, min(1, t))
    return a + (b - a) * t

def grad_rgb(t):
    """3-stop: cyan(0) → gold(0.5) → red(1.0)"""
    t = max(0, min(1, t))
    if t < 0.5:
        s = t * 2
        return (int(lerp(LO[0], MID[0], s)),
                int(lerp(LO[1], MID[1], s)),
                int(lerp(LO[2], MID[2], s)))
    s = (t - 0.5) * 2
    return (int(lerp(MID[0], HI[0], s)),
            int(lerp(MID[1], HI[1], s)),
            int(lerp(MID[2], HI[2], s)))

def grad_hex(t):
    r, g, b = grad_rgb(t)
    return f'#{r:02x}{g:02x}{b:02x}'

# ── Simulation ─────────────────────────────────────────────────
cur_pace = 0
cur_gear = 1

def tick():
    global cur_pace, cur_gear
    if cur_pace > 0:
        cur_pace = min(MAX_PACE, cur_pace + random.randint(1, 8))
        r = cur_pace / MAX_PACE
        if   r < 0.10: cur_gear = 1
        elif r < 0.20: cur_gear = 2
        elif r < 0.35: cur_gear = 3
        elif r < 0.50: cur_gear = 4
        elif r < 0.60: cur_gear = 5
        elif r < 0.70: cur_gear = 6
        elif r < 0.82: cur_gear = 7
        elif r < 0.92: cur_gear = 8
        else:          cur_gear = 9
    return cur_gear, cur_pace

# ── Drawing primitives ─────────────────────────────────────────

def draw_arc_full(cv, cx, cy, r, thick, color, a_start, a_end):
    """Draw a filled arc ring from a_start to a_end with given color."""
    h = thick / 2
    n = max(30, int(abs(a_end - a_start) / math.radians(1.5)))
    step = (a_end - a_start) / n

    pts = []
    for i in range(n + 1):
        a = a_start + i * step
        pts.append((cx + (r + h) * math.cos(a), cy + (r + h) * math.sin(a)))
    for i in range(n, -1, -1):
        a = a_start + i * step
        pts.append((cx + (r - h) * math.cos(a), cy + (r - h) * math.sin(a)))

    cv.create_polygon(*[c for p in pts for c in p], fill=color, outline='')


def draw_arc_gradient(cv, cx, cy, r, thick, a_start, a_end, ratio):
    """Draw arc ring with gradient segments, only up to ratio."""
    if ratio <= 0:
        return
    h = thick / 2
    span = a_end - a_start
    active_angle = span * ratio
    n = max(30, int(active_angle / math.radians(2)))

    if n <= 0:
        return

    step = active_angle / n

    for i in range(n):
        a0 = a_start + i * step
        a1 = a_start + (i + 1) * step
        t = (i + 0.5) / n  # midpoint of segment for color

        col = grad_hex(t * ratio)

        pts = [
            (cx + (r + h) * math.cos(a0), cy + (r + h) * math.sin(a0)),
            (cx + (r + h) * math.cos(a1), cy + (r + h) * math.sin(a1)),
            (cx + (r - h) * math.cos(a1), cy + (r - h) * math.sin(a1)),
            (cx + (r - h) * math.cos(a0), cy + (r - h) * math.sin(a0)),
        ]
        cv.create_polygon(*[c for p in pts for c in p], fill=col, outline='')


def draw_ticks(cv, cx, cy, r, thick, a_start, a_end, ratio):
    """Ticks: minor every 20 km/h, major every 80 + label."""
    span = a_end - a_start
    # Tick base: just outside arc outer edge
    r_base = r + thick / 2 + 1

    for kmh in range(0, MAX_KMH + 1, TICK_MINOR):
        if kmh == 0 or kmh == MAX_KMH:
            continue
        t = kmh / MAX_KMH
        a = a_start + span * t

        major = (kmh % TICK_MAJOR == 0)
        tlen = 7 if major else 3
        r_inner = r_base - tlen

        ca, sa = math.cos(a), math.sin(a)
        x0 = cx + r_base * ca
        y0 = cy + r_base * sa
        x1 = cx + r_inner * ca
        y1 = cy + r_inner * sa

        active = (t <= ratio and ratio > 0)
        col = grad_hex(t) if active else TICK_DIM
        width = 1.5 if major else 1

        cv.create_line(x0, y0, x1, y1, fill=col, width=width)

        # Major label
        if major and kmh > 0 and kmh < MAX_KMH:
            lr = r_inner - 8
            lx = cx + lr * ca
            ly = cy + lr * sa
            deg = math.degrees(a) % 360
            # Skip labels in gap zone (65-115°)
            if not (65 < deg < 115):
                lcol = grad_hex(t) if active else LBL_DIM
                cv.create_text(lx, ly, text=str(kmh),
                               fill=lcol, font=('Roboto', 8, 'bold'))


def draw_numbers(cv, gear, pace, ratio):
    """Speed (center, large, gradient color) + Gear (gap bottom, small)."""
    r, g, b = grad_rgb(ratio) if ratio > 0 else (60, 60, 60)
    col = f'#{r:02x}{g:02x}{b:02x}'

    # ── Speed: large, centered ──
    # Visual center of arc ring is slightly above CY
    # Arc inner edge at top: CY - 106 = 14px from top
    # Good speed digit center: Y ≈ 105
    cv.create_text(CX, 105, text=str(pace),
                   fill=col, font=('Roboto', 50, 'bold'))

    # ── Gear: small, in the gap at bottom ──
    # Gap center = 90° (directly below)
    # Bottom of arc inner edge: CY + (ARC_R - ARC_THICK/2) = 120 + 106 = 226
    # Gap visible area: roughly Y = 140 to Y = 226
    # Gear at Y = 175, centered, well inside the gap zone
    cv.create_text(CX, 175, text=str(gear),
                   fill=col, font=('Roboto', 28, 'bold'))


# ── App ────────────────────────────────────────────────────────

class App:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title('Treadmill HUD v2')
        self.root.geometry(f'{SW}x{SH}+300+100')
        self.root.resizable(False, False)
        self.root.configure(bg=BG)

        self.cv = tk.Canvas(self.root, width=SW, height=SH,
                            bg=BG, highlightthickness=0)
        self.cv.pack()

        self.cv.bind('<MouseWheel>', self._scroll)
        self.cv.bind('<Button-1>', self._click)
        self.root.bind('<Escape>', lambda e: self.root.quit())
        self.root.bind('q', lambda e: self.root.quit())
        self.root.bind('<space>', self._toggle)

        self._redraw()
        print("MouseWheel=±10  Click=toggle  Space=toggle  q/ESC=quit")
        self.root.mainloop()

    def _toggle(self, ev=None):
        global cur_pace
        cur_pace = 0 if cur_pace > 0 else 50

    def _scroll(self, ev):
        global cur_pace
        d = 10 if ev.delta > 0 else -10
        cur_pace = max(0, min(MAX_PACE, cur_pace + d))

    def _click(self, ev):
        self._toggle()

    def _redraw(self):
        cv = self.cv
        cv.delete('all')

        gear, pace = tick()
        ratio = pace / MAX_PACE

        # 1. Pure black background
        cv.create_rectangle(0, 0, SW, SH, fill=BG, outline='')

        # 2. Background arc (full 320°, dim, always visible)
        draw_arc_full(cv, CX, CY, ARC_R, ARC_THICK, BG_DIM,
                      ARC_START, ARC_END)

        # 3. Foreground arc (gradient, extends to current ratio)
        draw_arc_gradient(cv, CX, CY, ARC_R, ARC_THICK,
                          ARC_START, ARC_END, ratio)

        # 4. Ticks
        draw_ticks(cv, CX, CY, ARC_R, ARC_THICK,
                   ARC_START, ARC_END, ratio)

        # 5. Numbers
        draw_numbers(cv, gear, pace, ratio)

        self.root.after(50, self._redraw)


if __name__ == '__main__':
    App()
