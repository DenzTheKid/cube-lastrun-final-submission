"""
Apocalyptic Chaos City & Collapsed Bridge Asset Pipeline (V2 - High-Craft Pixel Art) for CUBE: LAST RUN.
Generates:
1. parallax_skyline_distant.png (480x270): Ruined distant towers, translucent smoke plumes, distant fires, collapsed suspension bridge.
2. parallax_buildings_mid.png (480x270): Chaotic doomsday skyline featuring:
   - Skyscraper struck by a crashed commercial airliner (unobscured fuselage, tail fin, swept wing, jet engine, blast crater & roaring fire!)
   - Multi-floor burning buildings with organic pixel flames licking out of shattered windows (zero flat white bars or opaque smoke blobs)
   - Collapsed/tilted buildings with exposed steel I-beam girders, cross-bracing & rubble
   - Collapsed construction crane & broken crooked neon billboards
3. parallax_overpass_fore.png (480x270): Twisted/broken highway guardrails, burning car wrecks, sagging power lines.
4. collapsed_bridge_pit.png (80x64): Ultra-clear collapsed highway bridge structure (diagonal fallen asphalt decks with yellow road lines,
   twisted red steel truss girders, broken central concrete bridge pier with protruding rebar, snapped suspension cables, and glowing chasm fire).
"""
import os
import math
import random
import requests
from PIL import Image, ImageDraw

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_DIR = os.path.join(PROJECT_ROOT, "assets", "environment")
os.makedirs(ENV_DIR, exist_ok=True)

OUTLINE = (10, 11, 20, 255)


def draw_organic_smoke(draw, cx, cy, width, height, rng):
    """Draws subtle, semi-transparent pixel-art smoke wisps that add atmosphere without obscuring details."""
    for s in range(5):
        sx = cx + int(math.sin(s * 1.1) * (width * 0.25)) + rng.randint(-3, 3)
        sy = cy - int(height * 0.6) - s * 6
        rx = max(4, int(width * 0.32) + s * 2)
        ry = max(3, int(rx * 0.55))
        alpha = max(22, 88 - s * 14)
        col = (44, 24, 32, alpha) if s == 0 else (20, 16, 28, alpha)
        draw.ellipse([sx - rx, sy - ry, sx + rx, sy + ry], fill=col)


