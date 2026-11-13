"""
Generate premium pixel-art assets for CUBE: LAST RUN.
Uses Pillow to create crisp, shaded, outlines-enforced 2D sprite sheets.
"""
import os
from PIL import Image, ImageDraw

os.makedirs("assets/characters", exist_ok=True)
os.makedirs("assets/weapons", exist_ok=True)
os.makedirs("assets/zombies", exist_ok=True)
os.makedirs("assets/environment", exist_ok=True)
os.makedirs("assets/effects", exist_ok=True)
os.makedirs("assets/ui", exist_ok=True)

OUTLINE = (18, 22, 30, 255)

def draw_shaded_box(draw, x0, y0, w, h, fill_col, highlight_col, shadow_col, outline_col=OUTLINE):
    # Outline
    draw.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], fill=fill_col, outline=outline_col)
    # Highlight (top and left inner edge)
    draw.line([x0 + 1, y0 + 1, x0 + w - 2, y0 + 1], fill=highlight_col)
    draw.line([x0 + 1, y0 + 1, x0 + 1, y0 + h - 2], fill=highlight_col)
    # Shadow (bottom and right inner edge)
    draw.line([x0 + 1, y0 + h - 2, x0 + w - 2, y0 + h - 2], fill=shadow_col)
    draw.line([x0 + w - 2, y0 + 1, x0 + w - 2, y0 + h - 2], fill=shadow_col)

