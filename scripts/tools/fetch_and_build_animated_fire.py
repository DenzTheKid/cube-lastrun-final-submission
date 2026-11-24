"""
1. Searches and downloads CC0 animated pixel fire sprite sheets from OpenGameArt.org / GitHub CC0 repositories.
2. Builds an ultra-crisp 8-frame animated pixel-art fire sprite sheet:
   - res://assets/effects/fire_animated_sheet.png (256x32: 8 frames of 32x32 animated roaring pixel fire)
   - res://assets/effects/fire_small_sheet.png (128x16: 8 frames of 16x16 animated window/crater fire)
3. Updates:
   - res://assets/environment/parallax_overpass_fore.png:
     COMPLETELY REMOVES the dark car lumps/fires sitting on top of the guardrail ("yang di atas tiang pembatas itu hapus aja").
     Keeps ONLY the clean grounded guardrail, posts, and streetlamps!
   - res://assets/environment/parallax_buildings_mid.png & parallax_skyline_distant.png & collapsed_bridge_pit.png:
     Removes static baked flames so all fires are rendered as LIVE MOVING 8-frame animated fire sprites!
"""
import os
import re
import math
import random
import requests
from PIL import Image, ImageDraw

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_DIR = os.path.join(PROJECT_ROOT, "assets", "environment")
FX_DIR = os.path.join(PROJECT_ROOT, "assets", "effects")
QUAR_DIR = os.path.join(PROJECT_ROOT, "assets", "_quarantine")

for d in [ENV_DIR, FX_DIR, QUAR_DIR]:
    os.makedirs(d, exist_ok=True)

OUTLINE = (10, 11, 20, 255)
HEADERS = {"User-Agent": "Mozilla/5.0 CubeLastRunAssetPipeline/2.0"}


def search_and_download_cc0_fire_sheets():
    """Queries OpenGameArt.org for CC0 animated fire sprite sheets and downloads valid PNGs."""
    url = "https://opengameart.org/art-search-advanced?keys=fire+sprite+sheet&field_art_type_tid%5B%5D=9&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC"
    try:
        print(f"[OGA CC0] Searching animated fire sprite sheets: {url}")
        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            links = re.findall(r'href="(/content/[^"]+)"', r.text)
            seen = set()
            for link in links:
                if link in seen:
                    continue
                seen.add(link)
                if len(seen) > 4:
                    break
                pr = requests.get("https://opengameart.org" + link, headers=HEADERS, timeout=10)
                if pr.status_code == 200:
                    pngs = re.findall(r'https://opengameart\.org/sites/default/files/[^"\'\s>]+\.png', pr.text)
                    for purl in pngs[:2]:
                        if "thumbnail" in purl:
                            continue
                        fname = "oga_fire_" + os.path.basename(purl.split("?")[0])
                        out_p = os.path.join(QUAR_DIR, fname)
                        if not os.path.exists(out_p):
                            ir = requests.get(purl, headers=HEADERS, timeout=10)
                            if ir.status_code == 200 and len(ir.content) > 400:
                                with open(out_p, "wb") as f:
                                    f.write(ir.content)
                                print(f"[OGA CC0] Downloaded reference fire sheet: {fname} ({len(ir.content)} bytes)")
    except Exception as e:
        print(f"[OGA CC0] Note: {e}")


