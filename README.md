# CUBE: LAST RUN (V1.1)
**Tagline: Run. Shoot. Survive. Don't Stop.**

A high-octane 2D endless side-scrolling runner built in Godot Engine 4.7.2 featuring a cube survivor equipped with a double-barrel shotgun fleeing a continuous zombie horde in an apocalyptic wasteland.

---

## Quick Start (How to Run)

### Option 1: Standalone Executable (No Godot Required)
The release executable has all game assets, scripts, and audio embedded directly into a single file:
- **Location:** [`C:\Users\Lenovo\Downloads\Cube_LastRun.exe`](file:///C:/Users/Lenovo/Downloads/Cube_LastRun.exe)
- **Subfolder:** [`C:\Users\Lenovo\Downloads\CubeLastRun\Cube_LastRun.exe`](file:///C:/Users/Lenovo/Downloads/CubeLastRun/Cube_LastRun.exe)
- **Root C:\Downloads:** [`C:\Downloads\Cube_LastRun.exe`](file:///C:/Downloads/Cube_LastRun.exe)
- *Simply double-click `Cube_LastRun.exe` to play immediately!*

### Option 2: Godot Editor
1. Launch Godot Engine 4.7.x.
2. Select **Import** and open `D:\Projects\GODOT\cube--lastrun\project.godot`.
3. Press **F5** to start from the Main Menu.

### Option 3: Command Line (PowerShell)
```powershell
godot --path "D:\Projects\GODOT\cube--lastrun"
```

---

## Controls
- **Jump:** `Spacebar` / `W` / `Up Arrow`
- **Aim (5 Discrete Poses):** `Mouse Cursor` (Quantized forward hemisphere) or `WASD / Arrow Keys`
- **Shoot:** `Left Mouse Button` / `X` (Double-Barrel Shotgun)
- **Shotgun Recoil Jump:** Aim **DOWNWARD** or **DIAG-DOWN** and shoot to vault high into the air!
- **Reload:** `R` (Carries 2 shells; auto-reloads when dry)
- **Pause:** `Escape` / `P` (Includes Resume, Restart, and Audio Toggles)

---

## V1.1 Key Upgrades & Highlights
1. **Discrete 5-Directional Aiming:** Snappy forward, up, diag-up, down, and diag-down aiming replacing jittery 360° rotation.
2. **Shotgun Recoil Jumps & Vaults:** Pure vertical high jumps and diagonal forward vaults with fall-cancellation for clutch pit recoveries.
3. **Overhauled Procedural Generator:** 20 distinct modular encounter patterns with difficulty gating and strict fairness validation (no consecutive lethal pits or barricades).
4. **Optimized Batched Chunk Rendering:** Custom `_draw()` rendering reduced node count per chunk from 74 down to 2 nodes (97% reduction), eliminating GC stutter.
5. **GL Compatibility Renderer:** Optimized for Intel N100 / Intel UHD Graphics and Linux Mesa drivers (> 100 FPS measured).
6. **25-Point Automated QA Test Suite:** 100% pass rate across mechanics, physics, enemies, and UI.

---

## Documentation Links
- [QA Verification & Test Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/QA_REPORT.md)
- [Performance & Profiling Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/PERFORMANCE_REPORT.md)
- [Changelog (V1.1.0)](file:///d:/Projects/GODOT/cube--lastrun/CHANGELOG.md)
- [Gameplay & Controls Guide](file:///d:/Projects/GODOT/cube--lastrun/documentation/GAMEPLAY_AND_CONTROLS.md)
- [Technical Architecture](file:///d:/Projects/GODOT/cube--lastrun/documentation/ARCHITECTURE.md)
- [Asset Sources & Licensing Register](file:///d:/Projects/GODOT/cube--lastrun/ASSET_SOURCES.md)
- [Asset Security & Validation Report](file:///d:/Projects/GODOT/cube--lastrun/ASSET_SECURITY_REPORT.md)
- [Asset Research & Verification Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/ASSET_RESEARCH_REPORT.md)
