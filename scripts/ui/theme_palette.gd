extends RefCounted
class_name ThemePalette

# Centralized color palette for CUBE: LAST RUN.
# Enforces a strict, cohesive palette across sky phases, city depth layers,
# Main Menu, Pause/Game-Over overlays, and HUD.

# Three core game-wide accent colors
const ACCENT_AMBER := Color("#f28c38")   # Primary action, focus, sun warmth, reload
const ACCENT_CYAN := Color("#38d8f2")    # Active/ON state, distance/time, cyan windows
const ACCENT_MAGENTA := Color("#e63962") # Danger, HP pips, horde proximity, neon

# UI plate & typography colors (flat fills, crisp 2px borders, zero blur)
const PLATE_BG := Color("#101221")
const PLATE_BG_ALPHA := Color(0.063, 0.071, 0.129, 0.90)
const PLATE_BG_HOVER := Color("#1b1f38")
const PLATE_BG_PRIMARY := Color("#19172b")
const PLATE_BG_PRIMARY_HOVER := Color("#261d30")
const PLATE_BG_PRESSED := Color("#0d0e1a")

const BORDER_IDLE := Color("#2e3659")
const BORDER_SUBTLE := Color("#232946")
const BORDER_OUTLINE := Color("#0a0b14")

const TEXT_PRIMARY := Color("#f2f4fa")
const TEXT_MUTED := Color("#8c96b8")
const TEXT_DIM := Color("#5c6484")
const TITLE_SHADOW := Color("#7a2832")

# Sky Phase 0: Daylight (t = 0.0)
const DAY_ZENITH := Color("#3878a8")
const DAY_UPPER := Color("#5ea4c8")
const DAY_LOWER := Color("#bdd4dc")
const DAY_HORIZON := Color("#f2dbb8")
const DAY_DISTANT_TINT := Color(0.84, 0.89, 0.96, 1.0)
const DAY_MID_TINT := Color(0.92, 0.94, 0.98, 1.0)
const DAY_FORE_TINT := Color(0.98, 0.98, 1.00, 1.0)

# Sky Phase 1: Late Afternoon (t = 0.35)
const AFTERNOON_ZENITH := Color("#243c6e")
const AFTERNOON_UPPER := Color("#5e466e")
const AFTERNOON_LOWER := Color("#c8684c")
const AFTERNOON_HORIZON := Color("#f29e4c")
const AFTERNOON_DISTANT_TINT := Color(0.94, 0.80, 0.84, 1.0)
const AFTERNOON_MID_TINT := Color(0.95, 0.88, 0.92, 1.0)
const AFTERNOON_FORE_TINT := Color(0.98, 0.95, 0.96, 1.0)

# Sky Phase 2: Dusk (t = 0.65) — existing red-magenta dusk backbone
const DUSK_ZENITH := Color("#0f1021")
const DUSK_UPPER := Color("#2b193d")
const DUSK_LOWER := Color("#7a2832")
const DUSK_HORIZON := Color("#f28c38")
const DUSK_DISTANT_TINT := Color(0.92, 0.74, 0.82, 1.0)
const DUSK_MID_TINT := Color(0.92, 0.86, 0.94, 1.0)
const DUSK_FORE_TINT := Color(0.96, 0.92, 0.95, 1.0)

# Sky Phase 3: Night (t = 1.0)
const NIGHT_ZENITH := Color("#080914")
const NIGHT_UPPER := Color("#111328")
const NIGHT_LOWER := Color("#1d1736")
const NIGHT_HORIZON := Color("#2b193d")
const NIGHT_DISTANT_TINT := Color(0.72, 0.75, 0.90, 1.0)
const NIGHT_MID_TINT := Color(0.84, 0.86, 0.95, 1.0)
const NIGHT_FORE_TINT := Color(0.92, 0.92, 0.97, 1.0)

const MOON_COLOR := Color("#f6f0c8")
