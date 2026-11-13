import sys
import os
import json
import subprocess

sfx_script = r"C:\Users\Lenovo\.gemini\config\skills\godot\scripts\assets\make_sfx.py"

sounds = [
    # Shotgun blast
    {"preset": "explosion", "out": "assets/audio/sfx_shotgun.wav", "volume": 1.0, 
     "params": {"attack": 0.0, "decay": 0.08, "sustain_level": 0.3, "release": 0.18, "punch": 0.5, "noise_level": 0.6, "sub_level": 0.8, "sub_freq_start": 180.0, "sub_freq_end": 35.0}},
    # Recoil jump
    {"preset": "explosion", "out": "assets/audio/sfx_recoil.wav", "volume": 1.0,
     "params": {"attack": 0.0, "decay": 0.12, "sustain_level": 0.4, "release": 0.22, "punch": 0.7, "sub_level": 1.0, "sub_freq_start": 160.0, "sub_freq_end": 30.0}},
    # Dry empty click
    {"preset": "blip", "out": "assets/audio/sfx_empty.wav", "volume": 0.7,
     "params": {"freq_start": 1200.0, "decay": 0.01, "sustain": 0.0, "release": 0.02}},
    # Shell casing eject
    {"preset": "coin", "out": "assets/audio/sfx_shell_eject.wav", "volume": 0.6,
     "params": {"freq_start": 1800.0, "decay": 0.02, "release": 0.06}},
    # Zombie hit
    {"preset": "hurt", "out": "assets/audio/sfx_zombie_hit.wav", "volume": 0.85,
     "params": {"wave": "saw", "freq_start": 220.0, "freq_end": 70.0, "decay": 0.1, "release": 0.15}},
    # Zombie death
    {"preset": "hit", "out": "assets/audio/sfx_zombie_death.wav", "volume": 0.9,
     "params": {"noise_level": 0.5, "decay": 0.06, "release": 0.12}},
]

for s in sounds:
    cmd = [
        sys.executable, sfx_script,
        "--preset", s["preset"],
        "--out", s["out"],
        "--volume", str(s["volume"]),
        "--params", json.dumps(s["params"]),
        "--overwrite"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error generating {s['out']}: {res.stderr}")
    else:
        print(f"Generated {s['out']}")

print("All custom SFX generated!")
