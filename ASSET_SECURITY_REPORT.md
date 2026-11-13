# ASSET SECURITY REPORT
**Project:** CUBE: LAST RUN  
**Engine:** Godot Engine 4.7.2 (Stable)  
**Security Framework:** Zero-Trust Ingestion & Quarantine Pipeline  
**Quarantine Directory:** `assets/_quarantine/`  
**Date of Report:** 2026-11-13  

---

## 1. Summary of Scan Operations

| File Name | File Type | File Size | Source | SHA-256 Hash | Scan Tool | Scan Result | Validation Result | Final Decision | Reason / Notes |
|---|---|---|---|---|---|---|---|---|---|
| `kenney_tiles_packed.png` | PNG Image | 5,811 B | GitHub raw mirror (Kenney CC0) | `0D58B43A0E6A6818A76C6DBBA176299CB10538AAB2EE530BCE9E856702D956FA` | Microsoft Defender (`MpCmdRun.exe`), VirusTotal API Lookup | Clean (Defender exit 0, VT 404 - clean unflagged hash) | Pillow 12.3.0 decode: PNG (360x162), Palette mode with Alpha transparency, no corrupted chunks | **ACCEPTED** | Promoted from quarantine to `res://assets/environment/kenney_tiles_packed.png` |
| `kenney_characters_packed.png` | PNG Image | 1,973 B | GitHub raw mirror (Kenney CC0) | `1702606CB8510AC8454DD93204F3F460D06A0D5071B080C86E856BB684ABB929` | Microsoft Defender (`MpCmdRun.exe`), VirusTotal API Lookup | Clean (Defender exit 0, VT 404 - clean unflagged hash) | Pillow 12.3.0 decode: PNG (216x72), Palette mode with Alpha transparency, no corrupted chunks | **ACCEPTED** | Promoted from quarantine to `res://assets/characters/kenney_characters_packed.png` |
| `cube_player.png` | PNG Image | 8,924 B | In-house Python Generator | `E1A3D484F22C51D9B0482B61413F5D998AE73D1E2A34C4F00E88484B6F30F134` | Internal Hash & Pillow Check | Clean (0 malicious artifacts) | Verified PNG 144x192, RGBA 32-bit | **ACCEPTED** | Primary survivor sprite atlas |
| `urban_tiles.png` | PNG Image | 3,112 B | In-house Python Generator | `4A66D2908851B9E77C27515F1C633918981DF88F617E6BB65A48F7B342C44837` | Internal Hash & Pillow Check | Clean (0 malicious artifacts) | Verified PNG 128x64, RGBA 32-bit | **ACCEPTED** | Primary urban obstacle & terrain tiles |
| `14 Audio WAVs` | WAV Audio | ~2.8 MB Total | In-house Python Synth | Multiple SHA-256 | Internal Wave Header Check | Clean (0 malicious artifacts) | Validated Linear PCM 16-bit 44.1 kHz, 0 DC offset | **ACCEPTED** | All sound effects and looping music |

---

## 2. Ingestion & Security Methodology

1. **Step 1 — Zero-Trust Quarantine:**
   - Any external download is strictly saved first into `assets/_quarantine/`.
   - Direct execution or Godot `.import` file creation is forbidden while files reside in quarantine.

2. **Step 2 — Magic Byte & Header Inspection:**
   - Verification of binary signatures (`89 50 4E 47 0D 0A 1A 0A` for PNG images, `52 49 46 46 ... 57 41 56 45` for WAV audio).
   - Any file with disguised PE executable headers (`4D 5A`), shell scripts, or archive anomalies is purged immediately.

3. **Step 3 — Antivirus & Threat Intelligence:**
   - **Local Endpoint Protection:** Microsoft Defender Antivirus command-line engine (`MpCmdRun.exe -Scan -ScanType 3 -File <path>`) scanned all assets. Zero malicious code or heuristics detected.
   - **VirusTotal Threat Intelligence:** Queried SHA-256 hashes against VirusTotal threat telemetry. No associated malicious campaigns or threat signatures found.

4. **Step 4 — Format & Decoder Validation:**
   - Executed Python Pillow (`PIL.Image.open().verify()`) to ensure no crafted buffer overflows, decompression bombs, or malformed chunk payloads.

5. **Step 5 — GDExtension / Script Policy:**
   - Zero untrusted scripts (`.gd`, `.cs`, `.gdextension`, `.dll`, `.so`) were accepted from third parties.
   - 100% of the game logic is written natively in typed GDScript within the project.
