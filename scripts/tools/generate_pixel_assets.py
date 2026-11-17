"""
Generate Next-Gen AAA Indie 2.5D Voxel-Styled Pixel Art Assets for CUBE: LAST RUN.
Creates crisp, beveled, high-contrast sprite sheets, multi-layer parallax backgrounds,
light maps for PointLight2D, and sleek HUD icons.
"""
import os
import math
import random
from PIL import Image, ImageDraw

os.makedirs("assets/characters", exist_ok=True)
os.makedirs("assets/weapons", exist_ok=True)
os.makedirs("assets/zombies", exist_ok=True)
os.makedirs("assets/environment", exist_ok=True)
os.makedirs("assets/effects", exist_ok=True)
os.makedirs("assets/ui", exist_ok=True)

OUTLINE = (14, 16, 24, 255)


def draw_voxel_cube(draw, x0, y0, w, h, fill_col, hi_col, rim_col, sh_col, outline_col=OUTLINE):
    """Draws a 2.5D beveled voxel-styled cube with top/right specular rim and deep bottom/left shadow."""
    draw.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], fill=fill_col, outline=outline_col)
    # 2px top bevel highlight for 2.5D depth
    draw.line([x0 + 1, y0 + 1, x0 + w - 2, y0 + 1], fill=rim_col)
    draw.line([x0 + 1, y0 + 2, x0 + w - 2, y0 + 2], fill=hi_col)
    # Right edge warm/cyan rim light (facing dusk horizon)
    draw.line([x0 + w - 2, y0 + 1, x0 + w - 2, y0 + h - 2], fill=hi_col)
    # Left & bottom deep shadow bevel
    draw.line([x0 + 1, y0 + 2, x0 + 1, y0 + h - 2], fill=sh_col)
    draw.line([x0 + 1, y0 + h - 2, x0 + w - 2, y0 + h - 2], fill=sh_col)
    draw.line([x0 + 2, y0 + h - 3, x0 + w - 3, y0 + h - 3], fill=sh_col)