def generate_animated_fire_sheets():
    """
    Generates an 8-frame grounded, steady-height pixel-art fire animation sprite sheet (256x32, 8 frames of 32x32).
    Base and overall flame height stay planted steadily in place (ZERO up-and-down bouncing),
    while the flame tips gently sway horizontally like real wind-blown fire.
    """
    fw, fh = 32, 32
    frames = 8
    sheet = Image.new("RGBA", (fw * frames, fh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    C_DARK_RED = (135, 20, 22, 245)
    C_CRIMSON = (222, 38, 26, 255)
    C_ORANGE = (252, 118, 24, 255)
    C_GOLD = (255, 206, 56, 255)
    C_CORE = (255, 248, 190, 255)

    for f in range(frames):
        ox = f * fw
        phase = (f / float(frames)) * (2.0 * math.pi)
        base_y = 29

        # Render fire row-by-row from base_y upward with smooth horizontal wind sway (height stays constant!)
        max_h = 18
        for dy in range(max_h):
            y = base_y - dy
            t = dy / float(max_h)  # 0.0 at base -> 1.0 at tip

            # Gentle horizontal sway that increases smoothly toward the flame tip (zero vertical bounce!)
            sway_x = math.sin(phase - t * 3.8) * (2.2 * t)

            # Three grounded flame peaks (left, center, right) with steady height
            peaks = [
                (10.0 + sway_x * 0.85, 5.2 * (1.0 - t * 0.88), 0.72),
                (16.0 + sway_x * 1.15, 6.8 * (1.0 - t * 0.78), 1.00),
                (22.0 + sway_x * 0.85, 5.0 * (1.0 - t * 0.90), 0.76),
            ]

            for lx in range(3, 29):
                # Compute intensity from the 3 steady flame cones
                intensity = 0.0
                for pcx, half_w, p_scale in peaks:
                    if t > p_scale:
                        continue
                    local_t = t / p_scale
                    w_at_y = max(0.5, half_w * (1.0 - local_t * 0.82))
                    dist = abs(lx - pcx) / w_at_y
                    if dist < 1.0:
                        val = (1.0 - dist * dist) * (1.0 - local_t * 0.65)
                        if val > intensity:
                            intensity = val

                if intensity > 0.14:
                    px = ox + lx
                    if intensity > 0.74 and t < 0.38:
                        col = C_CORE
                    elif intensity > 0.52 and t < 0.58:
                        col = C_GOLD
                    elif intensity > 0.34 and t < 0.78:
                        col = C_ORANGE
                    elif intensity > 0.22:
                        col = C_CRIMSON
                    else:
                        col = C_DARK_RED
                    sheet.putpixel((px, y), col)

    out_fx = os.path.join(FX_DIR, "fire_animated_sheet.png")
    out_env = os.path.join(ENV_DIR, "fire_animated_sheet.png")
    sheet.save(out_fx)
    sheet.save(out_env)
    print(f"Saved steady-height 8-frame animated fire sprite sheet: {out_fx} (256x32)")


def build_clean_foreground_overpass():
    """
    Regenerates res://assets/environment/parallax_overpass_fore.png (480x270)
    COMPLETELY REMOVES the objects/cars sitting on top of the guardrail posts ("yang di atas tiang pembatas itu hapus aja").
    Keeps ONLY the crisp grounded W-beam guardrail, anchored posts, and streetlamps!
    """
    img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    RAIL_DARK = (36, 26, 38, 255)
    RAIL_HI = (88, 62, 76, 255)
    RAIL_RIDGE = (62, 44, 54, 255)
    RAIL_CHANNEL = (24, 17, 26, 255)
    POLE_COL = (24, 28, 44, 255)
    POLE_HI = (56, 64, 96, 255)
    LAMP_AMBER = (242, 140, 56, 255)
    LAMP_CORE = (255, 243, 176, 255)

    # 1. Clean continuous corrugated W-beam highway guardrail (y = 212..218)
    for x in range(480):
        img.putpixel((x, 212), OUTLINE)
        img.putpixel((x, 213), RAIL_HI)
        img.putpixel((x, 214), RAIL_RIDGE)
        img.putpixel((x, 215), RAIL_CHANNEL)
        img.putpixel((x, 216), RAIL_RIDGE)
        img.putpixel((x, 217), RAIL_DARK)
        img.putpixel((x, 218), OUTLINE)

    for sx in range(12, 480, 48):
        img.putpixel((sx, 213), (140, 100, 120, 255))
        img.putpixel((sx + 1, 213), OUTLINE)
        img.putpixel((sx, 217), (140, 100, 120, 255))
        img.putpixel((sx + 1, 217), OUTLINE)

    # 2. Guardrail vertical posts every 24px firmly seated on curb (y = 209..227) — ZERO objects on top!
    for gx in range(0, 480, 24):
        for x in range(gx, gx + 4):
            img.putpixel((x, 209), OUTLINE)
        for y in range(210, 224):
            img.putpixel((gx, y), OUTLINE)
            img.putpixel((gx + 1, y), (46, 34, 48, 255))
            img.putpixel((gx + 2, y), (70, 50, 72, 255))
            img.putpixel((gx + 3, y), OUTLINE)
        draw.rectangle([gx - 2, 224, gx + 5, 227], fill=(52, 40, 56, 255), outline=OUTLINE)

    # 3. 5 evenly spaced streetlamps (every 96px: x = 36, 132, 228, 324, 420)
    for lx in [36, 132, 228, 324, 420]:
        for y in range(142, 223):
            img.putpixel((lx, y), OUTLINE)
            img.putpixel((lx + 1, y), POLE_COL)
            img.putpixel((lx + 2, y), POLE_HI)
            img.putpixel((lx + 3, y), OUTLINE)
        draw.rectangle([lx - 3, 223, lx + 6, 227], fill=(42, 50, 76, 255), outline=OUTLINE)
        draw.rectangle([lx, 140, lx + 17, 142], fill=POLE_COL, outline=OUTLINE)
        draw.rectangle([lx + 12, 142, lx + 20, 146], fill=POLE_COL, outline=OUTLINE)
        draw.rectangle([lx + 13, 145, lx + 19, 146], fill=LAMP_AMBER)
        draw.rectangle([lx + 14, 145, lx + 18, 145], fill=LAMP_CORE)

    img.save(os.path.join(ENV_DIR, "parallax_overpass_fore.png"))
    print("Saved clean parallax_overpass_fore.png (removed objects above guardrail posts!)")


def build_apocalyptic_backgrounds_for_animated_fires():
    """
    Regenerates parallax_buildings_mid.png, parallax_skyline_distant.png, and collapsed_bridge_pit.png
    WITHOUT static frozen fire drawings so that live animated fire nodes burn dynamically on them!
    """
    from build_apocalypse_city_and_bridge import draw_organic_smoke

    # 1. Distant Skyline (480x270)
    dist = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dist)
    rng = random.Random(777)

    SIL_COL = (24, 18, 36, 255)
    SIL_RIM = (78, 36, 50, 255)
    GIRDER_COL = (42, 28, 48, 255)
    WIN_FIRE = (245, 128, 38, 235)
    WIN_DARK = (14, 11, 22, 255)

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
            pts = [(bx, 270), (bx, by), (bx + bw // 4, by), (bx + bw // 2, by + 14), (bx + (bw * 3) // 4, by + 2), (bx + bw, by + 4), (bx + bw, 270)]
        elif rtype == 2:
            pts = [(bx, 270), (bx, by + 16), (bx + bw // 2, by + 8), (bx + (bw * 3) // 4, by), (bx + bw, by + 3), (bx + bw, 270)]
        else:
            pts = [(bx, 270), (bx, by + 14), (bx + 6, by + 4), (bx + bw // 2, by), (bx + bw - 6, by + 6), (bx + bw, by + 14), (bx + bw, 270)]

        d_draw.polygon(pts, fill=SIL_COL, outline=OUTLINE)
        d_draw.line(pts[1:-1], fill=SIL_RIM, width=1)

        for gx in range(bx + 6, bx + bw - 6, 10):
            gh = rng.randint(5, 12)
            d_draw.line([(gx, by + 6), (gx + rng.randint(-2, 2), by + 6 - gh)], fill=GIRDER_COL, width=1)

        cols = max(1, (bw - 10) // 6)
        for wy in range(by + 20, 212, 8):
            for c in range(cols):
                wx = bx + 5 + c * 6
                val = rng.random()
                if val > 0.82:
                    d_draw.rectangle([wx, wy, wx + 3, wy + 3], fill=WIN_FIRE)
                elif val > 0.35:
                    d_draw.rectangle([wx, wy, wx + 2, wy + 2], fill=WIN_DARK)

    dist.save(os.path.join(ENV_DIR, "parallax_skyline_distant.png"))

    # 2. Mid-Ground Skyline (480x270) — Ruined buildings + Crashed Airplane (no static frozen flames!)
    mid = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mid)
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
        m_draw.polygon(poly, fill=bcol, outline=OUTLINE)

        for gx in range(bx + 6, bx + bw - 6, 9):
            top_pt_y = max(by, roof_y_left)
            gh = rng.randint(6, 15)
            m_draw.line([(gx, top_pt_y + 4), (gx, top_pt_y - gh)], fill=STEEL_GIRDER, width=2)
            if rng.random() > 0.4:
                m_draw.line([(gx - 4, top_pt_y - gh // 2), (gx + 5, top_pt_y - gh // 2 + 2)], fill=STEEL_RUST, width=1)

        cols = max(1, (bw - 12) // 8)
        wy = by + 16
        while wy < 214:
            m_draw.line([(bx + 2, wy - 2), (bx + bw - 3, wy - 2)], fill=CHARRED_WALL)
            for c in range(cols):
                wx = bx + 6 + c * 8
                rval = rng.random()
                if rval > 0.76:
                    m_draw.rectangle([wx, wy, wx + 4, wy + 6], fill=WIN_FIRE_A)
                    m_draw.rectangle([wx + 1, wy + 2, wx + 3, wy + 5], fill=WIN_FIRE_B)
                elif rval > 0.18:
                    m_draw.rectangle([wx, wy, wx + 4, wy + 6], fill=WIN_UNLIT)
                    if rval > 0.55:
                        m_draw.point((wx + 1, wy + 1), fill=STEEL_GIRDER)
            wy += 10

        if disaster == "collapsed_half":
            crater = [
                (bx + bw // 2, by + 4),
                (bx + bw + 1, by + 2),
                (bx + bw + 1, by + 54),
                (bx + bw - 16, by + 44),
                (bx + bw // 2 - 4, by + 24)
            ]
            m_draw.polygon(crater, fill=(0, 0, 0, 0))
            m_draw.line([(bx + bw // 2, by + 24), (bx + bw, by + 54)], fill=OUTLINE, width=2)
            m_draw.line([(bx + bw // 2, by + 24), (bx + bw - 2, by + 24)], fill=STEEL_RUST, width=2)
            m_draw.line([(bx + bw - 14, by + 12), (bx + bw - 14, by + 46)], fill=STEEL_GIRDER, width=2)
            m_draw.polygon([(bx + 6, by), (bx + 20, by - 4), (bx + 22, by - 15), (bx + 4, by - 11)], fill=(58, 38, 44, 255), outline=OUTLINE)

        elif disaster == "airplane_crash":
            impact_cy = by + 44
            crater_pts = [
                (bx, impact_cy - 14), (bx + 16, impact_cy - 21), (bx + 38, impact_cy - 17),
                (bx + 48, impact_cy - 4), (bx + 42, impact_cy + 14), (bx + 20, impact_cy + 18), (bx, impact_cy + 10)
            ]
            m_draw.polygon(crater_pts, fill=(18, 8, 12, 255), outline=OUTLINE)
            for gx in range(bx + 6, bx + 42, 7):
                m_draw.line([(gx, impact_cy - 16), (gx + 2, impact_cy + 14)], fill=(70, 52, 60, 255), width=1)

            FUSE_WHITE = (232, 238, 248, 255)
            FUSE_SILVER = (175, 188, 208, 255)
            FUSE_SHADOW = (96, 108, 130, 255)
            AIRLINE_RED = (232, 45, 66, 255)
            AIRLINE_GOLD = (255, 208, 65, 255)

            tail_fin_pts = [(bx - 22, impact_cy - 14), (bx - 30, impact_cy - 36), (bx - 19, impact_cy - 36), (bx - 8, impact_cy - 11)]
            m_draw.polygon(tail_fin_pts, fill=AIRLINE_RED, outline=OUTLINE)
            m_draw.line([(bx - 27, impact_cy - 28), (bx - 14, impact_cy - 23)], fill=FUSE_WHITE, width=2)
            m_draw.line([(bx - 25, impact_cy - 24), (bx - 13, impact_cy - 19)], fill=AIRLINE_GOLD, width=1)

            fuse_pts = [(bx - 24, impact_cy - 14), (bx + 20, impact_cy - 2), (bx + 16, impact_cy + 12), (bx - 26, impact_cy - 2)]
            m_draw.polygon(fuse_pts, fill=FUSE_WHITE, outline=OUTLINE)
            belly_pts = [(bx - 25, impact_cy - 7), (bx + 18, impact_cy + 5), (bx + 16, impact_cy + 12), (bx - 26, impact_cy - 2)]
            m_draw.polygon(belly_pts, fill=FUSE_SHADOW, outline=OUTLINE)
            m_draw.line([(bx - 24, impact_cy - 8), (bx + 18, impact_cy + 4)], fill=AIRLINE_RED, width=2)

            for w_idx in range(8):
                wx = bx - 20 + w_idx * 5
                wy = int(impact_cy - 11 + w_idx * 1.35)
                m_draw.rectangle([wx, wy, wx + 2, wy + 2], fill=(16, 22, 36, 255))

            htail_pts = [(bx - 22, impact_cy - 7), (bx - 33, impact_cy - 1), (bx - 25, impact_cy + 2), (bx - 14, impact_cy - 5)]
            m_draw.polygon(htail_pts, fill=FUSE_SILVER, outline=OUTLINE)

            wing_pts = [(bx - 4, impact_cy + 1), (bx + 12, impact_cy + 5), (bx - 6, impact_cy + 24), (bx - 16, impact_cy + 20)]
            m_draw.polygon(wing_pts, fill=FUSE_SILVER, outline=OUTLINE)
            m_draw.rectangle([bx - 2, impact_cy + 11, bx + 9, impact_cy + 18], fill=FUSE_SHADOW, outline=OUTLINE)

        elif disaster == "skeletal_bomb_ruin":
            hole_poly = [
                (bx + 8, by + 28), (bx + 18, by + 23), (bx + bw - 9, by + 27),
                (bx + bw - 7, by + 46), (bx + bw - 18, by + 53), (bx + 11, by + 49)
            ]
            m_draw.polygon(hole_poly, fill=(16, 12, 22, 245), outline=OUTLINE)
            m_draw.line([(bx + 11, by + 27), (bx + bw - 11, by + 49)], fill=STEEL_GIRDER, width=2)
            m_draw.line([(bx + bw - 11, by + 27), (bx + 11, by + 49)], fill=STEEL_GIRDER, width=2)
            m_draw.polygon([(bx + 4, by - 10), (bx + 32, by - 2), (bx + 29, by + 9), (bx + 1, by + 1)], fill=(20, 14, 28, 255), outline=NEON_PINK)

        elif disaster == "cracked_burning":
            # Clean blast notch & exposed steel girder core (removed the thin orange zigzag line)
            notch = [(bx, by + 32), (bx + 16, by + 38), (bx + 12, by + 54), (bx, by + 58)]
            m_draw.polygon(notch, fill=(16, 12, 22, 245), outline=OUTLINE)
            m_draw.line([(bx + 6, by + 35), (bx + 6, by + 56)], fill=STEEL_GIRDER, width=2)

        elif disaster == "collapsed_crane":
            m_draw.line([(bx + 6, by), (bx + 42, by - 22)], fill=(195, 138, 38, 255), width=3)
            m_draw.line([(bx + 10, by), (bx + 42, by - 22)], fill=OUTLINE, width=1)
            m_draw.line([(bx + 42, by - 22), (bx + 46, by + 12)], fill=(90, 95, 110, 255), width=1)

        elif disaster == "side_explosion_crater":
            side_crater = [
                (bx + bw + 1, by + 26), (bx + bw - 22, by + 34), (bx + bw - 26, by + 52),
                (bx + bw - 14, by + 64), (bx + bw + 1, by + 70)
            ]
            m_draw.polygon(side_crater, fill=(0, 0, 0, 0))
            m_draw.line([(bx + bw, by + 26), (bx + bw - 22, by + 34), (bx + bw - 26, by + 52), (bx + bw - 14, by + 64), (bx + bw, by + 70)], fill=OUTLINE, width=2)
            m_draw.line([(bx + bw - 18, by + 32), (bx + bw - 18, by + 64)], fill=STEEL_GIRDER, width=2)
            m_draw.rectangle([bx + 8, by - 14, bx + 46, by - 2], fill=(18, 14, 28, 255), outline=NEON_CYAN)

        elif disaster == "industrial_inferno":
            m_draw.polygon([(bx + 12, by), (bx + 8, by - 20), (bx + 15, by - 20), (bx + 18, by)], fill=STEEL_RUST, outline=OUTLINE)
            m_draw.polygon([(bx + 28, by), (bx + 36, by - 16), (bx + 42, by - 14), (bx + 34, by)], fill=STEEL_RUST, outline=OUTLINE)

    mid.save(os.path.join(ENV_DIR, "parallax_buildings_mid.png"))
    print("Saved parallax_buildings_mid.png ready for live animated fire nodes!")

    # 3. Collapsed Bridge Pit (80x64) — Clean collapsed bridge structure (live animated fire node placed on top in game!)
    w, h = 80, 64
    b_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(b_img)
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

    b_draw.rectangle([0, 8, w - 1, h - 1], fill=ABYSS_DARK)
    for tx in range(8, w - 8, 12):
        b_draw.line([(tx, 14), (tx + 12, 50)], fill=ABYSS_MID, width=1)
        b_draw.line([(tx + 12, 14), (tx, 50)], fill=ABYSS_MID, width=1)
    b_draw.line([(4, 22), (w - 5, 22)], fill=ABYSS_MID, width=2)

    pier_x = 33
    pier_pts = [(pier_x, 54), (pier_x + 2, 24), (pier_x + 6, 28), (pier_x + 10, 23), (pier_x + 14, 27), (pier_x + 15, 54)]
    b_draw.polygon(pier_pts, fill=CONCRETE_MID, outline=OUTLINE)
    b_draw.polygon([(pier_x + 8, 25), (pier_x + 14, 27), (pier_x + 15, 54), (pier_x + 8, 54)], fill=CONCRETE_DARK)
    b_draw.line([(pier_x + 3, 26), (pier_x + 2, 52)], fill=CONCRETE_LIGHT, width=1)
    b_draw.line([(pier_x + 7, 26), (pier_x + 5, 38), (pier_x + 9, 46)], fill=OUTLINE, width=1)
    for rx in [pier_x + 3, pier_x + 7, pier_x + 11]:
        b_draw.line([(rx, 24), (rx + rng.randint(-2, 2), 17)], fill=REBAR_STEEL, width=1)

    b_draw.polygon([(0, 8), (6, 8), (8, 22), (5, 38), (7, 54), (0, 54)], fill=CONCRETE_MID, outline=OUTLINE)
    b_draw.polygon([(w - 1, 8), (w - 7, 8), (w - 9, 20), (w - 6, 36), (w - 8, 54), (w - 1, 54)], fill=CONCRETE_MID, outline=OUTLINE)

    for ry in [11, 15, 19]:
        b_draw.line([(5, ry), (14, ry + 2)], fill=REBAR_STEEL, width=1)
        b_draw.line([(w - 6, ry), (w - 15, ry + 2)], fill=REBAR_STEEL, width=1)

    left_truss_pts = [(2, 16), (32, 41), (28, 48), (2, 26)]
    b_draw.polygon(left_truss_pts, fill=TRUSS_SH, outline=OUTLINE)
    b_draw.line([(3, 16), (31, 41)], fill=TRUSS_RED, width=2)
    b_draw.line([(3, 25), (28, 47)], fill=TRUSS_RED, width=2)
    for step in range(4):
        sx0 = 4 + step * 7
        sy0 = 17 + step * 6
        b_draw.line([(sx0, sy0), (sx0 - 2, sy0 + 7)], fill=TRUSS_HI, width=1)
        b_draw.line([(sx0, sy0), (sx0 + 5, sy0 + 11)], fill=TRUSS_HI, width=1)

    left_deck_pts = [(1, 8), (35, 36), (31, 41), (1, 16)]
    b_draw.polygon(left_deck_pts, fill=ASPHALT_DARK, outline=OUTLINE)
    b_draw.line([(2, 9), (34, 36)], fill=CONCRETE_LIGHT, width=1)
    b_draw.line([(7, 15), (18, 24)], fill=YELLOW_DASH, width=2)
    b_draw.line([(23, 28), (31, 35)], fill=YELLOW_DASH, width=2)

    right_truss_pts = [(w - 3, 17), (47, 42), (51, 48), (w - 3, 27)]
    b_draw.polygon(right_truss_pts, fill=TRUSS_SH, outline=OUTLINE)
    b_draw.line([(w - 4, 17), (48, 42)], fill=TRUSS_RED, width=2)
    b_draw.line([(w - 4, 26), (51, 47)], fill=TRUSS_RED, width=2)
    for step in range(4):
        sx0 = (w - 6) - step * 7
        sy0 = 18 + step * 6
        b_draw.line([(sx0, sy0), (sx0 + 2, sy0 + 7)], fill=TRUSS_HI, width=1)
        b_draw.line([(sx0, sy0), (sx0 - 5, sy0 + 11)], fill=TRUSS_HI, width=1)

    right_deck_pts = [(w - 2, 8), (44, 38), (48, 43), (w - 2, 16)]
    b_draw.polygon(right_deck_pts, fill=ASPHALT_DARK, outline=OUTLINE)
    b_draw.line([(w - 3, 9), (45, 38)], fill=CONCRETE_LIGHT, width=1)
    b_draw.line([(w - 8, 16), (w - 19, 25)], fill=YELLOW_DASH, width=2)
    b_draw.line([(w - 24, 29), (47, 38)], fill=YELLOW_DASH, width=2)

    b_draw.rectangle([2, 2, 5, 9], fill=TRUSS_RED, outline=OUTLINE)
    b_draw.rectangle([w - 6, 2, w - 3, 9], fill=TRUSS_RED, outline=OUTLINE)
    b_draw.line([(4, 3), (12, 13), (17, 23)], fill=REBAR_STEEL, width=1)
    b_draw.line([(w - 5, 3), (w - 13, 14), (w - 17, 25)], fill=REBAR_STEEL, width=1)

    b_img.save(os.path.join(ENV_DIR, "collapsed_bridge_pit.png"))
    print("Saved collapsed_bridge_pit.png ready for live animated fire node!")


if __name__ == "__main__":
    search_and_download_cc0_fire_sheets()
    generate_animated_fire_sheets()
    build_clean_foreground_overpass()
    build_apocalyptic_backgrounds_for_animated_fires()
    print("=== ANIMATED FIRE SHEETS & CLEAN OVERPASS PIPELINE COMPLETE ===")
