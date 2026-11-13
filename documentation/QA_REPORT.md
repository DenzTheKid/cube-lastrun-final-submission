# CUBE: LAST RUN — QA REPORT (V1.2 360° AIMING & RECOIL VERIFICATION)
**Project:** CUBE: LAST RUN V1.2  
**Engine Version:** Godot Engine 4.7.2 (Stable)  
**QA Lead:** Antigravity Senior Game QA & Systems Engineer  
**Date:** 2026-11-13  
**Status:** ALL 25 TEST CASES PASSED (100% PASS RATE)  

---

## 1. Automated QA Test Suite Results

Test Execution Command:
`godot --headless --path "d:\Projects\GODOT\cube--lastrun" scenes/tools/test_runner.tscn`

| Test # | Test Case Description | Subsystem Verified | Result | Measured Metric / Observation |
|:---:|---|---|:---:|---|
| **01** | Main menu opens & components present | UI / Main Menu | **PASS** | PlayButton, ControlsButton, AudioRow, HighScoreLabel validated. |
| **02** | Play starts gameplay (GameWorld initializes) | Core World Loop | **PASS** | Player, Camera2D, RearHorde, LevelGenerator, HUD mounted. |
| **03** | Player runs automatically | Player Physics | **PASS** | `velocity.x` = 175.0 px/s forward charge verified without user input. |
| **04** | Player jumps | Player Movement | **PASS** | `velocity.y` = -380.0 px/s upward impulse verified on jump trigger. |
| **05** | Player lands correctly & resets coyote timer | Platformer Physics | **PASS** | Coyote timer resets to 0.12s upon touching ground; landing sound triggered. |
| **06** | Full continuous 360-degree aiming | Weapon System | **PASS** | Tested 0°, 45°, 90°, 135°, 180°, -135°, -90°, -45°, 23.5°, 162°, -162°. Smooth rotation & vertical flip verified. |
| **07** | Shooting consumes ammunition | Weapon Inventory | **PASS** | Two-shell break-action chamber verified: 2 -> 1 -> 0 shells. |
| **08** | Reload works (auto on empty & manual early) | Weapon Reload State | **PASS** | Automatic reload locks gun at 0 shells; manual reload on 1 shell works (~0.8s). |
| **09** | Recoil jump works on the ground | Tactical Mobility | **PASS** | Shooting downward (Vector2.DOWN) on ground propels player to `velocity.y` = -480.0 px/s. |
| **10** | Recoil jump works in midair | Air Control / Fall Arrest | **PASS** | Falling at +450 px/s reversed to -480 px/s instantly; allows clutch pit recovery. |
| **11** | Zombies spawn correctly with collision layer | Enemy Spawning | **PASS** | Walker spawned on Collision Layer 3 (Mask 1), Hitbox on Mask 2. |
| **12** | Zombies react to damage and die at 0 HP | Combat / Damage | **PASS** | Zombie flashes red/white, health decreases 1 -> 0, squash/fade death sequence plays. |
| **13** | Brute requires exactly 4 hits | Enemy Balance | **PASS** | Armored Brute verified with 4 HP; withstands 3 hits and dies on 4th hit. |
| **14** | Horde catches player & initiates transformation | Threat & Game Over | **PASS** | Horde collision halts player, triggers stylized infection animation (frames 42-45). |
| **15** | Unfair obstacle combinations are rejected | Level Generation | **PASS** | 50 iterations tested; zero consecutive lethal pits or barricade walls occurred. |
| **16** | Score updates correctly on distance and kills | Score & Progression | **PASS** | Distance adds 0.5 pts/meter; zombie kills add +100/+150/+200/+300 pts. |
| **17** | Pause menu stops gameplay tree | Game Flow / UI | **PASS** | Tree paused verified; process mode ALWAYS on menu allows focus navigation. |
| **18** | Resume correctly unpauses gameplay | Game Flow / UI | **PASS** | Unpauses tree, hides panel, restores mouse/gamepad focus. |
| **19** | Restart resets all game metrics cleanly | State Persistence | **PASS** | Score resets to 0, distance resets to 0.0m, difficulty resets to 1.0x. |
| **20** | Game Over triggers properly | State Machine | **PASS** | High scores saved to `user://cube_lastrun_save.json`; record banner displays. |
| **21** | Main Menu navigation transitions state | Scene Routing | **PASS** | Safely routes between Main Menu and Game World via deferred transitions. |
| **22** | Audio volume controls operate correctly | Audio System | **PASS** | SFX and Music volume sliders modulate AudioServer bus cleanly. |
| **23** | All required assets exist and resolve in VFS | Asset Integrity | **PASS** | 14 audio streams and 14 textures verified present on disk and VFS. |
| **24** | Zero runtime errors across execution | Stability Audit | **PASS** | 0 script errors, 0 null pointers, 0 unhandled exceptions. |
| **25** | Long-session memory strictly bounded | Memory Audit | **PASS** | Static memory sampled at 47.74 MB (well below 60 MB budget threshold). |

---

## 2. 360° Continuous Sweep & Grip Attachment Verification

Executed via [`scenes/tools/capture_360_test.tscn`](file:///d:/Projects/GODOT/cube--lastrun/scenes/tools/capture_360_test.tscn):
- **Full Angular Sweep:** Stepped through 0° to 360° at 15° increments.
- **Weapon Grip Integrity:** Verified that `Shotgun.position` remained locked at `(2, 4)` across every angle with zero detachment or offset drift.
- **Backward Firing (180°):** Successfully fired pellets directly leftward toward the pursuing horde with proper projectile velocity and casing ejection.
- **Downward Recoil Jump (270°):** Successfully launched survivor upward from ground (`velocity.y = -480.0 px/s`).

---

## 3. Static Analysis & Linting

Command:
`python lint_project.py d:\Projects\GODOT\cube--lastrun --pretty`

- **Total Scripts Analyzed:** 17 GDScript files
- **Total Scenes Analyzed:** 19 `.tscn` scene files
- **Total Diagnostics:** **0 Errors, 0 Warnings**
