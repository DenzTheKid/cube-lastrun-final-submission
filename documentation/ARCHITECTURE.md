# CUBE: LAST RUN — TECHNICAL ARCHITECTURE
**Engine:** Godot Engine 4.7.2 (Stable)  
**Language:** GDScript (Strict Static Typing)  
**Target Platform:** Windows 11 & EndeavourOS Linux (N100 / Intel UHD Graphics optimized, 60 FPS rock-solid)

---

## 1. Directory Structure

```text
res://
├── assets/
│   ├── audio/                 # 14 Synthesized 16-bit PCM WAVs (Music & SFX)
│   ├── characters/            # Cube Survivor spritesheet (144x192, 8 animation states)
│   ├── effects/               # Particle assets and muzzle flares
│   ├── environment/           # Urban apocalypse tileset (128x64) and 3 parallax layers (480x270)
│   ├── ui/                    # HUD icons, shells, reticle, and danger skull atlas
│   ├── weapons/               # Double-barrel shotgun, break-action shells, muzzle flash
│   ├── zombies/               # Walker, Runner, Brute, Mutant, and Rear Horde wall
│   └── _quarantine/           # Isolated staging directory for untrusted downloads
├── data/
│   ├── enemy_definitions/
│   ├── game_settings/
│   └── obstacle_patterns/
├── documentation/             # Comprehensive design, controls, and architecture docs
├── scenes/
│   ├── effects/
│   ├── enemies/               # rear_horde.tscn, walker, runner, brute, mutant
│   ├── environment/
│   ├── main/                  # game_world.tscn, main_menu.tscn
│   ├── obstacles/             # barricade.tscn, spikes.tscn, platform.tscn, pit_killzone.tscn
│   ├── player/                # player.tscn, shotgun.tscn, shotgun_pellet.tscn
│   └── ui/                    # hud.tscn, pause_menu.tscn, game_over_menu.tscn
├── scripts/
│   ├── enemies/               # rear_horde.gd, zombie_base.gd, zombie_mutant.gd
│   ├── gameplay/              # game_world.gd
│   ├── generation/            # level_generator.gd (fair procedural chunk pipeline)
│   ├── obstacles/             # hazard.gd
│   ├── player/                # player.gd, shotgun.gd, shotgun_pellet.gd
│   ├── systems/               # audio_manager.gd (autoload), game_manager.gd (autoload)
│   ├── tools/                 # Python Pillow generators for pixel art & deterministic audio
│   └── ui/                    # hud.gd, main_menu.gd, pause_menu.gd, game_over_menu.gd
├── ASSET_SECURITY_REPORT.md   # Security verification, SHA-256 hashes, and malware logs
├── ASSET_SOURCES.md           # External provenance and CC0 licensing registry
└── project.godot              # Godot 4 project configuration
```

---

## 2. Core Systems & Principles

### Autoload Singletons
- **`GameManager` (`res://scripts/systems/game_manager.gd`):**  
  Owns game state machine (`MENU`, `PLAYING`, `PAUSED`, `GAME_OVER`), distance tracking, score accumulation, survival timer, difficulty progression scaling (`1.0` to `2.5x`), and local high score persistence via `user://cube_lastrun_save.json`.
- **`AudioManager` (`res://scripts/systems/audio_manager.gd`):**  
  Manages background music looping (`music_gameplay.wav`, `music_menu.wav`) and an 8-channel polyphonic sound effect pool with randomized pitch modulation.

### Procedural Level Generator (`LevelGenerator`)
- Seamless horizontal chunking at 384px per chunk (24 grid units of 16px).
- Generates 9 distinct modular encounter patterns including clear runs, spike hurdles, elevated bridges, pit gaps, barricades, and brute confrontations.
- **Fairness Validation:** Avoids consecutive bottleneck obstacles (never spawns back-to-back pits or barricade walls). Validates player horizontal velocity against jump clearance and shotgun recoil boost.
- **Garbage Collection:** Actively frees retired chunks and distant enemies once beyond `player_x - 450px`, keeping active node counts below 40 and static memory usage under 35 MB.

### Double-Barrel Shotgun & Physics Integration
- `Shotgun` acts as an independent weapon controller mounted to the cube's grip anchor.
- Computes real-time angular vectors between global player position and mouse cursor.
- Downward firing calculates `recoil_impulse = -aim_dir * recoil_strength`, applying vertical velocity directly to the player's `CharacterBody2D` while resetting coyote time, allowing aerial recovery and double jumps.
- Firing triggers 6 conical buckshot pellets (`ShotgunPellet`) with independent random angular spreads.

---

## 3. Performance & Rendering Budgets
- **Resolution:** Native viewport 480x270, scaled with `canvas_items` expand mode and integer override (960x540).
- **Filtering:** Nearest-neighbor pixel filter (`textures/canvas_textures/default_texture_filter = 0`).
- **Memory Footprint:** ~27 MB to 35 MB static RAM in runtime tests.
- **Frame Times:** Avg < 0.15 ms per frame on Intel UHD / N100 class targets (well below the 16.6ms budget for 60 FPS).