# -------------------------------------------------------------
# 1. PLAYER: CUBE SURVIVOR
# Frame size: 24x24. Rows:
# Row 0: Idle (4 frames)
# Row 1: Run (6 frames)
# Row 2: Jump (2 frames)
# Row 3: Fall (2 frames)
# Row 4: Land (2 frames)
# Row 5: Hurt (2 frames)
# Row 6: Death (4 frames)
# Row 7: Transform (4 frames)
# Total size: (24 * 6) x (24 * 8) = 144 x 192
# -------------------------------------------------------------
def make_player():
    fw, fh = 24, 24
    cols = 6
    rows = 8
    img = Image.new("RGBA", (fw * cols, fh * rows), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    CYAN_BASE = (42, 157, 143, 255)
    CYAN_HI = (72, 202, 228, 255)
    CYAN_SH = (38, 70, 83, 255)

    FACE_BASE = (244, 162, 97, 255)
    FACE_HI = (247, 184, 133, 255)
    FACE_SH = (231, 111, 81, 255)

    HEADBAND = (230, 57, 70, 255)
    HEADBAND_HI = (255, 107, 107, 255)

    WHITE = (245, 245, 245, 255)
    BLACK = (20, 20, 25, 255)
    HURT_RED = (230, 50, 50, 255)
    ZOMB_BASE = (88, 129, 87, 255)
    ZOMB_HI = (120, 165, 110, 255)
    ZOMB_SH = (52, 78, 65, 255)

    def draw_player_cube(cx, cy, bob_y=0, leg_phase=0, is_hurt=False, is_zomb=False, eyes_open=True, dead_phase=0):
        if dead_phase >= 3:
            # Shattered cube debris
            draw.rectangle([cx + 3, cy + 18, cx + 8, cy + 22], fill=CYAN_BASE, outline=OUTLINE)
            draw.rectangle([cx + 10, cy + 19, cx + 15, cy + 22], fill=CYAN_SH, outline=OUTLINE)
            draw.rectangle([cx + 16, cy + 17, cx + 21, cy + 22], fill=HEADBAND, outline=OUTLINE)
            return
        elif dead_phase == 2:
            draw_shaded_box(draw, cx + 4, cy + 12, 16, 10, CYAN_SH, CYAN_BASE, OUTLINE)
            draw.rectangle([cx + 8, cy + 14, cx + 12, cy + 16], fill=HURT_RED)
            return
        elif dead_phase == 1:
            draw_shaded_box(draw, cx + 4, cy + 6, 16, 14, HURT_RED, WHITE, OUTLINE)
            return

        bx = cx + 4
        by = cy + 4 + bob_y
        bw, bh = 16, 15

        base_col = HURT_RED if is_hurt else (ZOMB_BASE if is_zomb else CYAN_BASE)
        hi_col = WHITE if is_hurt else (ZOMB_HI if is_zomb else CYAN_HI)
        sh_col = OUTLINE if is_hurt else (ZOMB_SH if is_zomb else CYAN_SH)

        # Body cube
        draw_shaded_box(draw, bx, by, bw, bh, base_col, hi_col, sh_col)

        # Headband across upper forehead
        draw.rectangle([bx + 1, by + 2, bx + bw - 2, by + 4], fill=HEADBAND)
        draw.line([bx + 1, by + 2, bx + bw - 2, by + 2], fill=HEADBAND_HI)
        # Headband knot / tail behind
        draw.rectangle([bx - 2, by + 3, bx, by + 5], fill=HEADBAND)

        # Face visor / eye slit area
        face_x0 = bx + 3
        face_y0 = by + 5
        face_w = bw - 5
        face_h = 6
        draw.rectangle([face_x0, face_y0, face_x0 + face_w - 1, face_y0 + face_h - 1], fill=FACE_BASE)

        # Eyes
        if is_zomb:
            # Glowing feral red/yellow zombie eyes
            draw.rectangle([face_x0 + 2, face_y0 + 1, face_x0 + 4, face_y0 + 3], fill=(255, 230, 50, 255))
            draw.point([face_x0 + 3, face_y0 + 2], fill=(255, 0, 0, 255))
            draw.rectangle([face_x0 + 6, face_y0 + 1, face_x0 + 8, face_y0 + 3], fill=(255, 230, 50, 255))
            draw.point([face_x0 + 7, face_y0 + 2], fill=(255, 0, 0, 255))
            # Zombie snarl teeth
            draw.line([face_x0 + 3, face_y0 + 5, face_x0 + 8, face_y0 + 5], fill=(30, 40, 20, 255))
        elif is_hurt:
            # X eyes
            draw.line([face_x0 + 2, face_y0 + 1, face_x0 + 4, face_y0 + 3], fill=BLACK)
            draw.line([face_x0 + 2, face_y0 + 3, face_x0 + 4, face_y0 + 1], fill=BLACK)
            draw.line([face_x0 + 6, face_y0 + 1, face_x0 + 8, face_y0 + 3], fill=BLACK)
            draw.line([face_x0 + 6, face_y0 + 3, face_x0 + 8, face_y0 + 1], fill=BLACK)
        elif eyes_open:
            # Expressive eyes looking forward/right
            draw.rectangle([face_x0 + 2, face_y0 + 1, face_x0 + 4, face_y0 + 3], fill=WHITE)
            draw.rectangle([face_x0 + 3, face_y0 + 2, face_x0 + 4, face_y0 + 3], fill=BLACK)
            draw.rectangle([face_x0 + 6, face_y0 + 1, face_x0 + 8, face_y0 + 3], fill=WHITE)
            draw.rectangle([face_x0 + 7, face_y0 + 2, face_x0 + 8, face_y0 + 3], fill=BLACK)
        else:
            # Blink line
            draw.line([face_x0 + 2, face_y0 + 2, face_x0 + 4, face_y0 + 2], fill=BLACK)
            draw.line([face_x0 + 6, face_y0 + 2, face_x0 + 8, face_y0 + 2], fill=BLACK)

        # Belt / holster detail
        draw.line([bx + 1, by + 12, bx + bw - 2, by + 12], fill=(50, 40, 30, 255))
        draw.point([bx + 7, by + 12], fill=(230, 190, 50, 255)) # brass buckle

        # Running feet / legs
        leg_y = by + bh
        if leg_phase == 1:
            draw.rectangle([bx + 2, leg_y - 1, bx + 5, leg_y + 2], fill=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 2, bx + 12, leg_y + 1], fill=OUTLINE)
        elif leg_phase == 2:
            draw.rectangle([bx + 1, leg_y - 2, bx + 4, leg_y + 1], fill=OUTLINE)
            draw.rectangle([bx + 10, leg_y - 1, bx + 13, leg_y + 2], fill=OUTLINE)
        elif leg_phase == 3: # Jump tuck
            draw.rectangle([bx + 3, leg_y - 2, bx + 6, leg_y], fill=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 2, bx + 12, leg_y], fill=OUTLINE)
        else: # Standing
            draw.rectangle([bx + 3, leg_y - 1, bx + 6, leg_y + 2], fill=OUTLINE)
            draw.rectangle([bx + 9, leg_y - 1, bx + 12, leg_y + 2], fill=OUTLINE)

    # Row 0: Idle (4 frames)
    for i in range(4):
        bob = 1 if i in (1, 2) else 0
        blink = (i == 3)
        draw_player_cube(i * fw, 0 * fh, bob_y=bob, leg_phase=0, eyes_open=(not blink))

    # Row 1: Run (6 frames)
    bobs = [0, -1, 0, 1, 0, -1]
    legs = [1, 2, 1, 2, 1, 2]
    for i in range(6):
        draw_player_cube(i * fw, 1 * fh, bob_y=bobs[i], leg_phase=legs[i])

    # Row 2: Jump (2 frames)
    draw_player_cube(0 * fw, 2 * fh, bob_y=1, leg_phase=0) # anticipation
    draw_player_cube(1 * fw, 2 * fh, bob_y=-2, leg_phase=3) # air leap

    # Row 3: Fall (2 frames)
    draw_player_cube(0 * fw, 3 * fh, bob_y=0, leg_phase=3)
    draw_player_cube(1 * fw, 3 * fh, bob_y=1, leg_phase=3)

    # Row 4: Land (2 frames)
    draw_player_cube(0 * fw, 4 * fh, bob_y=2, leg_phase=0) # squish
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

