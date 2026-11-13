# CUBE: LAST RUN (V1.2 — 360° AIMING & RECOIL UPGRADE)
**Tagline: Run. Shoot. Survive. Don't Stop.**

A fast-paced, high-octane 2D endless side-scrolling runner built in Godot Engine 4.7.2 featuring a cube survivor equipped with a double-barrel shotgun fleeing a continuous zombie horde in an apocalyptic wasteland.

---

## Quick Start (How to Run)

### Option 1: Standalone Executable (No Godot Required)
The release executable has all game assets, scripts, and audio embedded directly into a single file:
- **Latest V1.2 Build:** [`C:\Users\Lenovo\Downloads\Cube_LastRun_V1.2.exe`](file:///C:/Users/Lenovo/Downloads/Cube_LastRun_V1.2.exe)
- **Standard Name:** [`C:\Users\Lenovo\Downloads\Cube_LastRun.exe`](file:///C:/Users/Lenovo/Downloads/Cube_LastRun.exe)
- **Subfolder:** [`C:\Users\Lenovo\Downloads\CubeLastRun\Cube_LastRun_V1.2.exe`](file:///C:/Users/Lenovo/Downloads/CubeLastRun/Cube_LastRun_V1.2.exe)
- **Root C:\Downloads:** [`C:\Downloads\Cube_LastRun_V1.2.exe`](file:///C:/Downloads/Cube_LastRun_V1.2.exe)
- *Simply double-click `Cube_LastRun_V1.2.exe` to play immediately!*

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
- **Aim (Full 360° Continuous):** `Mouse Cursor` (Full 360° world tracking) or `Gamepad Right Stick / Arrow Keys`
- **Shoot:** `Left Mouse Button` / `X` (Double-Barrel Shotgun)
- **Shotgun Recoil Jump:** Aim **DOWNWARD** at any angle and shoot to vault into the air!
- **Reload:** `R` (Carries 2 shells; auto-reloads when dry)
- **Pause:** `Escape` / `P` (Includes Resume, Restart, and Audio Toggles)

---

## V1.2 Key Upgrades & Highlights
1. **True Unrestricted 360° Aiming:** Smooth, continuous mouse tracking in all directions without angle quantization, sector snapping, or rotation jitter.
2. **Dedicated WeaponVisuals & Vertical Flipping:** Shotgun flips cleanly when aiming backward/left (`scale.y = -1.0`), preventing upside-down weapon rendering while keeping 100% continuous angular accuracy.
3. **Continuous 360° Recoil Physics:** Firing downward at any angle applies an upward impulse proportional to angle; diagonal downward-forward shots deliver vault momentum; backward shots push the player forward away from the horde.
4. **Muzzle Alignment & Pellet Trajectory:** Pellets spawn directly from the moving barrel tip and disperse along the exact aim direction.
5. **20 Modular Encounter Patterns:** Progressive difficulty with strict fairness validation preventing impossible hazard bottlenecks.
6. **GL Compatibility Renderer:** Optimized for Intel N100 / Intel UHD Graphics (> 100 FPS measured).
7. **25-Point Automated QA Suite:** 100% pass rate.

---

## Documentation Links
- [Changelog (V1.2.0)](file:///d:/Projects/GODOT/cube--lastrun/CHANGELOG.md)
- [QA Verification & Test Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/QA_REPORT.md)
- [Performance & Profiling Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/PERFORMANCE_REPORT.md)
- [Gameplay & Controls Guide](file:///d:/Projects/GODOT/cube--lastrun/documentation/GAMEPLAY_AND_CONTROLS.md)
- [Technical Architecture](file:///d:/Projects/GODOT/cube--lastrun/documentation/ARCHITECTURE.md)
- [Asset Sources & Licensing Register](file:///d:/Projects/GODOT/cube--lastrun/ASSET_SOURCES.md)
- [Asset Security & Validation Report](file:///d:/Projects/GODOT/cube--lastrun/ASSET_SECURITY_REPORT.md)
- [Asset Research & Verification Report](file:///d:/Projects/GODOT/cube--lastrun/documentation/ASSET_RESEARCH_REPORT.md)
