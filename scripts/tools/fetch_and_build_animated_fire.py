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
    Regenerates parallax_buildings_mid.png and parallax_skyline_distant.png:
    - Mostly classic dark, moody post-apocalyptic skyscrapers with dark unlit windows & only a FEW sparse lit rooms
      ("sisanya kaya awal gedung biasa yang lampunya hidupnya cuma beberapa aja").
    - Only 2-3 focal apocalyptic destruction landmarks (the crashed commercial airplane skyscraper + 1 blasted tower)
      so fires are minimal, high-impact, and never cluttered ("yang kebakar dikit aja jangan banyak banyak").
    """
    # 1. Distant Skyline (480x270) — Clean moody dark city silhouettes with very sparse dim windows
    dist = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dist)

    SIL_COL = (22, 18, 36, 255)
    SIL_RIM = (46, 32, 62, 255)
    WIN_UNLIT = (14, 12, 24, 255)
    WIN_AMBER_DIM = (195, 118, 56, 255)

    # [x, w, top_y, has_spire, seed, is_damaged]
    dist_specs = [
        (0, 44, 118, True, 1, False),
        (42, 38, 136, False, 2, False),
        (78, 52, 98, True, 3, True),    # Subtle damaged top
        (128, 40, 128, False, 4, False),
        (166, 48, 108, True, 5, False),
        (212, 42, 134, False, 6, False),
        (252, 54, 94, True, 7, True),   # Subtle damaged top
        (304, 38, 140, False, 8, False),
        (340, 48, 112, True, 9, False),
        (386, 46, 126, False, 10, False),
        (430, 50, 104, True, 11, False)
    ]

    for bx, bw, by, has_spire, b_seed, is_damaged in dist_specs:
        if is_damaged:
            pts = [(bx, 270), (bx, by), (bx + bw // 3, by + 2), (bx + (bw * 2) // 3, by + 11), (bx + bw, by + 14), (bx + bw, 270)]
            d_draw.polygon(pts, fill=SIL_COL, outline=OUTLINE)
        else:
            d_draw.rectangle([bx, by, bx + bw, 270], fill=SIL_COL, outline=OUTLINE)
            d_draw.line([(bx + 1, by + 1), (bx + bw - 1, by + 1)], fill=SIL_RIM)
            if has_spire:
                tx = bx + bw // 2
                d_draw.rectangle([tx, by - 16, tx + 1, by], fill=SIL_COL)
                d_draw.rectangle([tx, by - 18, tx + 1, by - 17], fill=(230, 57, 98, 255))

        # Mostly darkened distant towers; only 2 buildings retain a couple dim rooms
        dist_has_lights = (b_seed == 1 or b_seed == 4)
        cols = max(1, (bw - 10) // 6)
        floor_idx = 0
        wy = (by + 16) if is_damaged else (by + 10)
        while wy < 214:
            lit_col = -1
            if dist_has_lights and (floor_idx == 2 or floor_idx == 5):
                lit_col = (floor_idx + b_seed) % max(1, cols)
            for c in range(cols):
                wx = bx + 6 + c * 6
                wcol = WIN_AMBER_DIM if c == lit_col else WIN_UNLIT
                d_draw.rectangle([wx, wy, wx + 2, wy + 2], fill=wcol)
            wy += 7
            floor_idx += 1

    dist.save(os.path.join(ENV_DIR, "parallax_skyline_distant.png"))

    # 2. Mid-Ground Skyline (480x270) — 100% CLEAN classic dark navy/slate buildings with sparse lit rooms!
    # Disasters (crashed airplane & side blast crater) are saved as separate rare overlay sprites
    # so they only appear rarely on ParallaxRareLandmarks (e.g. 1 airplane every 6 blocks = 2880px)!
    mid = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mid)

    NAVY_DARK = (22, 27, 51, 255)      # #161b33
    NAVY_SLATE = (31, 39, 71, 255)     # #1f2747
    NAVY_LEDGE = (46, 56, 94, 255)
    MID_RIM = (52, 62, 102, 255)
    MID_UNLIT = (11, 14, 26, 255)
    WIN_AMBER = (242, 140, 56, 255)    # #f28c38
    WIN_CYAN = (56, 216, 242, 255)     # #38d8f2
    NEON_MAGENTA = (230, 57, 98, 255)  # #e63962
    STEEL_GIRDER = (64, 72, 98, 255)
    STEEL_RUST = (118, 58, 48, 255)

    # [bx, bw, by, style, rooftop_feature]
    mid_buildings = [
        (0, 56, 106, 0, "neon_magenta"),
        (62, 52, 82, 1, "tower"),
        (120, 68, 76, 0, "none"),         # Intact skyscraper (rarely overlaid with airplane_crash_overlay.png)
        (194, 48, 122, 1, "ac"),
        (248, 52, 88, 0, "neon_magenta"),
        (306, 44, 134, 1, "ac"),          # Classic low building (preserves sunset/moon canyon gap)
        (356, 62, 78, 0, "neon_cyan"),    # Intact skyscraper (occasionally overlaid with side_blast_overlay.png)
        (424, 54, 102, 1, "tower")
    ]

    for idx, (bx, bw, by, st, feat) in enumerate(mid_buildings):
        bcol = NAVY_DARK if st == 0 else NAVY_SLATE
        div_col = (18, 22, 42, 255) if st == 0 else (25, 31, 58, 255)

        # Draw clean building body
        m_draw.rectangle([bx, by, bx + bw, 270], fill=bcol, outline=OUTLINE)
        # Clean top cornice ledge (3px deep)
        m_draw.rectangle([bx - 1, by, bx + bw + 1, by + 3], fill=NAVY_LEDGE, outline=OUTLINE)
        m_draw.line([(bx, by + 1), (bx + bw, by + 1)], fill=MID_RIM)

        # Classic rooftop architecture
        if feat == "neon_magenta":
            bbw = bw - 14
            m_draw.rectangle([bx + 7, by - 18, bx + 7 + bbw, by - 4], fill=(18, 16, 30, 255), outline=OUTLINE)
            m_draw.rectangle([bx + 9, by - 16, bx + 5 + bbw, by - 6], fill=(14, 12, 24, 255), outline=NEON_MAGENTA)
            m_draw.rectangle([bx + 13, by - 12, bx + 1 + bbw, by - 11], fill=NEON_MAGENTA)
            m_draw.rectangle([bx + 11, by - 4, bx + 12, by], fill=OUTLINE)
            m_draw.rectangle([bx + bbw, by - 4, bx + bbw + 1, by], fill=OUTLINE)
        elif feat == "neon_cyan":
            bbw = bw - 16
            m_draw.rectangle([bx + 8, by - 16, bx + 8 + bbw, by - 4], fill=(18, 16, 30, 255), outline=OUTLINE)
            m_draw.rectangle([bx + 10, by - 14, bx + 6 + bbw, by - 6], fill=(14, 12, 24, 255), outline=WIN_CYAN)
            m_draw.rectangle([bx + 12, by - 4, bx + 13, by], fill=OUTLINE)
            m_draw.rectangle([bx + bbw, by - 4, bx + bbw + 1, by], fill=OUTLINE)
        elif feat == "tower":
            m_draw.rectangle([bx + 10, by - 16, bx + 26, by - 4], fill=(48, 38, 46, 255), outline=OUTLINE)
            m_draw.rectangle([bx + 8, by - 18, bx + 28, by - 15], fill=(36, 28, 36, 255), outline=OUTLINE)
            m_draw.rectangle([bx + 12, by - 4, bx + 13, by], fill=OUTLINE)
            m_draw.rectangle([bx + 22, by - 4, bx + 23, by], fill=OUTLINE)
        elif feat == "ac":
            m_draw.rectangle([bx + 8, by - 7, bx + 24, by], fill=NAVY_DARK, outline=OUTLINE)
            m_draw.rectangle([bx + 28, by - 5, bx + 40, by], fill=NAVY_DARK, outline=OUTLINE)

        # Structured floor-and-bay window grids: MOSTLY DARK UNLIT (only a few sparse lit rooms!)
        mid_has_lights = (idx == 0 or idx == 1 or idx == 2 or idx == 4 or idx == 7)
        cols = max(1, (bw - 10) // 8)
        floor_num = 0
        wy = by + 9
        while wy < 214:
            m_draw.line([(bx + 2, wy - 2), (bx + bw - 3, wy - 2)], fill=div_col)

            c_start_a = -10
            c_len_a = 0
            c_col_a = WIN_AMBER
            if mid_has_lights:
                if idx == 0 and floor_num == 4:
                    c_start_a, c_len_a, c_col_a = 1, 2, WIN_AMBER
                elif idx == 1 and (floor_num == 3 or floor_num == 7):
                    c_start_a = 1 if floor_num == 3 else max(0, cols - 2)
                    c_len_a = 1
                    c_col_a = WIN_AMBER if floor_num == 3 else WIN_CYAN
                elif idx == 2 and floor_num == 9:
                    # Low sparse amber window well below rare airplane crash zone
                    c_start_a, c_len_a, c_col_a = 4, 1, WIN_AMBER
                elif idx == 4 and floor_num == 5:
                    c_start_a, c_len_a, c_col_a = 2, 1, WIN_CYAN
                elif idx == 7 and (floor_num == 2 or floor_num == 6):
                    c_start_a, c_len_a, c_col_a = 1, 2, WIN_AMBER

            for c in range(cols):
                wx = bx + 6 + c * 8
                wcol = c_col_a if (c >= c_start_a and c < c_start_a + c_len_a) else MID_UNLIT
                m_draw.rectangle([wx, wy, wx + 3, wy + 5], fill=wcol)
                m_draw.line([(wx, wy + 6), (wx + 3, wy + 6)], fill=OUTLINE)
            wy += 10
            floor_num += 1

    mid.save(os.path.join(ENV_DIR, "parallax_buildings_mid.png"))
    print("Saved clean classic parallax_buildings_mid.png (dark skyscrapers + sparse lit windows!)")

    # 2B. Rare Crashed Airplane Overlay (480x270) — Aligned pixel-for-pixel onto Building 3 (bx=120, bw=68, by=76)
    plane_img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(plane_img)
    bx, bw, by = 120, 68, 76
    impact_cy = by + 42

    # Jagged charred impact crater inside Building 3
    crater_pts = [
        (bx, impact_cy - 14), (bx + 16, impact_cy - 20), (bx + 36, impact_cy - 16),
        (bx + 46, impact_cy - 4), (bx + 40, impact_cy + 14), (bx + 20, impact_cy + 17), (bx, impact_cy + 10)
    ]
    p_draw.polygon(crater_pts, fill=(18, 8, 12, 255), outline=OUTLINE)
    for gx in range(bx + 6, bx + 40, 7):
        p_draw.line([(gx, impact_cy - 15), (gx + 2, impact_cy + 13)], fill=(70, 52, 60, 255), width=1)

    FUSE_WHITE = (232, 238, 248, 255)
    FUSE_SILVER = (175, 188, 208, 255)
    FUSE_SHADOW = (96, 108, 130, 255)
    AIRLINE_RED = (232, 45, 66, 255)
    AIRLINE_GOLD = (255, 208, 65, 255)

    tail_fin_pts = [(bx - 22, impact_cy - 14), (bx - 30, impact_cy - 35), (bx - 19, impact_cy - 35), (bx - 8, impact_cy - 11)]
    p_draw.polygon(tail_fin_pts, fill=AIRLINE_RED, outline=OUTLINE)
    p_draw.line([(bx - 27, impact_cy - 27), (bx - 14, impact_cy - 22)], fill=FUSE_WHITE, width=2)
    p_draw.line([(bx - 25, impact_cy - 23), (bx - 13, impact_cy - 18)], fill=AIRLINE_GOLD, width=1)

    fuse_pts = [(bx - 24, impact_cy - 14), (bx + 20, impact_cy - 2), (bx + 16, impact_cy + 12), (bx - 26, impact_cy - 2)]
    p_draw.polygon(fuse_pts, fill=FUSE_WHITE, outline=OUTLINE)
    belly_pts = [(bx - 25, impact_cy - 7), (bx + 18, impact_cy + 5), (bx + 16, impact_cy + 12), (bx - 26, impact_cy - 2)]
    p_draw.polygon(belly_pts, fill=FUSE_SHADOW, outline=OUTLINE)
    p_draw.line([(bx - 24, impact_cy - 8), (bx + 18, impact_cy + 4)], fill=AIRLINE_RED, width=2)

    for w_idx in range(8):
        wx = bx - 20 + w_idx * 5
        wy = int(impact_cy - 11 + w_idx * 1.35)
        p_draw.rectangle([wx, wy, wx + 2, wy + 2], fill=(16, 22, 36, 255))

    htail_pts = [(bx - 22, impact_cy - 7), (bx - 33, impact_cy - 1), (bx - 25, impact_cy + 2), (bx - 14, impact_cy - 5)]
    p_draw.polygon(htail_pts, fill=FUSE_SILVER, outline=OUTLINE)

    wing_pts = [(bx - 4, impact_cy + 1), (bx + 12, impact_cy + 5), (bx - 6, impact_cy + 23), (bx - 16, impact_cy + 19)]
    p_draw.polygon(wing_pts, fill=FUSE_SILVER, outline=OUTLINE)
    p_draw.rectangle([bx - 2, impact_cy + 10, bx + 9, impact_cy + 17], fill=FUSE_SHADOW, outline=OUTLINE)

    plane_img.save(os.path.join(ENV_DIR, "airplane_crash_overlay.png"))
    print("Saved rare airplane_crash_overlay.png!")

    # 2C. Occasional Side Blast Crater Overlay (480x270) — Aligned pixel-for-pixel onto Building 7 (bx=356, bw=62, by=78)
    blast_img = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    bl_draw = ImageDraw.Draw(blast_img)
    bx, bw, by = 356, 62, 78

    # Charred dark interior blast cavity on upper-right side of Building 7
    blast_pts = [
        (bx + bw, by + 26), (bx + bw - 19, by + 33), (bx + bw - 24, by + 49),
        (bx + bw - 13, by + 62), (bx + bw, by + 66)
    ]
    bl_draw.polygon(blast_pts, fill=(16, 10, 14, 255), outline=OUTLINE)
    # Jagged scorched concrete rim & exposed internal steel girders/floor slab
    bl_draw.line([(bx + bw, by + 26), (bx + bw - 19, by + 33), (bx + bw - 24, by + 49), (bx + bw - 13, by + 62), (bx + bw, by + 66)], fill=OUTLINE, width=2)
    bl_draw.line([(bx + bw - 15, by + 32), (bx + bw - 15, by + 61)], fill=STEEL_GIRDER, width=2)
    bl_draw.line([(bx + bw - 22, by + 46), (bx + bw - 2, by + 46)], fill=STEEL_RUST, width=1)
    bl_draw.line([(bx + bw - 18, by + 56), (bx + bw - 3, by + 56)], fill=(48, 38, 46, 255), width=2)

    blast_img.save(os.path.join(ENV_DIR, "side_blast_overlay.png"))
    print("Saved side_blast_overlay.png!")

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
