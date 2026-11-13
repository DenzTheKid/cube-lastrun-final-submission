# CUBE: LAST RUN — TECHNICAL ARCHITECTURE (V1.1)
**Engine:** Godot Engine 4.7.2 (Stable)  
**Language:** GDScript (Strict Static Typing)  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Target Platform:** Windows 11 & EndeavourOS Linux (Intel N100 / Intel UHD Graphics optimized, 60+ FPS)  

---

## 1. Directory Structure

```text
res://
├── assets/
│   ├── audio/                 # 14 Synthesized 16-bit PCM WAVs (Music & SFX)
│   ├── characters/            # Cube Survivor spritesheet (144x192, 8 animation states)
│   ├── environment/           # Urban apocalypse tileset (128x64) and 3 parallax layers (480x270)
│   ├── ui/                    # HUD icons, shells, reticle, and danger skull atlas
│   ├── weapons/               # Double-barrel shotgun, break-action shells, muzzle flash
│   ├── zombies/               # Walker, Runner, Brute, Mutant, and Rear Horde wall
│   └── _quarantine/           # Isolated staging directory for verified external downloads
├── data/
├── documentation/             # Comprehensive design, controls, QA, performance, and architecture docs
│   ├── ARCHITECTURE.md
│   ├── ASSET_RESEARCH_REPORT.md
│   ├── GAMEPLAY_AND_CONTROLS.md
│   ├── PERFORMANCE_REPORT.md
│   └── QA_REPORT.md
├── scenes/
│   ├── enemies/               # rear_horde.tscn, walker, runner, brute, mutant
│   ├── main/                  # game_world.tscn, main_menu.tscn
│   ├── obstacles/             # barricade.tscn, spikes.tscn, platform.tscn, pit_killzone.tscn
│   ├── player/                # player.tscn, shotgun.tscn, shotgun_pellet.tscn
│   ├── tools/                 # test_runner.tscn (25-point automated QA harness)
│   └── ui/                    # hud.tscn, pause_menu.tscn, game_over_menu.tscn
├── scripts/
│   ├── enemies/               # rear_horde.gd, zombie_base.gd, zombie_mutant.gd
│   ├── gameplay/              # game_world.gd (camera framing & trauma screen shake)
│   ├── generation/            # level_generator.gd (20 modular patterns, fair validation, batched drawing)
│   ├── obstacles/             # hazard.gd
│   ├── player/                # player.gd, shotgun.gd, shotgun_pellet.gd
│   ├── systems/               # audio_manager.gd (autoload), game_manager.gd (autoload)
│   ├── tools/                 # test_harness.gd, asset generators
│   └── ui/                    # hud.gd, main_menu.gd, pause_menu.gd, game_over_menu.gd
├── ASSET_SECURITY_REPORT.md   # Security verification, SHA-256 hashes, and malware logs
├── ASSET_SOURCES.md           # External provenance and CC0 licensing register
├── CHANGELOG.md               # Version history and detailed changelog
├── README.md                  # Project overview and run instructions
└── project.godot              # Engine configuration (Compatibility renderer, input maps)
```

---

## 2. Core Systems & Principles

### Autoload Singletons
- **`GameManager` (`res://scripts/systems/game_manager.gd`):**  
  State machine (`MENU`, `PLAYING`, `PAUSED`, `GAME_OVER`), distance tracking, score accumulation, survival timer, difficulty progression scaling (`1.0` to `2.5x`), local high score persistence via `user://cube_lastrun_save.json`, and deferred scene transitions.
- **`AudioManager` (`res://scripts/systems/audio_manager.gd`):**  
  Manages background music looping (`music_gameplay.wav`, `music_menu.wav`) and an 8-channel polyphonic sound effect pool with randomized pitch modulation and 0.045s anti-spam voice cooldowns.

### Procedural Level Generator (`LevelGenerator`)
- Seamless horizontal chunking at 384px per chunk (24 grid units of 16px).
- Generates **20 distinct modular encounter patterns** with difficulty gating and controlled randomization.
- **Batched Rendering (`ChunkNode._draw`):** Eliminates individual `Sprite2D` node allocations per chunk, reducing node count per chunk from 74 down to 2 nodes (97% reduction).
- **Algorithmic Fairness Validation:** Strictly forbids consecutive lethal pit gaps or barricade walls. Validates forward velocity against jump clearance and recoil vault reach.
- **Garbage Collection:** Actively frees retired chunks and distant enemies once beyond `player_x - 480px`, keeping active node counts strictly bounded (~28–38 nodes).

### Double-Barrel Shotgun & Physics Integration
- Implements **5 canonical discrete aiming poses** (`FORWARD`, `DIAGONAL_UPWARD`, `STRAIGHT_UPWARD`, `DIAGONAL_DOWNWARD`, `STRAIGHT_DOWNWARD`).
- Mouse cursor angle quantization and keyboard/gamepad direct mapping (WASD / Arrow keys).
- **Recoil Jump Mechanics:**
  - Straight Downward: Pure vertical high jump (`-480 px/s`).
  - Diagonal Downward: Forward vault boost (`+140 px/s` X, `-375 px/s` Y).
  - Velocity clamping at `-540 px/s` prevents unbounded skyward ejection.
- Firing triggers 6 conical buckshot pellets with independent random angular spreads.

---

## 3. Measured Performance Profile
- **Engine Renderer:** `gl_compatibility` (OpenGL 3.3 / GLES3).
- **Frame Times:** 8.06 ms – 9.70 ms (103 – 124 FPS measured in 600-frame test).
- **Memory Footprint:** 47.73 MB static RAM.
- **Draw Calls:** 7 – 12 per frame.
