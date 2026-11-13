# CHANGELOG — CUBE: LAST RUN

## [v1.1.0] — 2026-11-13 (V1.1 Complete Audit, Repair & Premium Polish)

### Added
- **Discrete 5-Directional Aiming System:**
  - Added strict 5-pose aiming (`FORWARD`, `DIAGONAL_UPWARD`, `STRAIGHT_UPWARD`, `DIAGONAL_DOWNWARD`, `STRAIGHT_DOWNWARD`).
  - Added discrete keyboard/gamepad aiming mapping (WASD / Arrows) alongside cursor direction quantization.
  - Connected character animation and eye orientation to the active aim direction.
- **Trauma-Based Screen Shake:**
  - Added quadratic decay camera shake to `GameWorld`: subtle shake on standard shotgun blasts (0.18 trauma), heavy punch on downward recoil jumps (0.28 trauma), and sharp jolt on hazard damage (0.45 trauma).
- **Procedural Generation Expansion:**
  - Expanded level generator from 9 static patterns to **20 distinct modular encounter patterns** with difficulty gating.
  - Added new encounters: Twin Runners, High Road Bridges, Barricade + Walker, Mutant & Spikes, Recoil Double Vault, Platform Cascade, High Ambush, and The Gauntlet.
  - Implemented algorithmic fairness checks to prevent impossible obstacle combos (strictly forbids consecutive severe pits or barricade walls).
- **Pause Menu Audio Settings:**
  - Added real-time SFX and Music toggle controls directly to the in-game Pause menu overlay.
- **Automated QA Test Suite:**
  - Created 25-point automated QA test runner (`scenes/tools/test_runner.tscn` and `scripts/tools/test_harness.gd`). All 25 test cases passed with 100% success rate.
- **Comprehensive Documentation Suite:**
  - Added `documentation/QA_REPORT.md`, `documentation/PERFORMANCE_REPORT.md`, and `CHANGELOG.md`.

### Changed & Optimized
- **Renderer Migration:** Switched `project.godot` rendering engine from Forward Plus (D3D12) to **GL Compatibility (`gl_compatibility`)**, specifically optimized for Intel N100 / Intel UHD Graphics and Linux Mesa drivers.
- **Chunk Node Optimization:** Refactored terrain chunk generation from individual `Sprite2D` nodes to custom `_draw()` batched texture rendering, slashing node count per chunk from 74 down to 2 nodes (97% reduction) and eliminating GC churn.
- **Reload System Refinement:** Resolved conflict between manual reload (`R`) and auto-reload on empty; ensured atomic reload lock and dry click audio feedback during reload attempts.
- **Recoil Jump Tuning:** Added upward velocity clamping (`-540.0 px/s`) and fall momentum cancellation to ensure snappy, predictable jumps that stay within camera framing.
- **Scene Routing Safeguard:** Implemented deferred scene transitions (`call_deferred("change_scene_to_file", ...)`) in `GameManager` to prevent `remove_child: Parent node is busy` engine warnings.
- **Audio Voice Anti-Spam:** Added 0.045s cooldown per sound name in `AudioManager` to eliminate voice clipping during crowd pellet penetrations.

### Fixed
- Fixed `InputEventMouseMotion` crash in `pause_menu.gd` by switching to `event.is_action_pressed("pause") and not event.is_echo()`.
- Corrected controls documentation in `main_menu.tscn` to reflect discrete 5-directional aiming.
- Preserved V1.0 executable backup (`Cube_LastRun_v1.0_backup.exe`) prior to V1.1 deployment.

---

## [v1.0.0] — 2026-11-13 (Initial Master Delivery)
- Initial release of CUBE: LAST RUN with core running, shooting, recoil jumping, 4 zombie types, rear horde pursuer, and 14 synthesized audio tracks.
