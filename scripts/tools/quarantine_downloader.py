import os
import sys
import json
import hashlib
import urllib.request
import subprocess
import zipfile

QUARANTINE_DIR = r"D:\Projects\GODOT\cube--lastrun\assets\_quarantine"
os.makedirs(QUARANTINE_DIR, exist_ok=True)

DEFENDER_CLI = r"C:\Program Files\Windows Defender\MpCmdRun.exe"

def get_kenney_signed_url(asset_slug):
    hex_id = f"assets/{asset_slug}".encode().hex()
    req = urllib.request.Request(
        f"https://kenney.nl/download-link/{hex_id}",
        headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            "Referer": f"https://kenney.nl/assets/{asset_slug}"
        }
    )
    res = urllib.request.urlopen(req, timeout=15)
    data = json.loads(res.read().decode())
    return data["url"]

def calc_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def scan_defender(filepath):
    if not os.path.exists(DEFENDER_CLI):
        return {"status": "UNAVAILABLE", "output": "MpCmdRun.exe not found"}
    cmd = [DEFENDER_CLI, "-Scan", "-ScanType", "3", "-File", filepath, "-DisableRemediation"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    is_clean = res.returncode == 0
    return {
        "status": "CLEAN" if is_clean else f"EXIT_{res.returncode}",
        "output": res.stdout.strip() or res.stderr.strip()
    }

candidates = [
    {
        "id": "kenney_crosshair_pack",
        "name": "Kenney Crosshair Pack",
        "url_getter": lambda: get_kenney_signed_url("crosshair-pack"),
        "filename": "kenney_crosshair-pack.zip"
    },
    {
        "id": "kenney_particle_pack",
        "name": "Kenney Particle Pack",
        "url_getter": lambda: get_kenney_signed_url("particle-pack"),
        "filename": "kenney_particle-pack.zip"
    },
    {
        "id": "oga_endless_midnight",
        "name": "Endless Midnight Zombie Swarm Assets",
        "url_getter": lambda: "https://opengameart.org/sites/default/files/Images.zip",
        "filename": "oga_endless_midnight_images.zip"
    },
    {
        "id": "kenney_impact_sounds",
        "name": "Kenney Impact Sounds",
        "url_getter": lambda: get_kenney_signed_url("impact-sounds"),
        "filename": "kenney_impact-sounds.zip"
    },
    {
        "id": "oga_michel_baradari_shots",
        "name": "Shotgun Shots by Michel Baradari",
        "url_getter": lambda: "https://opengameart.org/sites/default/files/shots.7z",
        "filename": "oga_michel_baradari_shots.7z"
    }
]

audit_results = []

for c in candidates:
    print(f"\n==========================================")
    print(f"Processing: {c['name']}")
    dest_path = os.path.join(QUARANTINE_DIR, c['filename'])
    
    # 1. Download
    try:
        url = c["url_getter"]()
        print(f"Downloading from: {url[:70]}...")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp, open(dest_path, "wb") as out_f:
            while chunk := resp.read(65536):
                out_f.write(chunk)
        size = os.path.getsize(dest_path)
        print(f"Downloaded successfully: {size} bytes")
    except Exception as e:
        print(f"Download failed: {e}")
        audit_results.append({"name": c["name"], "status": "DOWNLOAD_FAILED", "error": str(e)})
        continue

    # 2. SHA-256
    sha256 = calc_sha256(dest_path)
    print(f"SHA-256: {sha256}")

    # 3. Archive Inspection
    entries = []
    extensions = set()
    suspicious_files = []
    
    if dest_path.endswith(".zip"):
        try:
            with zipfile.ZipFile(dest_path, "r") as zf:
                for zinfo in zf.infolist():
                    name = zinfo.filename
                    entries.append(name)
                    ext = os.path.splitext(name)[1].lower()
                    if ext:
                        extensions.add(ext)
                    if ext in [".exe", ".bat", ".cmd", ".ps1", ".scr", ".dll", ".vbs", ".msi", ".jar"]:
                        suspicious_files.append(name)
                    if ".." in name or name.startswith("/") or name.startswith("\\"):
                        suspicious_files.append(f"PATH_TRAVERSAL:{name}")
        except Exception as e:
            print(f"ZIP inspection error: {e}")
    elif dest_path.endswith(".7z"):
        try:
            res = subprocess.run(["tar", "-tf", dest_path], capture_output=True, text=True)
            for line in res.stdout.splitlines():
                name = line.strip()
                if not name:
                    continue
                entries.append(name)
                ext = os.path.splitext(name)[1].lower()
                if ext:
                    extensions.add(ext)
                if ext in [".exe", ".bat", ".cmd", ".ps1", ".scr", ".dll", ".vbs", ".msi", ".jar"]:
                    suspicious_files.append(name)
                if ".." in name or name.startswith("/") or name.startswith("\\"):
                    suspicious_files.append(f"PATH_TRAVERSAL:{name}")
        except Exception as e:
            print(f"7Z inspection error: {e}")

    print(f"Total archive entries: {len(entries)}")
    print(f"Found extensions: {sorted(list(extensions))}")
    print(f"Suspicious files detected: {len(suspicious_files)}")

    # 4. Microsoft Defender Scan
    av_res = scan_defender(dest_path)
    print(f"Defender Status: {av_res['status']}")

    audit_results.append({
        "id": c["id"],
        "name": c["name"],
        "filename": c["filename"],
        "size_bytes": size,
        "sha256": sha256,
        "total_files": len(entries),
        "extensions": sorted(list(extensions)),
        "suspicious_files": suspicious_files,
        "defender_status": av_res["status"],
        "is_safe": len(suspicious_files) == 0 and av_res["status"] == "CLEAN"
    })

report_path = os.path.join(QUARANTINE_DIR, "quarantine_audit_summary.json")
with open(report_path, "w") as f:
    json.dump(audit_results, f, indent=2)

print(f"\nAudit complete. Results saved to {report_path}")