# -------------------------------------------------------------
# 1. PLAYER: CUBE SURVIVOR (144x192, 6 cols x 8 rows of 24x24)
# -------------------------------------------------------------
def make_player():
    fw, fh = 24, 24
    cols, rows = 6, 8
    img = Image.new("RGBA", (fw * cols, fh * rows), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    CYAN_BASE = (36, 168, 178, 255)
    CYAN_HI = (86, 224, 242, 255)
    CYAN_RIM = (175, 250, 255, 255)
    CYAN_SH = (22, 78, 96, 255)

    VISOR_DARK = (16, 24, 38, 255)
    VISOR_GLOW = (0, 245, 255, 255)
    VISOR_CORE = (225, 255, 255, 255)

    HEADBAND = (235, 45, 65, 255)
    HEADBAND_HI = (255, 115, 125, 255)
    HEADBAND_SH = (145, 20, 35, 255)

    WHITE = (250, 250, 255, 255)
    HURT_RED = (240, 55, 65, 255)
    ZOMB_BASE = (75, 145, 65, 255)
    ZOMB_HI = (130, 210, 90, 255)
    ZOMB_SH = (38, 72, 42, 255)

    def draw_player_cube(cx, cy, bob_y=0, leg_phase=0, is_hurt=False, is_zomb=False, eyes_open=True, dead_phase=0):
        if dead_phase >= 3:
            draw.rectangle([cx + 2, cy + 18, cx + 8, cy + 22], fill=CYAN_BASE, outline=OUTLINE)
            draw.rectangle([cx + 9, cy + 19, cx + 15, cy + 22], fill=CYAN_SH, outline=OUTLINE)
            draw.rectangle([cx + 16, cy + 17, cx + 22, cy + 22], fill=HEADBAND, outline=OUTLINE)
            return
        elif dead_phase == 2:
            draw_voxel_cube(draw, cx + 4, cy + 12, 16, 10, CYAN_SH, CYAN_BASE, CYAN_HI, OUTLINE)
            draw.rectangle([cx + 8, cy + 14, cx + 13, cy + 16], fill=HURT_RED)
            return
        elif dead_phase == 1:
            draw_voxel_cube(draw, cx + 4, cy + 6, 16, 14, HURT_RED, WHITE, WHITE, OUTLINE)
            return

        bx = cx + 4
        by = cy + 4 + bob_y
        bw, bh = 16, 15

        base_col = HURT_RED if is_hurt else (ZOMB_BASE if is_zomb else CYAN_BASE)
        hi_col = WHITE if is_hurt else (ZOMB_HI if is_zomb else CYAN_HI)
        rim_col = WHITE if is_hurt else (ZOMB_HI if is_zomb else CYAN_RIM)
        sh_col = OUTLINE if is_hurt else (ZOMB_SH if is_zomb else CYAN_SH)

        # Voxel Body Cube
        draw_voxel_cube(draw, bx, by, bw, bh, base_col, hi_col, rim_col, sh_col)

        # Tactical Crimson Headband across forehead
        draw.rectangle([bx + 1, by + 2, bx + bw - 2, by + 4], fill=HEADBAND)
        draw.line([bx + 1, by + 2, bx + bw - 2, by + 2], fill=HEADBAND_HI)
        draw.line([bx + 1, by + 4, bx + bw - 2, by + 4], fill=HEADBAND_SH)
        # Knot on back-left (connects seamlessly with Scarf Line2D trail)
        draw.rectangle([bx - 2, by + 2, bx, by + 5], fill=HEADBAND, outline=OUTLINE)
        draw.point([bx - 1, by + 3], fill=HEADBAND_HI)

        # Recessed Dark Tactical Visor Housing
        vx0, vy0, vw, vh = bx + 3, by + 5, bw - 4, 6
        draw.rectangle([vx0, vy0, vx0 + vw - 1, vy0 + vh - 1], fill=VISOR_DARK, outline=OUTLINE)

        if is_zomb:
            # Feral toxic-red/yellow zombie eyes
            draw.rectangle([vx0 + 2, vy0 + 1, vx0 + 4, vy0 + 4], fill=(255, 220, 40, 255))
            draw.point([vx0 + 3, vy0 + 2], fill=(255, 20, 20, 255))
            draw.rectangle([vx0 + 7, vy0 + 1, vx0 + 9, vy0 + 4], fill=(255, 220, 40, 255))
            draw.point([vx0 + 8, vy0 + 2], fill=(255, 20, 20, 255))
        elif is_hurt:
            # Glowing white hurt X-eyes
            draw.line([vx0 + 2, vy0 + 1, vx0 + 4, vy0 + 4], fill=WHITE)
            draw.line([vx0 + 2, vy0 + 4, vx0 + 4, vy0 + 1], fill=WHITE)
            draw.line([vx0 + 7, vy0 + 1, vx0 + 9, vy0 + 4], fill=WHITE)
            draw.line([vx0 + 7, vy0 + 4, vx0 + 9, vy0 + 1], fill=WHITE)
        elif eyes_open:
            # Glowing Cyber/Tactical Eyes with bright white specular core
            draw.rectangle([vx0 + 2, vy0 + 1, vx0 + 5, vy0 + 4], fill=VISOR_GLOW)
            draw.rectangle([vx0 + 3, vy0 + 1, vx0 + 4, vy0 + 2], fill=VISOR_CORE)
            draw.rectangle([vx0 + 7, vy0 + 1, vx0 + 10, vy0 + 4], fill=VISOR_GLOW)
            draw.rectangle([vx0 + 8, vy0 + 1, vx0 + 9, vy0 + 2], fill=VISOR_CORE)
        else:
            # Blinking glowing slit
            draw.line([vx0 + 2, vy0 + 3, vx0 + 5, vy0 + 3], fill=VISOR_GLOW)
            draw.line([vx0 + 7, vy0 + 3, vx0 + 10, vy0 + 3], fill=VISOR_GLOW)

        # Tactical Utility Belt & Brass Buckle
        draw.line([bx + 1, by + 12, bx + bw - 2, by + 12], fill=(40, 32, 28, 255))
        draw.rectangle([bx + 7, by + 11, bx + 9, by + 13], fill=(245, 195, 55, 255))

        # Expressive Armored Boots
        leg_y = by + bh
        BOOT_COL = (30, 35, 48, 255)
        if leg_phase == 1:
            draw.rectangle([bx + 1, leg_y - 1, bx + 5, leg_y + 2], fill=BOOT_COL, outline=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 2, bx + 13, leg_y + 1], fill=BOOT_COL, outline=OUTLINE)
        elif leg_phase == 2:
            draw.rectangle([bx + 2, leg_y - 2, bx + 6, leg_y + 1], fill=BOOT_COL, outline=OUTLINE)
            draw.rectangle([bx + 10, leg_y - 1, bx + 14, leg_y + 2], fill=BOOT_COL, outline=OUTLINE)
        elif leg_phase == 3:
            draw.rectangle([bx + 3, leg_y - 2, bx + 6, leg_y], fill=BOOT_COL, outline=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 2, bx + 12, leg_y], fill=BOOT_COL, outline=OUTLINE)
        else:
            draw.rectangle([bx + 3, leg_y - 1, bx + 6, leg_y + 2], fill=BOOT_COL, outline=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 1, bx + 12, leg_y + 2], fill=BOOT_COL, outline=OUTLINE)

    # Row 0: Idle (4 frames)
    for i in range(4):
        draw_player_cube(i * fw, 0 * fh, bob_y=(1 if i in (1, 2) else 0), leg_phase=0, eyes_open=(i != 3))
    # Row 1: Run (6 frames)
    bobs = [0, -1, 0, 1, 0, -1]
    legs = [1, 2, 1, 2, 1, 2]
    for i in range(6):
        draw_player_cube(i * fw, 1 * fh, bob_y=bobs[i], leg_phase=legs[i])
    # Row 2: Jump (2 frames)
    draw_player_cube(0 * fw, 2 * fh, bob_y=1, leg_phase=0)
    draw_player_cube(1 * fw, 2 * fh, bob_y=-2, leg_phase=3)
    # Row 3: Fall (2 frames)
    draw_player_cube(0 * fw, 3 * fh, bob_y=0, leg_phase=3)
    draw_player_cube(1 * fw, 3 * fh, bob_y=1, leg_phase=3)
    # Row 4: Land (2 frames)
    draw_player_cube(0 * fw, 4 * fh, bob_y=2, leg_phase=0)
    draw_player_cube(1 * fw, 4 * fh, bob_y=0, leg_phase=0)
    # Row 5: Hurt (2 frames)
    draw_player_cube(0 * fw, 5 * fh, bob_y=-1, is_hurt=True)
    draw_player_cube(1 * fw, 5 * fh, bob_y=0, is_hurt=True)
    # Row 6: Death (4 frames)
    for i in range(4):
        draw_player_cube(i * fw, 6 * fh, dead_phase=i)
    # Row 7: Transform (4 frames)
    draw_player_cube(0 * fw, 7 * fh, is_hurt=True)
    draw_player_cube(1 * fw, 7 * fh, is_zomb=True, bob_y=1)
    draw_player_cube(2 * fw, 7 * fh, is_zomb=True, bob_y=-1)
    draw_player_cube(3 * fw, 7 * fh, is_zomb=True, bob_y=0)

    img.save("assets/characters/cube_player.png")
    print("Saved assets/characters/cube_player.png (144x192)")