def draw_pixel_fire(draw, cx, cy, width, height, rng, with_smoke=True):
    """
    Draws crisp, organic pixel-art flames (dark ember base -> crimson -> orange -> golden yellow -> hot spark tips)
    with ZERO flat white bars.
    """
    if with_smoke:
        draw_organic_smoke(draw, cx, cy, width, height, rng)

    EMBER_BASE = (92, 18, 20, 255)
    FIRE_RED = (214, 34, 24, 255)
    FIRE_ORANGE = (248, 118, 24, 255)
    FIRE_GOLD = (255, 208, 56, 255)
    FIRE_TIP = (255, 246, 176, 255)

    # Uneven charred ember bed at base
    half_w = max(3, width // 2)
    for x in range(cx - half_w, cx + half_w + 1, 2):
        bh = rng.randint(1, 3)
        draw.rectangle([x, cy - bh, x + 1, cy + 1], fill=EMBER_BASE)

    # Organic jagged flame columns across width (varied base_y so bottom is never a flat bar!)
    for x in range(cx - half_w, cx + half_w + 1):
        dist_center = abs(x - cx) / float(max(1, half_w))
        profile = max(0.25, 1.0 - (dist_center ** 1.6))
        col_h = max(3, int(height * profile * rng.uniform(0.55, 1.25)))
        base_y = cy + int(math.sin(x * 0.9) * 2) + rng.randint(-1, 1)

        # Outer crimson tongue
        draw.line([(x, base_y + 1), (x, base_y - col_h)], fill=FIRE_RED)
        # Mid orange flame (70% height)
        oh = max(2, int(col_h * 0.72))
        draw.line([(x, base_y), (x, base_y - oh)], fill=FIRE_ORANGE)
        # Inner golden core (42% height)
        gh = max(1, int(col_h * 0.42))
        draw.line([(x, base_y - 1), (x, base_y - gh)], fill=FIRE_GOLD)
        # Hot core pixel near base
        if dist_center < 0.55 and rng.random() > 0.35:
            draw.point((x, base_y - rng.randint(1, max(1, gh // 2))), fill=FIRE_TIP)
        # Dark charred rubble tooth at base edge
        if (x + cx) % 3 == 0:
            draw.rectangle([x, base_y, x + 1, base_y + 2], fill=OUTLINE)

    # Rising glowing ember sparks
    for _ in range(max(3, width // 4)):
        ex = cx + rng.randint(-half_w - 3, half_w + 3)
        ey = cy - rng.randint(height // 2, height + 14)
        draw.point((ex, ey), fill=FIRE_GOLD if rng.random() > 0.4 else FIRE_ORANGE)


def build_apocalyptic_distant_skyline():
    """
    Generates res://assets/environment/parallax_skyline_distant.png (480x270)
    Devastated distant horizon with shattered skyscrapers, smoke plumes, distant fires, and collapsed suspension bridge.
    """
    img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(777)

    SIL_COL = (24, 18, 36, 255)
    SIL_RIM = (78, 36, 50, 255)
    GIRDER_COL = (42, 28, 48, 255)
    WIN_FIRE = (245, 128, 38, 235)
    WIN_DARK = (14, 11, 22, 255)

    # Tall translucent apocalyptic smoke columns rising in the far distance
    for sx in [52, 158, 268, 392]:
        for step in range(10):
            sy = 168 - step * 10
            rad = 7 + step * 2
            ox = int(math.sin(step * 0.6 + sx) * 5)
            alpha = max(18, 82 - step * 7)
            scol = (54, 24, 32, alpha) if step < 2 else (22, 16, 28, alpha)
            draw.ellipse([sx + ox - rad, sy - rad // 2, sx + ox + rad, sy + rad // 2], fill=scol)

    # Distant ruined skyscrapers: [x, w, top_y, ruin_type]
    dist_specs = [
        (0, 44, 116, 0),
        (42, 38, 134, 1),
        (78, 52, 98, 3),
        (128, 40, 126, 2),
        (166, 48, 108, 1),
        (212, 42, 132, 0),
        (252, 54, 96, 3),
        (304, 38, 140, 2),
        (340, 48, 112, 1),
        (386, 46, 124, 0),
        (430, 50, 104, 3)
    ]

    for bx, bw, by, rtype in dist_specs:
        if rtype == 0:
            pts = [(bx, 270), (bx, by + 2), (bx + bw // 3, by), (bx + bw // 2, by + 10), (bx + bw, by + 18), (bx + bw, 270)]
        elif rtype == 1:
            pts = [
                (bx, 270), (bx, by), (bx + bw // 4, by),
                (bx + bw // 2, by + 14), (bx + (bw * 3) // 4, by + 2),
                (bx + bw, by + 4), (bx + bw, 270)
            ]
        elif rtype == 2:
            pts = [(bx, 270), (bx, by + 16), (bx + bw // 2, by + 8), (bx + (bw * 3) // 4, by), (bx + bw, by + 3), (bx + bw, 270)]
        else:
            pts = [(bx, 270), (bx, by + 14), (bx + 6, by + 4), (bx + bw // 2, by), (bx + bw - 6, by + 6), (bx + bw, by + 14), (bx + bw, 270)]

        draw.polygon(pts, fill=SIL_COL, outline=OUTLINE)
        draw.line(pts[1:-1], fill=SIL_RIM, width=1)

        # Protruding bent steel girders on ruined roof
        for gx in range(bx + 6, bx + bw - 6, 10):
            gh = rng.randint(5, 12)
            draw.line([(gx, by + 6), (gx + rng.randint(-2, 2), by + 6 - gh)], fill=GIRDER_COL, width=1)

        if rtype in (1, 3):
            draw_pixel_fire(draw, bx + bw // 2, by + 11, bw // 2, 9, rng, with_smoke=False)

        cols = max(1, (bw - 10) // 6)
        for wy in range(by + 20, 212, 8):
            for c in range(cols):
                wx = bx + 5 + c * 6
                val = rng.random()
                if val > 0.82:
                    draw.rectangle([wx, wy, wx + 3, wy + 3], fill=WIN_FIRE)
                elif val > 0.35:
                    draw.rectangle([wx, wy, wx + 2, wy + 2], fill=WIN_DARK)

    img.save(os.path.join(ENV_DIR, "parallax_skyline_distant.png"))
    print("Saved V2 apocalyptic parallax_skyline_distant.png (480x270)")


def draw_crashed_airplane_on_building(draw, bx, by, bw, rng):
    """
    Draws a sharp, unmistakable commercial airliner crashed into Building 3 (x=118..192).
    Smoke is drawn BEHIND the aircraft so the fuselage, passenger windows, wings, jet engine, and red tail fin are 100% crisp!
    """
    impact_cx = bx + 26
    impact_cy = by + 44

    # 1. Translucent smoke behind the impact zone
    draw_organic_smoke(draw, impact_cx + 4, impact_cy - 6, 36, 26, rng)

    # 2. Gaping jagged impact crater in the building facade
    crater_pts = [
        (bx, impact_cy - 14),
        (bx + 16, impact_cy - 21),
        (bx + 38, impact_cy - 17),
        (bx + 48, impact_cy - 4),
        (bx + 42, impact_cy + 14),
        (bx + 20, impact_cy + 18),
        (bx, impact_cy + 10)
    ]
    draw.polygon(crater_pts, fill=(18, 8, 12, 255), outline=OUTLINE)

    # Exposed bent steel girders inside the crater
    for gx in range(bx + 6, bx + 42, 7):
        draw.line([(gx, impact_cy - 16), (gx + 2, impact_cy + 14)], fill=(70, 52, 60, 255), width=1)
    for gy in range(impact_cy - 10, impact_cy + 12, 7):
        draw.line([(bx + 4, gy), (bx + 40, gy + 2)], fill=(88, 62, 68, 255), width=1)

    # 3. Roaring fire inside the crater (right half of crater)
    draw_pixel_fire(draw, bx + 30, impact_cy + 10, 24, 18, rng, with_smoke=False)

    # 4. Protruding Commercial Airliner Rear Fuselage & Tail Assembly (drawn ON TOP of crater & smoke!)
    FUSE_WHITE = (232, 238, 248, 255)
    FUSE_SILVER = (175, 188, 208, 255)
    FUSE_SHADOW = (96, 108, 130, 255)
    AIRLINE_RED = (232, 45, 66, 255)
    AIRLINE_GOLD = (255, 208, 65, 255)

    # Tall Swept Vertical Tail Fin (Stabilizer) protruding at upper-left
    tail_fin_pts = [
        (bx - 22, impact_cy - 14),
        (bx - 30, impact_cy - 36),
        (bx - 19, impact_cy - 36),
        (bx - 8, impact_cy - 11)
    ]
    draw.polygon(tail_fin_pts, fill=AIRLINE_RED, outline=OUTLINE)
    # Airline tail logo stripes (white & gold diagonal stripes on tail fin)
    draw.line([(bx - 27, impact_cy - 28), (bx - 14, impact_cy - 23)], fill=FUSE_WHITE, width=2)
    draw.line([(bx - 25, impact_cy - 24), (bx - 13, impact_cy - 19)], fill=AIRLINE_GOLD, width=1)

    # Main Cylindrical Airplane Fuselage angled 22° downward into the skyscraper crater
    fuse_pts = [
        (bx - 24, impact_cy - 14),
        (bx + 20, impact_cy - 2),
        (bx + 16, impact_cy + 12),
        (bx - 26, impact_cy - 2)
    ]
    draw.polygon(fuse_pts, fill=FUSE_WHITE, outline=OUTLINE)

    # Lower fuselage belly shadow & red airline cheatline stripe
    belly_pts = [
        (bx - 25, impact_cy - 7),
        (bx + 18, impact_cy + 5),
        (bx + 16, impact_cy + 12),
        (bx - 26, impact_cy - 2)
    ]
    draw.polygon(belly_pts, fill=FUSE_SHADOW, outline=OUTLINE)
    draw.line([(bx - 24, impact_cy - 8), (bx + 18, impact_cy + 4)], fill=AIRLINE_RED, width=2)

    # Row of 8 passenger cabin windows along the upper white fuselage
    for w_idx in range(8):
        wx = bx - 20 + w_idx * 5
        wy = int(impact_cy - 11 + w_idx * 1.35)
        draw.rectangle([wx, wy, wx + 2, wy + 2], fill=(16, 22, 36, 255))

    # Horizontal Rear Tailplane (elevator wing at tail)
    htail_pts = [
        (bx - 22, impact_cy - 7),
        (bx - 33, impact_cy - 1),
        (bx - 25, impact_cy + 2),
        (bx - 14, impact_cy - 5)
    ]
    draw.polygon(htail_pts, fill=FUSE_SILVER, outline=OUTLINE)

    # Torn Main Swept Wing + Under-Wing Jet Turbine Engine Nacelle
    wing_pts = [
        (bx - 4, impact_cy + 1),
        (bx + 12, impact_cy + 5),
        (bx - 6, impact_cy + 24),
        (bx - 16, impact_cy + 20)
    ]
    draw.polygon(wing_pts, fill=FUSE_SILVER, outline=OUTLINE)
    draw.line([(bx - 4, impact_cy + 2), (bx - 14, impact_cy + 20)], fill=FUSE_WHITE, width=1)

    # Jet Engine Pod under the wing
    draw.rectangle([bx - 2, impact_cy + 11, bx + 9, impact_cy + 18], fill=FUSE_SHADOW, outline=OUTLINE)
    draw.ellipse([bx + 6, impact_cy + 11, bx + 11, impact_cy + 18], fill=(18, 20, 28, 255), outline=OUTLINE)

    # Flames licking up around the nose intrusion & burning jet engine
    draw_pixel_fire(draw, bx + 18, impact_cy + 10, 14, 14, rng, with_smoke=False)
    draw_pixel_fire(draw, bx + 3, impact_cy + 19, 10, 10, rng, with_smoke=False)


def build_apocalyptic_mid_skyline():
    """
    Generates res://assets/environment/parallax_buildings_mid.png (480x270)
    """
    img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(2026)

    NAVY_DARK = (22, 26, 46, 255)
    NAVY_SLATE = (30, 36, 62, 255)
    CHARRED_WALL = (16, 15, 26, 255)
    STEEL_GIRDER = (64, 72, 98, 255)
    STEEL_RUST = (118, 58, 48, 255)
    WIN_UNLIT = (11, 13, 24, 255)
    WIN_FIRE_A = (248, 118, 28, 255)
    WIN_FIRE_B = (255, 215, 75, 255)
    NEON_PINK = (230, 57, 98, 255)
    NEON_CYAN = (56, 216, 242, 255)

    mid_buildings = [
        (2, 54, 96, 0, "inferno_tower"),
        (60, 54, 84, 1, "collapsed_half"),
        (120, 72, 72, 0, "airplane_crash"),
        (196, 46, 114, 1, "skeletal_bomb_ruin"),
        (246, 50, 88, 0, "cracked_burning"),
        (300, 44, 136, 1, "collapsed_crane"),
        (348, 66, 76, 0, "side_explosion_crater"),
        (418, 60, 98, 1, "industrial_inferno")
    ]

    for bx, bw, by, st, disaster in mid_buildings:
        bcol = NAVY_DARK if st == 0 else NAVY_SLATE
        roof_y_left = by + (14 if disaster == "inferno_tower" else 0)
        roof_y_right = by + (26 if disaster == "collapsed_half" else (12 if disaster == "cracked_burning" else 0))

        poly = [
            (bx, 270),
            (bx, roof_y_left),
            (bx + bw // 4, by + rng.randint(0, 7)),
            (bx + bw // 2, by + (16 if disaster == "skeletal_bomb_ruin" else rng.randint(2, 10))),
            (bx + (bw * 3) // 4, by + rng.randint(0, 8)),
            (bx + bw, roof_y_right),
            (bx + bw, 270)
        ]
        draw.polygon(poly, fill=bcol, outline=OUTLINE)

        # Exposed steel I-beam girders sticking out of the shattered roof
        for gx in range(bx + 6, bx + bw - 6, 9):
            top_pt_y = max(by, roof_y_left)
            gh = rng.randint(6, 15)
            draw.line([(gx, top_pt_y + 4), (gx, top_pt_y - gh)], fill=STEEL_GIRDER, width=2)
            if rng.random() > 0.4:
                draw.line([(gx - 4, top_pt_y - gh // 2), (gx + 5, top_pt_y - gh // 2 + 2)], fill=STEEL_RUST, width=1)

        # Floor grid with shattered & burning windows
        cols = max(1, (bw - 12) // 8)
        wy = by + 16
        while wy < 214:
            draw.line([(bx + 2, wy - 2), (bx + bw - 3, wy - 2)], fill=CHARRED_WALL)
            for c in range(cols):
                wx = bx + 6 + c * 8
                rval = rng.random()
                if rval > 0.76:
                    draw.rectangle([wx, wy, wx + 4, wy + 6], fill=WIN_FIRE_A)
                    draw.rectangle([wx + 1, wy + 2, wx + 3, wy + 5], fill=WIN_FIRE_B)
                elif rval > 0.18:
                    draw.rectangle([wx, wy, wx + 4, wy + 6], fill=WIN_UNLIT)
                    if rval > 0.55:
                        draw.point((wx + 1, wy + 1), fill=STEEL_GIRDER)
            wy += 10

        if disaster == "inferno_tower":
            draw_pixel_fire(draw, bx + bw // 2, by + 12, bw - 12, 18, rng)
            draw_pixel_fire(draw, bx + bw // 2 - 4, by + 52, 24, 14, rng, with_smoke=False)
            draw_pixel_fire(draw, bx + bw // 2 + 6, by + 90, 22, 13, rng, with_smoke=False)

        elif disaster == "collapsed_half":
            crater = [
                (bx + bw // 2, by + 4),
                (bx + bw + 1, by + 2),
                (bx + bw + 1, by + 54),
                (bx + bw - 16, by + 44),
                (bx + bw // 2 - 4, by + 24)
            ]
            draw.polygon(crater, fill=(0, 0, 0, 0))
            draw.line([(bx + bw // 2, by + 24), (bx + bw, by + 54)], fill=OUTLINE, width=2)
            draw.line([(bx + bw // 2, by + 24), (bx + bw - 2, by + 24)], fill=STEEL_RUST, width=2)
            draw.line([(bx + bw - 14, by + 12), (bx + bw - 14, by + 46)], fill=STEEL_GIRDER, width=2)
            draw.polygon([(bx + 6, by), (bx + 20, by - 4), (bx + 22, by - 15), (bx + 4, by - 11)], fill=(58, 38, 44, 255), outline=OUTLINE)
            draw_pixel_fire(draw, bx + bw - 14, by + 46, 20, 14, rng)

        elif disaster == "airplane_crash":
            draw_crashed_airplane_on_building(draw, bx, by, bw, rng)
            draw_pixel_fire(draw, bx + bw - 16, by + 8, 22, 14, rng)

        elif disaster == "skeletal_bomb_ruin":
            hole_poly = [
                (bx + 8, by + 28), (bx + 18, by + 23), (bx + bw - 9, by + 27),
                (bx + bw - 7, by + 46), (bx + bw - 18, by + 53), (bx + 11, by + 49)
            ]
            draw.polygon(hole_poly, fill=(16, 12, 22, 245), outline=OUTLINE)
            draw.line([(bx + 11, by + 27), (bx + bw - 11, by + 49)], fill=STEEL_GIRDER, width=2)
            draw.line([(bx + bw - 11, by + 27), (bx + 11, by + 49)], fill=STEEL_GIRDER, width=2)
            draw.polygon([(bx + 4, by - 10), (bx + 32, by - 2), (bx + 29, by + 9), (bx + 1, by + 1)], fill=(20, 14, 28, 255), outline=NEON_PINK)
            draw_pixel_fire(draw, bx + bw // 2, by + 50, 20, 14, rng, with_smoke=False)

        elif disaster == "cracked_burning":
            crack_pts = [
                (bx + bw // 2, by + 4),
                (bx + bw // 2 - 6, by + 35),
                (bx + bw // 2 + 5, by + 68),
                (bx + bw // 2 - 4, by + 102),
                (bx + bw // 2 + 2, 215)
            ]
            draw.line(crack_pts, fill=OUTLINE, width=4)
            draw.line(crack_pts, fill=(255, 95, 28, 220), width=1)
            draw_pixel_fire(draw, bx + bw // 2, by + 10, 24, 15, rng)
            draw_pixel_fire(draw, bx + bw // 2 - 3, by + 68, 18, 12, rng, with_smoke=False)

        elif disaster == "collapsed_crane":
            draw.line([(bx + 6, by), (bx + 42, by - 22)], fill=(195, 138, 38, 255), width=3)
            draw.line([(bx + 10, by), (bx + 42, by - 22)], fill=OUTLINE, width=1)
            draw.line([(bx + 42, by - 22), (bx + 46, by + 12)], fill=(90, 95, 110, 255), width=1)
            draw_pixel_fire(draw, bx + 20, by + 6, 22, 13, rng)

        elif disaster == "side_explosion_crater":
            side_crater = [
                (bx + bw + 1, by + 26),
                (bx + bw - 22, by + 34),
                (bx + bw - 26, by + 52),
                (bx + bw - 14, by + 64),
                (bx + bw + 1, by + 70)
            ]
            draw.polygon(side_crater, fill=(0, 0, 0, 0))
            draw.line([(bx + bw, by + 26), (bx + bw - 22, by + 34), (bx + bw - 26, by + 52), (bx + bw - 14, by + 64), (bx + bw, by + 70)], fill=OUTLINE, width=2)
            draw.line([(bx + bw - 18, by + 32), (bx + bw - 18, by + 64)], fill=STEEL_GIRDER, width=2)
            draw_pixel_fire(draw, bx + bw - 16, by + 60, 20, 15, rng, with_smoke=False)
            draw.rectangle([bx + 8, by - 14, bx + 46, by - 2], fill=(18, 14, 28, 255), outline=NEON_CYAN)
            draw_pixel_fire(draw, bx + 26, by - 2, 24, 14, rng)

        elif disaster == "industrial_inferno":
            draw.polygon([(bx + 12, by), (bx + 8, by - 20), (bx + 15, by - 20), (bx + 18, by)], fill=STEEL_RUST, outline=OUTLINE)
            draw.polygon([(bx + 28, by), (bx + 36, by - 16), (bx + 42, by - 14), (bx + 34, by)], fill=STEEL_RUST, outline=OUTLINE)
            draw_pixel_fire(draw, bx + 11, by - 18, 12, 12, rng)
            draw_pixel_fire(draw, bx + 34, by + 40, 24, 15, rng, with_smoke=False)

    img.save(os.path.join(ENV_DIR, "parallax_buildings_mid.png"))
    print("Saved V2 apocalyptic parallax_buildings_mid.png (480x270)")


def build_apocalyptic_foreground_overpass():
    """
    Generates res://assets/environment/parallax_overpass_fore.png (480x270)
    """
    img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(909)

    RAIL_DARK = (36, 26, 38, 255)
    RAIL_HI = (88, 62, 76, 255)
    RAIL_RIDGE = (62, 44, 54, 255)
    POLE_COL = (24, 28, 44, 255)
    POLE_HI = (56, 64, 96, 255)
    LAMP_AMBER = (242, 140, 56, 255)
    LAMP_CORE = (255, 243, 176, 255)

    for cx in [64, 180, 355]:
        car_pts = [
            (cx, 214), (cx + 4, 202), (cx + 13, 195),
            (cx + 31, 195), (cx + 39, 202), (cx + 46, 205), (cx + 46, 214)
        ]
        draw.polygon(car_pts, fill=(24, 20, 28, 255), outline=OUTLINE)
        draw.polygon([(cx + 14, 197), (cx + 22, 197), (cx + 22, 203), (cx + 11, 203)], fill=(255, 110, 28, 235))
        draw.polygon([(cx + 24, 197), (cx + 30, 197), (cx + 35, 203), (cx + 24, 203)], fill=(255, 165, 50, 235))
        draw_pixel_fire(draw, cx + 26, 198, 18, 13, rng)

    breach_ranges = [(148, 174), (305, 332)]
    for x in range(480):
        in_breach = any(b0 <= x <= b1 for b0, b1 in breach_ranges)
        if not in_breach:
            img.putpixel((x, 212), OUTLINE)
            img.putpixel((x, 213), RAIL_HI)
            img.putpixel((x, 214), RAIL_RIDGE)
            img.putpixel((x, 215), (24, 17, 26, 255))
            img.putpixel((x, 216), RAIL_RIDGE)
            img.putpixel((x, 217), RAIL_DARK)
            img.putpixel((x, 218), OUTLINE)
        else:
            drop = int(math.sin((x % 26) * 0.25) * 5)
            img.putpixel((x, 215 + drop), OUTLINE)
            img.putpixel((x, 216 + drop), RAIL_HI)
            img.putpixel((x, 217 + drop), RAIL_DARK)
            img.putpixel((x, 218 + drop), OUTLINE)

    for gx in range(0, 480, 24):
        for y in range(210, 224):
            img.putpixel((gx, y), OUTLINE)
            img.putpixel((gx + 1, y), (46, 34, 48, 255))
            img.putpixel((gx + 2, y), (70, 50, 72, 255))
            img.putpixel((gx + 3, y), OUTLINE)
        draw.rectangle([gx - 2, 224, gx + 5, 227], fill=(52, 40, 56, 255), outline=OUTLINE)

    lamp_xs = [36, 132, 228, 324, 420]
    for idx, lx in enumerate(lamp_xs):
        for y in range(142, 223):
            img.putpixel((lx, y), OUTLINE)
            img.putpixel((lx + 1, y), POLE_COL)
            img.putpixel((lx + 2, y), POLE_HI)
            img.putpixel((lx + 3, y), OUTLINE)
        draw.rectangle([lx - 3, 223, lx + 6, 227], fill=(42, 50, 76, 255), outline=OUTLINE)
        draw.rectangle([lx, 140, lx + 18, 143], fill=POLE_COL, outline=OUTLINE)
        draw.rectangle([lx + 12, 142, lx + 21, 147], fill=POLE_COL, outline=OUTLINE)
        draw.rectangle([lx + 13, 145, lx + 20, 147], fill=LAMP_AMBER)
        draw.rectangle([lx + 14, 145, lx + 19, 146], fill=LAMP_CORE)

        if idx < len(lamp_xs) - 1:
            nx = lamp_xs[idx + 1]
            for cx_p in range(lx + 3, nx):
                t = (cx_p - (lx + 3)) / float(nx - (lx + 3))
                sag = int(math.sin(t * math.pi) * 18)
                if not (0.45 < t < 0.58 and idx % 2 == 1):
                    img.putpixel((cx_p, 144 + sag), OUTLINE)

    img.save(os.path.join(ENV_DIR, "parallax_overpass_fore.png"))
    print("Saved V2 apocalyptic parallax_overpass_fore.png (480x270)")


def build_collapsed_bridge_pit_asset():
    """
    Generates res://assets/environment/collapsed_bridge_pit.png (80x64)
    A crystal-clear Collapsed Bridge ("Jembatan Roboh") rendered inside every 80px road pit/hole ("lubang").
    No opaque smoke clouds blocking the broken central pier or the collapsed asphalt bridge decks!
    """
    w, h = 80, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(404)

    ABYSS_DARK = (10, 12, 20, 255)
    ABYSS_MID = (20, 24, 38, 255)
    CONCRETE_LIGHT = (138, 146, 166, 255)
    CONCRETE_MID = (86, 94, 112, 255)
    CONCRETE_DARK = (46, 52, 66, 255)
    ASPHALT_DARK = (32, 36, 48, 255)
    YELLOW_DASH = (255, 207, 86, 255)
    TRUSS_RED = (165, 52, 44, 255)
    TRUSS_HI = (218, 82, 64, 255)
    TRUSS_SH = (92, 28, 28, 255)
    REBAR_STEEL = (175, 186, 204, 255)

    # 1. Deep chasm background (y = 8..63)
    draw.rectangle([0, 8, w - 1, h - 1], fill=ABYSS_DARK)

    # Background steel arch/truss skeleton in the chasm depths
    for tx in range(8, w - 8, 12):
        draw.line([(tx, 14), (tx + 12, 50)], fill=ABYSS_MID, width=1)
        draw.line([(tx + 12, 14), (tx, 50)], fill=ABYSS_MID, width=1)
    draw.line([(4, 22), (w - 5, 22)], fill=ABYSS_MID, width=2)

    # 2. Central Collapsed Concrete Bridge Pier (Tiang Penyangga Jembatan yang Patah di Tengah)
    pier_x = 33
    pier_pts = [
        (pier_x, 54),
        (pier_x + 2, 24),
        (pier_x + 6, 28),
        (pier_x + 10, 23),
        (pier_x + 14, 27),
        (pier_x + 15, 54)
    ]
    draw.polygon(pier_pts, fill=CONCRETE_MID, outline=OUTLINE)
    draw.polygon([(pier_x + 8, 25), (pier_x + 14, 27), (pier_x + 15, 54), (pier_x + 8, 54)], fill=CONCRETE_DARK)
    draw.line([(pier_x + 3, 26), (pier_x + 2, 52)], fill=CONCRETE_LIGHT, width=1)
    # Structural crack on central pier & bent rebar sticking out of broken top
    draw.line([(pier_x + 7, 26), (pier_x + 5, 38), (pier_x + 9, 46)], fill=OUTLINE, width=1)
    for rx in [pier_x + 3, pier_x + 7, pier_x + 11]:
        draw.line([(rx, 24), (rx + rng.randint(-2, 2), 17)], fill=REBAR_STEEL, width=1)

    # 3. Left & Right Broken Bridge Abutment Piers (x = 0..6 and x = 73..79)
    draw.polygon([(0, 8), (6, 8), (8, 22), (5, 38), (7, 54), (0, 54)], fill=CONCRETE_MID, outline=OUTLINE)
    draw.polygon([(w - 1, 8), (w - 7, 8), (w - 9, 20), (w - 6, 36), (w - 8, 54), (w - 1, 54)], fill=CONCRETE_MID, outline=OUTLINE)

    # Protruding horizontal bent steel rebar at broken road edges
    for ry in [11, 15, 19]:
        draw.line([(5, ry), (14, ry + 2)], fill=REBAR_STEEL, width=1)
        draw.line([(w - 6, ry), (w - 15, ry + 2)], fill=REBAR_STEEL, width=1)

    # 4. LEFT COLLAPSED BRIDGE DECK & RED STEEL TRUSS GIRDER (Slanted downward into chasm!)
    left_truss_pts = [(2, 16), (32, 41), (28, 48), (2, 26)]
    draw.polygon(left_truss_pts, fill=TRUSS_SH, outline=OUTLINE)
    draw.line([(3, 16), (31, 41)], fill=TRUSS_RED, width=2)
    draw.line([(3, 25), (28, 47)], fill=TRUSS_RED, width=2)
    for step in range(4):
        sx0 = 4 + step * 7
        sy0 = 17 + step * 6
        draw.line([(sx0, sy0), (sx0 - 2, sy0 + 7)], fill=TRUSS_HI, width=1)
        draw.line([(sx0, sy0), (sx0 + 5, sy0 + 11)], fill=TRUSS_HI, width=1)

    left_deck_pts = [(1, 8), (35, 36), (31, 41), (1, 16)]
    draw.polygon(left_deck_pts, fill=ASPHALT_DARK, outline=OUTLINE)
    draw.line([(2, 9), (34, 36)], fill=CONCRETE_LIGHT, width=1)
    draw.line([(7, 15), (18, 24)], fill=YELLOW_DASH, width=2)
    draw.line([(23, 28), (31, 35)], fill=YELLOW_DASH, width=2)

    # 5. RIGHT COLLAPSED BRIDGE DECK & RED STEEL TRUSS GIRDER (Slanted downward from right edge!)
    right_truss_pts = [(w - 3, 17), (47, 42), (51, 48), (w - 3, 27)]
    draw.polygon(right_truss_pts, fill=TRUSS_SH, outline=OUTLINE)
    draw.line([(w - 4, 17), (48, 42)], fill=TRUSS_RED, width=2)
    draw.line([(w - 4, 26), (51, 47)], fill=TRUSS_RED, width=2)
    for step in range(4):
        sx0 = (w - 6) - step * 7
        sy0 = 18 + step * 6
        draw.line([(sx0, sy0), (sx0 + 2, sy0 + 7)], fill=TRUSS_HI, width=1)
        draw.line([(sx0, sy0), (sx0 - 5, sy0 + 11)], fill=TRUSS_HI, width=1)

    right_deck_pts = [(w - 2, 8), (44, 38), (48, 43), (w - 2, 16)]
    draw.polygon(right_deck_pts, fill=ASPHALT_DARK, outline=OUTLINE)
    draw.line([(w - 3, 9), (45, 38)], fill=CONCRETE_LIGHT, width=1)
    draw.line([(w - 8, 16), (w - 19, 25)], fill=YELLOW_DASH, width=2)
    draw.line([(w - 24, 29), (47, 38)], fill=YELLOW_DASH, width=2)

    # 6. Snapped Suspension Cables & Broken Guardrail Posts at top left & right edges (y = 1..9)
    draw.rectangle([2, 2, 5, 9], fill=TRUSS_RED, outline=OUTLINE)
    draw.rectangle([w - 6, 2, w - 3, 9], fill=TRUSS_RED, outline=OUTLINE)
    draw.line([(4, 3), (12, 13), (17, 23)], fill=REBAR_STEEL, width=1)
    draw.line([(w - 5, 3), (w - 13, 14), (w - 17, 25)], fill=REBAR_STEEL, width=1)

    # 7. Crisp flickering flames & glowing rubble at the bottom of the collapsed bridge (NO smoke blob covering the bridge!)
    draw_pixel_fire(draw, 40, 53, 22, 10, rng, with_smoke=False)

    img.save(os.path.join(ENV_DIR, "collapsed_bridge_pit.png"))
    print("Saved V2 collapsed_bridge_pit.png (80x64)")


if __name__ == "__main__":
    build_apocalyptic_distant_skyline()
    build_apocalyptic_mid_skyline()
    build_apocalyptic_foreground_overpass()
    build_collapsed_bridge_pit_asset()
    print("=== V2 APOCALYPTIC CHAOS CITY & COLLAPSED BRIDGE ASSETS GENERATED ===")
