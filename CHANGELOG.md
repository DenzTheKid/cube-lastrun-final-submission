# CHANGELOG — CUBE: LAST RUN

## [v1.2.0] — 2026-11-13 (V1.2 Full 360° Continuous Aiming & Ultra-Smooth Shotgun Fix)

### Added
- **True Unrestricted 360-Degree Aiming:**
  - Removed the 5-direction quantization system, angle snapping, and directional sector steps.
  - Implemented continuous 360-degree aiming tracking the mouse cursor in world coordinates (`get_global_mouse_position()`) with zero input lag.
  - Added support for all intermediate angles (0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°, and every angle in between).
- **Dedicated WeaponVisuals Container & Clean Vertical Flipping:**
  - Placed shotgun sprites, muzzle marker, ejection port, and muzzle flash inside a unified `WeaponVisuals` child node.
  - Implemented automatic vertical flipping (`scale.y = -1.0` when aiming into the left hemisphere `aim_direction.x < -0.01`), preventing the weapon from ever appearing awkwardly upside down while maintaining continuous rotation.
- **Continuous 360-Degree Recoil Physics:**
  - Refactored recoil impulse calculation into a continuous vector formula:
    - Downward shots (`aim_direction.y > 0.15`) apply an upward impulse proportional to the vertical angle component (`-aim_direction.y * recoil_jump_strength`).
    - Diagonal downward-forward shots deliver forward vaulting velocity (`+140.0 px/s * aim_direction.x`).
    - Horizontal and backward shots provide standard opposing recoil kicks.
- **Continuous 360-Degree Pellet Spreading:**
  - Buckshot pellets now spawn precisely from the moving barrel tip marker (`muzzle.global_position`) and disperse along the continuous aim vector.
- **360° Automated QA Verification Suite:**
  - Updated 25-point automated QA test runner to verify 360° angular sweeps, backward firing at 180°, downward recoil jumping at 270°, and weapon grip integrity.
- **New Release Executable:**
  - Exported `Cube_LastRun_V1.2.exe` to Downloads (`C:\Users\Lenovo\Downloads\Cube_LastRun_V1.2.exe` and `Cube_LastRun.exe`).
  - Preserved V1.1 as `Cube_LastRun_v1.1_backup.exe`.

---

## [v1.1.0] — 2026-11-13 (V1.1 Complete Audit, Repair & Premium Polish)
- Discrete 5-directional aiming system.
- Trauma-based screen shake on shotgun blasts and hazard damage.
- Procedural generation overhaul: expanded from 9 to 20 modular encounter patterns with difficulty gating and fairness filters.
- Switched rendering to GL Compatibility (`gl_compatibility`) for Intel N100 / Intel UHD Graphics.
- Optimized chunk rendering via custom `_draw()`, reducing node overhead by 97%.
- Atomic reload state machine and 25-point automated QA test runner.

---

## [v1.0.0] — 2026-11-13 (Initial Master Delivery)
- Initial release of CUBE: LAST RUN with core running, shooting, recoil jumping, 4 zombie types, rear horde pursuer, and 14 synthesized audio tracks.