# -------------------------------------------------------------
# 2. WEAPONS: DOUBLE-BARREL SHOTGUN, SHELLS & STAR MUZZLE FLASH
# -------------------------------------------------------------
def make_weapons():
    w_img = Image.new("RGBA", (24, 10), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(w_img)

    WOOD_DARK = (92, 46, 18, 255)
    WOOD_HI = (158, 88, 34, 255)
    STEEL_DARK = (42, 48, 62, 255)
    STEEL_MID = (118, 130, 148, 255)
    STEEL_HI = (215, 228, 245, 255)
    BRASS = (238, 185, 45, 255)

    # Stock & Grip
    w_draw.polygon([(0, 4), (5, 3), (7, 5), (5, 7), (0, 7)], fill=WOOD_DARK, outline=OUTLINE)
    w_draw.line([(1, 4), (5, 4)], fill=WOOD_HI)
    # Receiver with brass shell latch
    w_draw.rectangle([7, 2, 11, 7], fill=STEEL_DARK, outline=OUTLINE)
    w_draw.point([8, 4], fill=BRASS)
    w_draw.point([9, 4], fill=BRASS)
    # Heavy Twin Barrels with bright top specular edge
    w_draw.rectangle([11, 2, 23, 5], fill=STEEL_MID, outline=OUTLINE)
    w_draw.line([12, 2, 22, 2], fill=STEEL_HI)
    w_draw.rectangle([11, 5, 23, 7], fill=STEEL_DARK, outline=OUTLINE)
    # Glowing red fiber-optic front sight at muzzle tip
    w_draw.point([22, 1], fill=(255, 60, 40, 255))
    # Wooden pump/fore-end grip
    w_draw.rectangle([12, 7, 17, 8], fill=WOOD_DARK, outline=OUTLINE)
    w_draw.line([13, 7, 16, 7], fill=WOOD_HI)
    w_img.save("assets/weapons/shotgun.png")

    # Shells (16x8)
    sh_img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(sh_img)
    sh_draw.rectangle([1, 2, 3, 6], fill=BRASS, outline=OUTLINE)
    sh_draw.rectangle([3, 2, 7, 6], fill=(220, 35, 40, 255), outline=OUTLINE)
    sh_draw.line([4, 3, 6, 3], fill=(255, 110, 110, 255))
    sh_draw.rectangle([9, 2, 11, 6], fill=BRASS, outline=OUTLINE)
    sh_draw.rectangle([11, 2, 15, 6], fill=(70, 60, 55, 255), outline=OUTLINE)
    sh_img.save("assets/weapons/shotgun_shell.png")

    # Multi-Frame Star Muzzle Flash (32x16: 2 frames of 16x16)
    mf_img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    mf_draw = ImageDraw.Draw(mf_img)
    # Frame 0: High-energy star blast
    mf_draw.polygon([(0, 8), (5, 2), (14, 0), (10, 6), (15, 8), (10, 10), (14, 15), (5, 13)], fill=(255, 95, 15, 255))
    mf_draw.polygon([(0, 8), (4, 4), (11, 3), (8, 7), (13, 8), (8, 9), (11, 13), (4, 12)], fill=(255, 215, 55, 255))
    mf_draw.ellipse([0, 5, 6, 11], fill=(255, 255, 255, 255))
    # Frame 1: Secondary star flare & smoke ring
    mf_draw.polygon([(16, 8), (20, 4), (27, 3), (24, 7), (30, 8), (24, 9), (27, 13), (20, 12)], fill=(255, 160, 40, 230))
    mf_draw.ellipse([17, 6, 22, 10], fill=(255, 250, 210, 255))
    mf_img.save("assets/weapons/muzzle_flash.png")
    print("Saved weapons assets")


# -------------------------------------------------------------
# 3. ZOMBIE HORDE ARCHETYPES (2.5D Voxel-Shaded)
# -------------------------------------------------------------
def make_zombies():
    # A. Shambler / Walker (24x24 x 4 frames): Glowing toxic-green eyes, tattered clothes
    w_img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(w_img)
    W_BASE = (68, 108, 72, 255)
    W_HI = (110, 160, 105, 255)
    W_RIM = (155, 215, 140, 255)
    W_SH = (38, 62, 42, 255)
    SHIRT = (78, 88, 108, 255)
    TOXIC_GREEN = (65, 255, 50, 255)

    for i in range(4):
        cx = i * 24
        bob = 1 if i in (1, 3) else 0
        bx, by = cx + 4, 4 + bob
        draw_voxel_cube(w_draw, bx, by, 16, 15, W_BASE, W_HI, W_RIM, W_SH)
        # Tattered dark coat/shirt
        w_draw.rectangle([bx + 1, by + 9, bx + 14, by + 13], fill=SHIRT)
        w_draw.line([bx + 3, by + 9, bx + 5, by + 12], fill=W_SH)
        w_draw.line([bx + 9, by + 9, bx + 11, by + 13], fill=W_SH)
        # Glowing Toxic-Green Eyes
        w_draw.rectangle([bx + 4, by + 4, bx + 12, by + 7], fill=(18, 28, 18, 255))
        w_draw.rectangle([bx + 5, by + 5, bx + 7, by + 6], fill=TOXIC_GREEN)
        w_draw.point([bx + 5, by + 5], fill=(220, 255, 200, 255))
        w_draw.rectangle([bx + 9, by + 5, bx + 11, by + 6], fill=TOXIC_GREEN)
        # Rotting jaw & toxic drip
        w_draw.rectangle([bx + 5, by + 10, bx + 11, by + 12], fill=(28, 18, 20, 255))
        w_draw.point([bx + 6, by + 10], fill=(235, 235, 210, 255))
        w_draw.point([bx + 9, by + 10], fill=(235, 235, 210, 255))
        w_draw.point([bx + 7, by + 13], fill=TOXIC_GREEN)
        # Reaching undead arms
        reach = 2 if i in (1, 2) else 0
        w_draw.rectangle([bx - 2 - reach, by + 6, bx + 3, by + 8], fill=W_BASE, outline=OUTLINE)
        # Shambling feet
        if i % 2 == 0:
            w_draw.rectangle([bx + 3, by + 15, bx + 6, by + 18], fill=OUTLINE)
            w_draw.rectangle([bx + 9, by + 14, bx + 12, by + 17], fill=OUTLINE)
        else:
            w_draw.rectangle([bx + 3, by + 14, bx + 6, by + 17], fill=OUTLINE)
            w_draw.rectangle([bx + 9, by + 15, bx + 12, by + 18], fill=OUTLINE)
    w_img.save("assets/zombies/zombie_walker.png")

    # B. Sprinter / Crawler Cube (24x24 x 4 frames): Low profile, glowing red eyes, fast lunge
    r_img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(r_img)
    R_BASE = (155, 28, 42, 255)
    R_HI = (225, 65, 75, 255)
    R_RIM = (255, 130, 120, 255)
    R_SH = (85, 14, 22, 255)
    RED_GLOW = (255, 35, 35, 255)

    for i in range(4):
        cx = i * 24
        bob = (i % 2) * 2
        bx, by = cx + 4, 6 + bob # Lower aerodynamic profile
        draw_voxel_cube(r_draw, bx, by, 16, 13, R_BASE, R_HI, R_RIM, R_SH)
        # Glowing Red Feral Eyes
        r_draw.rectangle([bx + 3, by + 3, bx + 12, by + 6], fill=(24, 8, 10, 255))
        r_draw.rectangle([bx + 4, by + 4, bx + 6, by + 5], fill=RED_GLOW)
        r_draw.point([bx + 4, by + 4], fill=(255, 220, 200, 255))
        r_draw.rectangle([bx + 8, by + 4, bx + 10, by + 5], fill=RED_GLOW)
        # Fanged snarl
        r_draw.rectangle([bx + 4, by + 8, bx + 10, by + 10], fill=(20, 8, 8, 255))
        r_draw.point([bx + 5, by + 8], fill=(255, 255, 255, 255))
        r_draw.point([bx + 8, by + 8], fill=(255, 255, 255, 255))
        # Forward lunging claws
        r_draw.rectangle([bx - 3, by + 5, bx + 2, by + 8], fill=R_BASE, outline=OUTLINE)
        # Sprinting legs
        if i % 2 == 0:
            r_draw.rectangle([bx + 1, by + 13, bx + 4, by + 17], fill=OUTLINE)
            r_draw.rectangle([bx + 11, by + 12, bx + 14, by + 15], fill=OUTLINE)
        else:
            r_draw.rectangle([bx + 3, by + 12, bx + 6, by + 15], fill=OUTLINE)
            r_draw.rectangle([bx + 9, by + 13, bx + 12, by + 17], fill=OUTLINE)
    r_img.save("assets/zombies/zombie_runner.png")

    # C. Brute / Riot Cube (36x36 x 4 frames): Heavy armored cube with cracked visor
    b_img = Image.new("RGBA", (36 * 4, 36), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(b_img)
    B_BASE = (58, 74, 88, 255)
    B_HI = (98, 124, 142, 255)
    B_RIM = (155, 185, 205, 255)
    B_SH = (32, 42, 52, 255)
    ARMOR = (145, 152, 165, 255)
    ARMOR_HI = (205, 215, 228, 255)

    for i in range(4):
        cx = i * 36
        bob = i % 2
        bx, by = cx + 5, 5 + bob
        bw, bh = 26, 24
        draw_voxel_cube(b_draw, bx, by, bw, bh, B_BASE, B_HI, B_RIM, B_SH)
        # Heavy Riot Armor Plate with rivets
        b_draw.rectangle([bx + 3, by + 9, bx + 22, by + 20], fill=ARMOR, outline=OUTLINE)
        b_draw.line([bx + 4, by + 10, bx + 21, by + 10], fill=ARMOR_HI)
        for rx, ry in [(bx + 5, by + 11), (bx + 20, by + 11), (bx + 5, by + 18), (bx + 20, by + 18)]:
            b_draw.point([rx, ry], fill=(40, 45, 55, 255))
        # Cracked Riot Visor with glowing crimson core
        b_draw.rectangle([bx + 4, by + 3, bx + 18, by + 8], fill=(18, 12, 16, 255), outline=OUTLINE)
        b_draw.line([bx + 6, by + 5, bx + 15, by + 5], fill=(255, 45, 45, 255))
        b_draw.line([bx + 9, by + 3, bx + 12, by + 8], fill=(220, 240, 255, 255)) # Visor crack
        # Shoulder pauldron spikes
        b_draw.polygon([(bx + 18, by), (bx + 21, by - 4), (bx + 24, by)], fill=ARMOR, outline=OUTLINE)
        # Heavy stomping boots
        if i % 2 == 0:
            b_draw.rectangle([bx + 4, by + bh, bx + 10, by + bh + 4], fill=OUTLINE)
            b_draw.rectangle([bx + 15, by + bh - 1, bx + 21, by + bh + 3], fill=OUTLINE)
        else:
            b_draw.rectangle([bx + 4, by + bh - 1, bx + 10, by + bh + 3], fill=OUTLINE)
            b_draw.rectangle([bx + 15, by + bh, bx + 21, by + bh + 4], fill=OUTLINE)
    b_img.save("assets/zombies/zombie_brute.png")

    # D. Mutant Cube (26x26 x 4 frames)
    m_img = Image.new("RGBA", (26 * 4, 26), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(m_img)
    M_BASE = (48, 175, 42, 255)
    M_HI = (115, 240, 75, 255)
    M_RIM = (185, 255, 130, 255)
    M_SH = (24, 88, 26, 255)

    for i in range(4):
        cx = i * 26
        bob = 1 if i in (1, 2) else 0
        bx, by = cx + 4, 4 + bob
        draw_voxel_cube(m_draw, bx, by, 18, 16, M_BASE, M_HI, M_RIM, M_SH)
        m_draw.line([bx + 2, by + 10, bx + 8, by + 12], fill=(155, 40, 200, 255))
        m_draw.line([bx + 8, by + 12, bx + 14, by + 8], fill=(155, 40, 200, 255))
        m_draw.rectangle([bx + 4, by + 4, bx + 7, by + 7], fill=(255, 255, 40, 255))
        m_draw.point([bx + 5, by + 5], fill=OUTLINE)
        m_draw.rectangle([bx + 10, by + 3, bx + 12, by + 5], fill=(255, 60, 60, 255))
        m_draw.rectangle([bx + 13, by + 6, bx + 15, by + 8], fill=(0, 245, 255, 255))
        m_draw.rectangle([bx + 2, by + 16, bx + 5, by + 19], fill=OUTLINE)
        m_draw.rectangle([bx + 7, by + 16, bx + 10, by + 20], fill=OUTLINE)
        m_draw.rectangle([bx + 12, by + 16, bx + 15, by + 19], fill=OUTLINE)
    m_img.save("assets/zombies/zombie_mutant.png")
    print("Saved zombie sheets")


# -------------------------------------------------------------
# 4. ATMOSPHERIC PARALLAX LAYERS & URBAN HIGHWAY TILES
# -------------------------------------------------------------
def make_environment():
    # A. Layer 1: Sky & Celestial Layer (480x270)
    # Gradient: #0f1021 -> #2b193d -> #7a2832 -> #f28c38
    sky = Image.new("RGBA", (480, 270), (0, 0, 0, 255))
    s_draw = ImageDraw.Draw(sky)
    stops = [
        (0, (15, 16, 33)),
        (85, (43, 25, 61)),
        (175, (122, 40, 50)),
        (270, (242, 140, 56)),
    ]
    for y in range(270):
        for idx in range(len(stops) - 1):
            y0, c0 = stops[idx]
            y1, c1 = stops[idx + 1]
            if y0 <= y <= y1:
                t = (y - y0) / float(max(1, y1 - y0))
                r = int(c0[0] * (1 - t) + c1[0] * t)
                g = int(c0[1] * (1 - t) + c1[1] * t)
                b = int(c0[2] * (1 - t) + c1[2] * t)
                s_draw.line([0, y, 480, y], fill=(r, g, b, 255))
                break

    # Volumetric sun disc in texture (enhanced further by dusk_sky_gradient.gdshader)
    s_draw.ellipse([325, 68, 405, 148], fill=(255, 130, 50, 85))
    s_draw.ellipse([342, 85, 388, 131], fill=(255, 225, 150, 210))
    sky.save("assets/environment/parallax_sky.png")

    # B. Layer 2: Distant Mega-City Silhouette Layer (480x270, seamless)
    dist = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dist)
    SIL_DARK = (32, 20, 38, 235)
    SIL_RIM = (95, 42, 52, 210)
    SMOKE_COL = (24, 16, 28, 110)

    rnd = random.Random(101)
    # Distant rising black smoke plumes
    for sx in [70, 230, 390]:
        for sy in range(60, 210, 14):
            rad = int(12 + (210 - sy) * 0.14)
            offset_x = int(math.sin(sy * 0.08) * 8)
            d_draw.ellipse([sx + offset_x - rad, sy - rad, sx + offset_x + rad, sy + rad], fill=SMOKE_COL)

    bx = 0
    while bx < 480:
        bw = rnd.randint(24, 48)
        if bx + bw > 480:
            bw = 480 - bx
        bh = rnd.randint(68, 148)
        by = 224 - bh
        d_draw.rectangle([bx, by, bx + bw, 270], fill=SIL_DARK)
        # Sunset rim highlight on top & right edge of skyscraper
        d_draw.line([bx, by, bx + bw, by], fill=SIL_RIM)
        d_draw.line([bx + bw, by, bx + bw, 224], fill=SIL_RIM)

        # Radio tower & blinking red aviation beacon at top
        if rnd.random() > 0.45:
            tx = bx + bw // 2
            th = rnd.randint(14, 28)
            d_draw.line([tx, by - th, tx, by], fill=SIL_DARK, width=2)
            d_draw.ellipse([tx - 2, by - th - 2, tx + 2, by - th + 2], fill=(255, 45, 55, 240))
            d_draw.point([tx, by - th], fill=(255, 220, 220, 255))

        # Distant warm amber window clusters
        for wy in range(by + 10, 212, 10):
            for wx in range(bx + 4, bx + bw - 5, 7):
                if rnd.random() > 0.68:
                    d_draw.rectangle([wx, wy, wx + 2, wy + 4], fill=(235, 135, 65, 115))
        bx += bw + rnd.randint(2, 8)

    # Collapsed distant suspension bridge span
    d_draw.line([0, 192, 480, 192], fill=(45, 24, 38, 200), width=3)
    dist.save("assets/environment/parallax_skyline_distant.png")

    # C. Layer 3: Mid-Ground Urban Skyline Layer (480x270)
    # Multi-toned dark navy/slate buildings (#161b33, #1f2747) + amber/cyan/fluorescent windows
    mid = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mid)
    NAVY_DARK = (22, 27, 51, 255)   # #161b33
    NAVY_SLATE = (31, 39, 71, 255)  # #1f2747
    NAVY_RIM = (72, 62, 95, 255)

    WIN_AMBER = (255, 178, 68, 235)
    WIN_CYAN = (75, 225, 255, 220)
    WIN_OFF = (14, 18, 34, 255)

    bx = 0
    rnd = random.Random(202)
    while bx < 480:
        bw = rnd.randint(42, 74)
        if bx + bw > 480:
            bw = 480 - bx
        bh = rnd.randint(76, 156)
        by = 228 - bh
        b_col = NAVY_DARK if (bx // 40) % 2 == 0 else NAVY_SLATE
        m_draw.rectangle([bx, by, bx + bw, 270], fill=b_col, outline=OUTLINE)
        m_draw.line([bx + 1, by + 1, bx + bw - 1, by + 1], fill=NAVY_RIM)
        m_draw.line([bx + bw - 1, by + 1, bx + bw - 1, 228], fill=NAVY_RIM)

        # Rooftop silhouettes: water towers, neon billboards, or AC units
        roof_type = rnd.randint(0, 2)
        if roof_type == 0 and bw >= 48:
            # Neon Billboard frame
            bb_w = bw - 14
            m_draw.rectangle([bx + 7, by - 22, bx + 7 + bb_w, by - 5], fill=(38, 22, 42, 255), outline=OUTLINE)
            neon_col = (255, 65, 125, 240) if rnd.random() > 0.5 else (55, 235, 255, 240)
            m_draw.rectangle([bx + 9, by - 20, bx + 5 + bb_w, by - 7], outline=neon_col)
            m_draw.line([bx + 12, by - 5, bx + 12, by], fill=OUTLINE, width=2)
            m_draw.line([bx + bb_w, by - 5, bx + bb_w, by], fill=OUTLINE, width=2)
        elif roof_type == 1:
            # Rooftop water tower
            wx0 = bx + 8
            m_draw.rectangle([wx0, by - 18, wx0 + 14, by - 6], fill=(55, 42, 48, 255), outline=OUTLINE)
            m_draw.polygon([(wx0 - 1, by - 18), (wx0 + 7, by - 23), (wx0 + 15, by - 18)], fill=(40, 32, 38, 255), outline=OUTLINE)
            m_draw.line([wx0 + 3, by - 6, wx0 + 3, by], fill=OUTLINE)
            m_draw.line([wx0 + 11, by - 6, wx0 + 11, by], fill=OUTLINE)
        else:
            # AC units
            m_draw.rectangle([bx + 6, by - 7, bx + 18, by], fill=NAVY_SLATE, outline=OUTLINE)

        # Varied window clusters (warm amber, cool cyan, dark)
        for wy in range(by + 10, 218, 12):
            for wx in range(bx + 6, bx + bw - 8, 9):
                r_val = rnd.random()
                if r_val > 0.72:
                    w_col = WIN_AMBER
                elif r_val > 0.56:
                    w_col = WIN_CYAN
                else:
                    w_col = WIN_OFF
                m_draw.rectangle([wx, wy, wx + 4, wy + 6], fill=w_col)
        bx += bw + rnd.randint(6, 16)

    mid.save("assets/environment/parallax_buildings_mid.png")

    # D. Layer 4: Foreground Overpass / Street-Level Details Layer (480x270)
    # Rusted highway guardrails, streetlamps, burned-out car silhouettes along road verge
    fore = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    f_draw = ImageDraw.Draw(fore)
    RUST_DARK = (46, 30, 32, 245)
    RUST_HI = (92, 54, 46, 245)
    LAMP_POLE = (32, 36, 48, 255)
    SODIUM_GLOW = (255, 190, 85, 255)

    # Background highway guardrail running along y=212..220
    f_draw.rectangle([0, 213, 480, 217], fill=RUST_DARK, outline=OUTLINE)
    f_draw.line([0, 214, 480, 214], fill=RUST_HI)
    for gx in range(0, 480, 24):
        f_draw.rectangle([gx, 211, gx + 3, 224], fill=RUST_DARK, outline=OUTLINE)

    # Streetlamps at x=80, 240, 400
    for lx in [80, 240, 400]:
        f_draw.rectangle([lx, 138, lx + 3, 224], fill=LAMP_POLE, outline=OUTLINE)
        f_draw.line([lx + 2, 138, lx + 16, 134], fill=LAMP_POLE, width=2)
        f_draw.rectangle([lx + 13, 133, lx + 20, 136], fill=LAMP_POLE, outline=OUTLINE)
        f_draw.rectangle([lx + 14, 136, lx + 19, 138], fill=SODIUM_GLOW)
        # Subtle volumetric light cone baked in texture
        f_draw.polygon([(lx + 16, 138), (lx - 18, 224), (lx + 50, 224)], fill=(255, 185, 75, 24))

    # Burned-out car silhouettes behind guardrail
    for cx in [145, 325]:
        f_draw.polygon([
            (cx, 213), (cx + 4, 203), (cx + 12, 197), (cx + 28, 197),
            (cx + 35, 203), (cx + 42, 205), (cx + 42, 213)
        ], fill=(24, 22, 30, 240), outline=OUTLINE)
        # Broken window cutouts
        f_draw.polygon([(cx + 13, 199), (cx + 20, 199), (cx + 20, 204), (cx + 10, 204)], fill=(65, 35, 42, 180))
        f_draw.polygon([(cx + 22, 199), (cx + 27, 199), (cx + 31, 204), (cx + 22, 204)], fill=(65, 35, 42, 180))

    fore.save("assets/environment/parallax_overpass_fore.png")

    # E. Urban Highway Tileset (128x64, 8x4 grid of 16x16 tiles)
    t_img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    t_draw = ImageDraw.Draw(t_img)

    ROAD_DARK = (34, 38, 48, 255)
    ROAD_MID = (48, 54, 68, 255)
    CURB_TOP = (135, 142, 158, 255)
    CURB_SH = (78, 84, 98, 255)
    YELLOW_LINE = (245, 192, 48, 255)
    PUDDLE_COL = (85, 135, 185, 255)
    DIRT_DARK = (46, 36, 34, 255)
    DIRT_HI = (78, 60, 52, 255)
    SPIKE_METAL = (175, 188, 205, 255)
    SLUDGE = (50, 215, 65, 255)

    # Tile (0,0): Asphalt road surface with weathered concrete curb
    t_draw.rectangle([0, 0, 15, 3], fill=CURB_TOP, outline=OUTLINE)
    t_draw.line([1, 2, 14, 2], fill=CURB_SH)
    t_draw.rectangle([0, 4, 15, 15], fill=ROAD_DARK)
    t_draw.line([0, 4, 15, 4], fill=ROAD_MID)
    t_draw.point([4, 9], fill=ROAD_MID)
    t_draw.point([11, 12], fill=(24, 26, 34, 255))

    # Tile (1,0): Asphalt road with yellow lane marking & subtle reflective puddle
    t_draw.rectangle([16, 0, 31, 3], fill=CURB_TOP, outline=OUTLINE)
    t_draw.rectangle([16, 4, 31, 15], fill=ROAD_DARK)
    t_draw.rectangle([18, 7, 29, 10], fill=YELLOW_LINE)
    t_draw.line([18, 7, 29, 7], fill=(255, 230, 120, 255))
    # Reflective puddle sheen
    t_draw.ellipse([20, 12, 28, 14], fill=PUDDLE_COL)
    t_draw.line([22, 13, 26, 13], fill=(255, 180, 110, 255))

    # Tile (2,0): Deep concrete/sub-road structural foundation
    t_draw.rectangle([32, 0, 47, 15], fill=DIRT_DARK, outline=OUTLINE)
    t_draw.rectangle([34, 2, 45, 6], fill=DIRT_HI)
    t_draw.rectangle([34, 9, 41, 13], fill=DIRT_HI)

    # Tile (3,0): Razor Metal Road Spikes
    for sx in [49, 53, 57, 61]:
        t_draw.polygon([(sx, 15), (sx + 2, 3), (sx + 4, 15)], fill=SPIKE_METAL, outline=OUTLINE)
        t_draw.line([(sx + 1, 14), (sx + 2, 4)], fill=(240, 248, 255, 255))

    # Tile (4,0): Concrete Highway Barricade with crimson/amber hazard chevron
    t_draw.polygon([(65, 15), (67, 2), (77, 2), (79, 15)], fill=CURB_TOP, outline=OUTLINE)
    t_draw.polygon([(68, 4), (76, 4), (74, 12), (67, 12)], fill=(235, 55, 45, 255))
    t_draw.line([(69, 6), (73, 10)], fill=YELLOW_LINE, width=2)

    # Tile (5,0): Radioactive Acid Puddle (Pit Killzone)
    t_draw.rectangle([80, 7, 95, 15], fill=SLUDGE, outline=OUTLINE)
    t_draw.line([81, 8, 94, 8], fill=(175, 255, 120, 255))
    t_draw.ellipse([83, 4, 87, 8], fill=(175, 255, 120, 255))

    # Tile (6,0): Steel Overpass Platform Girder
    t_draw.rectangle([96, 1, 111, 8], fill=SPIKE_METAL, outline=OUTLINE)
    t_draw.line([97, 2, 110, 2], fill=(235, 245, 255, 255))
    for gx in range(98, 110, 3):
        t_draw.line([gx, 3, gx, 7], fill=(40, 45, 58, 255))

    # Tile (7,0): Hazard Warning Sign
    t_draw.rectangle([114, 1, 126, 12], fill=YELLOW_LINE, outline=OUTLINE)
    t_draw.rectangle([117, 3, 123, 8], fill=OUTLINE)
    t_img.save("assets/environment/urban_tiles.png")

    # F. Smooth Radial PointLight2D Texture (64x64)
    rad_img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for y in range(64):
        for x in range(64):
            dx = (x - 31.5) / 31.5
            dy = (y - 31.5) / 31.5
            d = math.sqrt(dx * dx + dy * dy)
            val = int(max(0.0, 1.0 - d) ** 2.0 * 255)
            rad_img.putpixel((x, y), (val, val, val, val))
    rad_img.save("assets/environment/point_light_radial.png")
    print("Saved environment & lighting textures")


# -------------------------------------------------------------
# 5. UI PIPS & HUD ATLAS
# -------------------------------------------------------------
def make_ui():
    # Glowing Heart / Shield HP Pips (14x14)
    full_pip = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    fp_draw = ImageDraw.Draw(full_pip)
    fp_draw.polygon([(7, 1), (12, 3), (12, 8), (7, 13), (2, 8), (2, 3)], fill=(255, 55, 75, 255), outline=OUTLINE)
    fp_draw.polygon([(7, 3), (10, 4), (10, 7), (7, 10), (4, 7), (4, 4)], fill=(255, 135, 145, 255))
    fp_draw.point([5, 4], fill=(255, 255, 255, 255))
    full_pip.save("assets/ui/hp_pip_full.png")

    empty_pip = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    ep_draw = ImageDraw.Draw(empty_pip)
    ep_draw.polygon([(7, 1), (12, 3), (12, 8), (7, 13), (2, 8), (2, 3)], fill=(35, 38, 48, 180), outline=OUTLINE)
    ep_draw.line([(5, 4), (9, 10)], fill=(18, 20, 26, 255)) # Shattered crack line
    empty_pip.save("assets/ui/hp_pip_empty.png")
    print("Saved UI pip assets")


if __name__ == "__main__":
    make_player()
    make_weapons()
    make_zombies()
    make_environment()
    make_ui()
    print("All Next-Gen AAA Indie pixel assets generated successfully!")