make_player()

# -------------------------------------------------------------
# 2. WEAPONS: DOUBLE-BARREL SHOTGUN & SHELLS
# -------------------------------------------------------------
def make_weapons():
    # Shotgun sprite: 24x10 pixels
    # Anchor/Pivot is around (4, 5) where the survivor's hand holds the grip.
    w_img = Image.new("RGBA", (24, 10), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(w_img)

    WOOD_DARK = (88, 47, 14, 255)
    WOOD_LIGHT = (140, 78, 25, 255)
    STEEL_DARK = (45, 50, 60, 255)
    STEEL_LIGHT = (130, 140, 155, 255)
    STEEL_HI = (200, 210, 225, 255)
    BRASS = (218, 165, 32, 255)

    # Stock & Grip
    w_draw.polygon([(0, 4), (5, 3), (7, 5), (5, 7), (0, 7)], fill=WOOD_DARK, outline=OUTLINE)
    w_draw.line([(1, 5), (4, 4)], fill=WOOD_LIGHT)

    # Receiver / Chamber
    w_draw.rectangle([7, 3, 11, 7], fill=STEEL_DARK, outline=OUTLINE)
    w_draw.point([8, 6], fill=BRASS) # hinge pin
    w_draw.point([7, 8], fill=STEEL_LIGHT) # trigger

    # Double Barrel (twin stacked or side-by-side profile)
    w_draw.rectangle([11, 3, 22, 5], fill=STEEL_LIGHT, outline=OUTLINE)
    w_draw.line([12, 3, 21, 3], fill=STEEL_HI) # top barrel highlight
    w_draw.rectangle([11, 5, 22, 7], fill=STEEL_DARK, outline=OUTLINE)
    # Muzzle tip
    w_draw.line([22, 3, 22, 7], fill=(20, 20, 20, 255))
    # Fore-end wooden grip under barrel
    w_draw.rectangle([11, 7, 16, 8], fill=WOOD_DARK, outline=OUTLINE)

    w_img.save("assets/weapons/shotgun.png")
    print("Saved assets/weapons/shotgun.png (24x10)")

    # Shells (16x16: 2 frames: live shell, spent casing)
    sh_img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(sh_img)

    RED_SHELL = (200, 30, 30, 255)
    RED_HI = (240, 80, 80, 255)
    SPENT_DARK = (60, 50, 40, 255)

    # Frame 0: Loaded Shell (red plastic cylinder with gold base)
    sh_draw.rectangle([1, 2, 3, 6], fill=BRASS, outline=OUTLINE)
    sh_draw.rectangle([3, 2, 7, 6], fill=RED_SHELL, outline=OUTLINE)
    sh_draw.line([4, 3, 6, 3], fill=RED_HI)

    # Frame 1: Spent casing (smoke hole at tip)
    sh_draw.rectangle([9, 2, 11, 6], fill=BRASS, outline=OUTLINE)
    sh_draw.rectangle([11, 2, 15, 6], fill=SPENT_DARK, outline=OUTLINE)
    sh_draw.point([15, 4], fill=(10, 10, 10, 255)) # open empty mouth

    sh_img.save("assets/weapons/shotgun_shell.png")
    print("Saved assets/weapons/shotgun_shell.png (16x8)")

    # Muzzle Flash (32x16: 2 frames)
    mf_img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    mf_draw = ImageDraw.Draw(mf_img)
    # Frame 0: Big explosive blast
    mf_draw.polygon([(0, 8), (6, 3), (12, 1), (9, 7), (15, 8), (9, 9), (12, 15), (6, 13)], fill=(255, 120, 0, 255))
    mf_draw.polygon([(0, 8), (4, 5), (8, 4), (6, 7), (10, 8), (6, 9), (8, 12), (4, 11)], fill=(255, 230, 80, 255))
    mf_draw.ellipse([0, 6, 4, 10], fill=(255, 255, 255, 255))
    # Frame 1: Fading smoke puff
    mf_draw.ellipse([18, 5, 26, 11], fill=(180, 180, 190, 200))
    mf_draw.ellipse([22, 6, 28, 10], fill=(220, 220, 230, 150))
    mf_img.save("assets/weapons/muzzle_flash.png")
    print("Saved assets/weapons/muzzle_flash.png (32x16)")

make_weapons()

# -------------------------------------------------------------
# 3. ZOMBIE ENEMIES: WALKER, RUNNER, BRUTE, MUTANT
# -------------------------------------------------------------
def make_zombies():
    # Sheet: 4 rows, 4 frames each.
    # Row 0: Walker (24x24)
    # Row 1: Runner (24x24)
    # Row 2: Brute (36x36 -> let's make uniform 36x36 grid or separate images!)
    # Separate images are much cleaner and avoid oversized padding!

    # A. Walker (24x24, 4 frames)
    w_img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(w_img)
    W_BASE = (75, 110, 75, 255)
    W_HI = (105, 145, 95, 255)
    W_SH = (45, 70, 45, 255)
    SHIRT = (100, 110, 125, 255)

    for i in range(4):
        cx = i * 24
        bob = 1 if i in (1, 3) else 0
        leg = 1 if i % 2 == 0 else 2
        bx, by = cx + 4, 4 + bob
        # Shaded cube
        draw_shaded_box(w_draw, bx, by, 16, 15, W_BASE, W_HI, W_SH)
        # Tattered shirt bottom half
        w_draw.rectangle([bx + 1, by + 9, bx + 14, by + 13], fill=SHIRT)
        w_draw.line([bx + 3, by + 8, bx + 5, by + 10], fill=W_SH) # tear
        # Milky undead eye & socket
        w_draw.rectangle([bx + 8, by + 4, bx + 11, by + 7], fill=(20, 30, 20, 255))
        w_draw.point([bx + 9, by + 5], fill=(220, 230, 210, 255))
        # Drooling rotting jaw
        w_draw.rectangle([bx + 9, by + 11, bx + 13, by + 13], fill=(30, 20, 20, 255))
        w_draw.point([bx + 10, by + 11], fill=(240, 240, 220, 255)) # tooth
        w_draw.point([bx + 12, by + 14], fill=(100, 180, 50, 255)) # slime drip
        # Shambling arms reaching out right
        arm_reach = bx + 14 + (2 if i in (1, 2) else 0)
        w_draw.rectangle([bx + 10, by + 6, arm_reach, by + 8], fill=W_BASE, outline=OUTLINE)
        # Feet
        if leg == 1:
            w_draw.rectangle([bx + 3, by + 15, bx + 6, by + 18], fill=OUTLINE)
            w_draw.rectangle([bx + 9, by + 14, bx + 12, by + 17], fill=OUTLINE)
        else:
            w_draw.rectangle([bx + 3, by + 14, bx + 6, by + 17], fill=OUTLINE)
            w_draw.rectangle([bx + 9, by + 15, bx + 12, by + 18], fill=OUTLINE)

    w_img.save("assets/zombies/zombie_walker.png")
    print("Saved assets/zombies/zombie_walker.png (96x24)")

    # B. Runner (24x24, 4 frames) - aggressive red/crimson feral zombie
    r_img = Image.new("RGBA", (24 * 4, 24), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(r_img)
    R_BASE = (165, 35, 45, 255)
    R_HI = (215, 60, 65, 255)
    R_SH = (100, 20, 25, 255)

    for i in range(4):
        cx = i * 24
        bob = (i % 2) * 2
        bx, by = cx + 4, 4 + bob
        draw_shaded_box(r_draw, bx, by, 16, 14, R_BASE, R_HI, R_SH)
        # Glowing yellow feral eyes
        r_draw.rectangle([bx + 7, by + 3, bx + 10, by + 5], fill=(255, 240, 40, 255))
        r_draw.point([bx + 8, by + 4], fill=(180, 20, 20, 255))
        r_draw.rectangle([bx + 11, by + 3, bx + 13, by + 5], fill=(255, 240, 40, 255))
        # Snarl mouth with fangs
        r_draw.rectangle([bx + 8, by + 8, bx + 13, by + 11], fill=(20, 10, 10, 255))
        r_draw.point([bx + 9, by + 9], fill=(255, 255, 255, 255))
        r_draw.point([bx + 12, by + 9], fill=(255, 255, 255, 255))
        # Claw hands
        r_draw.rectangle([bx + 12, by + 5, bx + 17, by + 8], fill=R_BASE, outline=OUTLINE)
        # Sprinting legs
        if i % 2 == 0:
            r_draw.rectangle([bx + 1, by + 14, bx + 4, by + 18], fill=OUTLINE)
            r_draw.rectangle([bx + 11, by + 13, bx + 14, by + 16], fill=OUTLINE)
        else:
            r_draw.rectangle([bx + 3, by + 13, bx + 6, by + 16], fill=OUTLINE)
            r_draw.rectangle([bx + 9, by + 14, bx + 12, by + 18], fill=OUTLINE)

    r_img.save("assets/zombies/zombie_runner.png")
    print("Saved assets/zombies/zombie_runner.png (96x24)")

    # C. Brute (36x36, 4 frames) - Heavy tank zombie with metal armor plate
    b_img = Image.new("RGBA", (36 * 4, 36), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(b_img)
    B_BASE = (65, 85, 95, 255)
    B_HI = (95, 120, 135, 255)
    B_SH = (35, 45, 55, 255)
    METAL = (160, 165, 175, 255)

    for i in range(4):
        cx = i * 36
        bob = (i % 2)
        bx, by = cx + 5, 5 + bob
        bw, bh = 26, 24
        draw_shaded_box(b_draw, bx, by, bw, bh, B_BASE, B_HI, B_SH)
        # Welded metal armor chest plate with bolts
        b_draw.rectangle([bx + 4, by + 8, bx + 18, by + 18], fill=METAL, outline=OUTLINE)
        b_draw.point([bx + 5, by + 9], fill=(40, 40, 40, 255))
        b_draw.point([bx + 17, by + 9], fill=(40, 40, 40, 255))
        b_draw.point([bx + 5, by + 17], fill=(40, 40, 40, 255))
        b_draw.point([bx + 17, by + 17], fill=(40, 40, 40, 255))
        # Deep menacing red eye slot
        b_draw.rectangle([bx + 12, by + 4, bx + 20, by + 7], fill=(20, 10, 10, 255))
        b_draw.line([bx + 14, by + 5, bx + 19, by + 5], fill=(255, 40, 40, 255))
        # Shoulder spikes / rebar
        b_draw.polygon([(bx + 2, by + 2), (bx + 5, by - 3), (bx + 7, by + 2)], fill=(120, 120, 130, 255), outline=OUTLINE)
        # Huge fists
        b_draw.rectangle([bx + 18, by + 12, bx + 27, by + 19], fill=B_BASE, outline=OUTLINE)
        # Heavy stomping legs
        if i % 2 == 0:
            b_draw.rectangle([bx + 4, by + bh, bx + 10, by + bh + 4], fill=OUTLINE)
            b_draw.rectangle([bx + 15, by + bh - 1, bx + 21, by + bh + 3], fill=OUTLINE)
        else:
            b_draw.rectangle([bx + 4, by + bh - 1, bx + 10, by + bh + 3], fill=OUTLINE)
            b_draw.rectangle([bx + 15, by + bh, bx + 21, by + bh + 4], fill=OUTLINE)

    b_img.save("assets/zombies/zombie_brute.png")
    print("Saved assets/zombies/zombie_brute.png (144x36)")

    # D. Mutant (26x26, 4 frames) - Toxic radioactive mutated green cube
    m_img = Image.new("RGBA", (26 * 4, 26), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(m_img)
    M_BASE = (50, 180, 40, 255)
    M_HI = (120, 240, 70, 255)
    M_SH = (25, 90, 25, 255)
    PURPLE = (140, 30, 180, 255)

    for i in range(4):
        cx = i * 26
        bob = 1 if i in (1, 2) else 0
        bx, by = cx + 4, 4 + bob
        draw_shaded_box(m_draw, bx, by, 18, 16, M_BASE, M_HI, M_SH)
        # Mutated purple veins
        m_draw.line([bx + 2, by + 10, bx + 8, by + 12], fill=PURPLE)
        m_draw.line([bx + 8, by + 12, bx + 14, by + 8], fill=PURPLE)
        # 3 asymmetrical glowing eyes
        m_draw.rectangle([bx + 4, by + 4, bx + 7, by + 7], fill=(255, 255, 0, 255))
        m_draw.point([bx + 5, by + 5], fill=(20, 20, 20, 255))
        m_draw.rectangle([bx + 10, by + 3, bx + 12, by + 5], fill=(255, 80, 80, 255))
        m_draw.point([bx + 11, by + 4], fill=(20, 20, 20, 255))
        m_draw.rectangle([bx + 13, by + 6, bx + 15, by + 8], fill=(0, 240, 255, 255))
        # Acidic tendril / mouth
        m_draw.rectangle([bx + 7, by + 10, bx + 13, by + 13], fill=(20, 50, 20, 255))
        m_draw.point([bx + 9, by + 14], fill=(120, 255, 50, 255))
        # Spidery leg stubs
        m_draw.rectangle([bx + 2, by + 16, bx + 5, by + 19], fill=OUTLINE)
        m_draw.rectangle([bx + 7, by + 16, bx + 10, by + 20], fill=OUTLINE)
        m_draw.rectangle([bx + 12, by + 16, bx + 15, by + 19], fill=OUTLINE)

    m_img.save("assets/zombies/zombie_mutant.png")
    print("Saved assets/zombies/zombie_mutant.png (104x26)")

make_zombies()

# -------------------------------------------------------------
# 4. REAR ZOMBIE HORDE (Wall of darkness, grasping claws, glowing eyes)
# -------------------------------------------------------------
def make_horde():
    hw, hh = 128, 360
    h_img = Image.new("RGBA", (hw, hh), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(h_img)

    # Gradient of darkness from left (x=0 solid dark) to right (x=128 transparent mist)
    for x in range(hw):
        alpha = int(255 * (1.0 - (x / hw) ** 1.3))
        col = (15, 10, 20, alpha)
        h_draw.line([x, 0, x, hh], fill=col)

    # Horde eyes and reaching arms throughout the column
    import random
    rnd = random.Random(42)
    for _ in range(50):
        ex = rnd.randint(10, 80)
        ey = rnd.randint(10, hh - 20)
        eye_col = rnd.choice([(255, 50, 50, 230), (255, 220, 40, 230), (100, 255, 100, 230)])
        h_draw.rectangle([ex, ey, ex + 3, ey + 2], fill=eye_col)
        h_draw.rectangle([ex + 6, ey, ex + 9, ey + 2], fill=eye_col)

    # Reaching claws / silhouettes protruding to the right
    for y in range(20, hh - 20, 28):
        arm_len = rnd.randint(70, 115)
        # Dark arm silhouette
        h_draw.polygon([(40, y + 2), (arm_len, y - 2), (arm_len + 8, y), (arm_len, y + 4), (40, y + 8)], fill=(12, 10, 16, 230))
        # Sharp claws
        h_draw.line([arm_len, y - 2, arm_len + 8, y - 4], fill=(20, 15, 25, 240), width=2)
        h_draw.line([arm_len + 2, y, arm_len + 10, y], fill=(20, 15, 25, 240), width=2)
        h_draw.line([arm_len, y + 4, arm_len + 8, y + 6], fill=(20, 15, 25, 240), width=2)

    h_img.save("assets/zombies/horde_wall.png")
    print("Saved assets/zombies/horde_wall.png (128x360)")

make_horde()

# -------------------------------------------------------------
# 5. ENVIRONMENT: APOCALYPTIC URBAN TILES & PARALLAX BACKGROUNDS
# -------------------------------------------------------------
def make_environment():
    # A. Urban Tileset (128x64 image containing 8x4 grid of 16x16 tiles)
    tw, th = 16, 16
    t_img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    t_draw = ImageDraw.Draw(t_img)

    ROAD_DARK = (40, 44, 52, 255)
    ROAD_LIGHT = (58, 63, 75, 255)
    CURB = (120, 125, 135, 255)
    YELLOW_LINE = (235, 185, 45, 255)
    DIRT = (70, 55, 45, 255)
    SPIKE_METAL = (160, 170, 180, 255)
    SLUDGE = (40, 180, 60, 255)

    # Tile (0,0): Road surface with top curb
    t_draw.rectangle([0, 0, 15, 3], fill=CURB, outline=OUTLINE)
    t_draw.rectangle([0, 4, 15, 15], fill=ROAD_DARK)
    t_draw.line([0, 4, 15, 4], fill=ROAD_LIGHT)

    # Tile (1,0): Road surface with yellow hazard dash
    t_draw.rectangle([16, 0, 31, 15], fill=ROAD_DARK)
    t_draw.rectangle([18, 6, 29, 9], fill=YELLOW_LINE)
    t_draw.line([16, 0, 31, 0], fill=ROAD_LIGHT)

    # Tile (2,0): Road underground fill
    t_draw.rectangle([32, 0, 47, 15], fill=DIRT, outline=OUTLINE)
    t_draw.point([36, 4], fill=(100, 80, 65, 255))
    t_draw.point([42, 11], fill=(100, 80, 65, 255))

    # Tile (3,0): Metal Road Spikes (Obstacle)
    for sx in [49, 53, 57, 61]:
        t_draw.polygon([(sx, 15), (sx + 2, 4), (sx + 4, 15)], fill=SPIKE_METAL, outline=OUTLINE)
        t_draw.line([(sx + 1, 14), (sx + 2, 5)], fill=(230, 240, 250, 255))

    # Tile (4,0): Industrial Barricade / Concrete Jersey Barrier
    t_draw.polygon([(65, 15), (68, 3), (76, 3), (79, 15)], fill=CURB, outline=OUTLINE)
    t_draw.polygon([(69, 5), (75, 5), (73, 13), (67, 13)], fill=(220, 60, 50, 255)) # red reflector

    # Tile (5,0): Toxic Sludge / Acid puddle (Pit obstacle)
    t_draw.rectangle([80, 8, 95, 15], fill=SLUDGE, outline=OUTLINE)
    t_draw.ellipse([83, 5, 87, 9], fill=(150, 255, 100, 255)) # bubble
    t_draw.ellipse([89, 7, 93, 10], fill=(150, 255, 100, 255))

    # Tile (6,0): Platform Grate (Suspended bridge)
    t_draw.rectangle([96, 2, 111, 7], fill=SPIKE_METAL, outline=OUTLINE)
    for gx in range(98, 110, 3):
        t_draw.line([gx, 3, gx, 6], fill=(50, 50, 60, 255))

    # Tile (7,0): Warning Sign (Hazard skull)
    t_draw.rectangle([114, 1, 126, 12], fill=YELLOW_LINE, outline=OUTLINE)
    t_draw.rectangle([117, 3, 123, 8], fill=OUTLINE)
    t_draw.point([118, 5], fill=YELLOW_LINE)
    t_draw.point([122, 5], fill=YELLOW_LINE)
    t_draw.line([120, 13, 120, 15], fill=SPIKE_METAL)

    t_img.save("assets/environment/urban_tiles.png")
    print("Saved assets/environment/urban_tiles.png (128x64)")

    # B. Parallax Layers (480x270 viewport)
    # Layer 1: Apocalyptic Twilight Sky (Smog & Dark Red Gradient)
    sky = Image.new("RGBA", (480, 270), (0, 0, 0, 255))
    s_draw = ImageDraw.Draw(sky)
    for y in range(270):
        # Top: deep dusk purple (25, 18, 35) -> middle toxic orange (120, 45, 30) -> horizon blood red (85, 20, 25)
        if y < 140:
            t = y / 140.0
            r = int(25 * (1 - t) + 130 * t)
            g = int(18 * (1 - t) + 45 * t)
            b = int(35 * (1 - t) + 30 * t)
        else:
            t = (y - 140) / 130.0
            r = int(130 * (1 - t) + 70 * t)
            g = int(45 * (1 - t) + 20 * t)
            b = int(30 * (1 - t) + 25 * t)
        s_draw.line([0, y, 480, y], fill=(r, g, b, 255))
    # Distant toxic sun / moon haze
    s_draw.ellipse([340, 60, 400, 120], fill=(220, 100, 50, 90))
    s_draw.ellipse([355, 75, 385, 105], fill=(255, 180, 100, 160))
    sky.save("assets/environment/parallax_sky.png")
    print("Saved assets/environment/parallax_sky.png (480x270)")

    # Layer 2: Distant Skyline Silhouette (Seamless 480x270)
    dist = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(dist)
    SIL_COL = (38, 26, 46, 220)
    # Draw skyline of jagged ruined buildings
    import random
    rnd = random.Random(101)
    bx = 0
    while bx < 480:
        bw = rnd.randint(25, 55)
        bh = rnd.randint(60, 140)
        by = 220 - bh
        d_draw.rectangle([bx, by, bx + bw, 270], fill=SIL_COL)
        # Antenna / broken spire
        if rnd.random() > 0.4:
            d_draw.line([bx + bw // 2, by, bx + bw // 2, by - rnd.randint(8, 25)], fill=SIL_COL, width=2)
        # Broken window grid
        for wy in range(by + 10, 210, 12):
            for wx in range(bx + 4, bx + bw - 6, 8):
                if rnd.random() > 0.6:
                    d_draw.rectangle([wx, wy, wx + 3, wy + 5], fill=(200, 120, 60, 80))
        bx += bw - 2
    dist.save("assets/environment/parallax_skyline_distant.png")
    print("Saved assets/environment/parallax_skyline_distant.png (480x270)")

    # Layer 3: Midground Destroyed Buildings & Highway Overpasses (480x270)
    mid = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mid)
    MID_COL = (24, 20, 32, 255)
    MID_HI = (45, 40, 55, 255)
    bx = 0
    rnd = random.Random(202)
    while bx < 480:
        bw = rnd.randint(40, 80)
        bh = rnd.randint(70, 160)
        by = 230 - bh
        m_draw.rectangle([bx, by, bx + bw, 270], fill=MID_COL)
        m_draw.line([bx, by, bx + bw, by], fill=MID_HI, width=2)
        # Rusted billboard on roof
        if rnd.random() > 0.5:
            bb_w = bw - 14
            m_draw.rectangle([bx + 7, by - 24, bx + 7 + bb_w, by - 4], fill=(80, 30, 30, 255), outline=OUTLINE)
            m_draw.line([bx + 12, by - 4, bx + 12, by], fill=OUTLINE, width=2)
            m_draw.line([bx + bb_w + 2, by - 4, bx + bb_w + 2, by], fill=OUTLINE, width=2)
        # Broken windows
        for wy in range(by + 14, 220, 14):
            for wx in range(bx + 6, bx + bw - 8, 10):
                if rnd.random() > 0.3:
                    m_draw.rectangle([wx, wy, wx + 4, wy + 7], fill=(15, 12, 20, 255))
        bx += bw + rnd.randint(5, 20)
    mid.save("assets/environment/parallax_buildings_mid.png")
    print("Saved assets/environment/parallax_buildings_mid.png (480x270)")

make_environment()

# -------------------------------------------------------------
# 6. UI HUD ELEMENTS & ICONS
# -------------------------------------------------------------
def make_ui():
    ui_img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    u_draw = ImageDraw.Draw(ui_img)

    # Ammo HUD: Loaded Shell Icon (16x24)
    # Shell 1: Loaded
    draw_shaded_box(u_draw, 4, 4, 12, 24, (210, 40, 40, 255), (250, 90, 90, 255), (140, 20, 20, 255))
    u_draw.rectangle([4, 20, 15, 27], fill=(218, 165, 32, 255), outline=OUTLINE) # brass rim
    # Shell 2: Empty casing / reload indicator
    draw_shaded_box(u_draw, 22, 4, 12, 24, (60, 65, 75, 255), (90, 95, 110, 255), (35, 40, 48, 255))
    u_draw.rectangle([22, 20, 33, 27], fill=(140, 110, 30, 255), outline=OUTLINE)

    # Horde Proximity Skull Icon (16x16)
    u_draw.rectangle([42, 6, 54, 17], fill=(235, 235, 240, 255), outline=OUTLINE)
    u_draw.rectangle([45, 17, 51, 21], fill=(235, 235, 240, 255), outline=OUTLINE)
    # Eye sockets
    u_draw.rectangle([44, 9, 47, 12], fill=(200, 30, 30, 255))
    u_draw.rectangle([49, 9, 52, 12], fill=(200, 30, 30, 255))
    u_draw.point([45, 10], fill=(255, 255, 255, 255))
    u_draw.point([50, 10], fill=(255, 255, 255, 255))

    # Crosshair / Directional Aim Reticle (16x16)
    u_draw.ellipse([64, 4, 76, 16], outline=(255, 80, 80, 220), width=1)
    u_draw.line([70, 2, 70, 18], fill=(255, 255, 255, 240))
    u_draw.line([62, 10, 78, 10], fill=(255, 255, 255, 240))
    u_draw.point([70, 10], fill=(255, 0, 0, 255))

    # Distance Flag / Milestone Icon (16x16)
    u_draw.line([88, 5, 88, 23], fill=(200, 200, 210, 255), width=2)
    u_draw.polygon([(90, 6), (102, 11), (90, 16)], fill=(240, 180, 40, 255), outline=OUTLINE)

    ui_img.save("assets/ui/hud_atlas.png")
    print("Saved assets/ui/hud_atlas.png (128x64)")

make_ui()
print("All pixel assets generated successfully!")
