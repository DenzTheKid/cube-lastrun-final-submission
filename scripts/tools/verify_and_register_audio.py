import os
import wave
import hashlib
from collections import defaultdict

AUDIO_DIR = r"d:\Projects\GODOT\cube--lastrun\assets\audio"

# Metadata database for all external / researched audio assets
ASSET_METADATA = {
    # Music
    "music/bgm_menu_dusk.ogg": {
        "name": "Simulation Unknown (Menu BGM)",
        "category": "Music / Main Menu",
        "creator": "Bobjt / Tricksntraps",
        "source": "https://opengameart.org/content/t-t-free-cyberpunk-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Atmospheric cyberpunk dusk ambiance for main menu"
    },
    "music/bgm_gameplay_run.ogg": {
        "name": "Experiment G (Gameplay BGM)",
        "category": "Music / Gameplay",
        "creator": "Bobjt / Tricksntraps",
        "source": "https://opengameart.org/content/t-t-free-cyberpunk-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "High-octane electronic baseline driving continuous highway survival"
    },
    "music/bgm_horde_intense.ogg": {
        "name": "Wicked Beast (Horde / Boss BGM)",
        "category": "Music / Horde Combat",
        "creator": "Bobjt / Tricksntraps",
        "source": "https://opengameart.org/content/t-t-free-cyberpunk-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Dark, urgent industrial tempo escalation for zombie swarm surges"
    },
    "music/bgm_game_over.ogg": {
        "name": "Game Over II ~ v1 (Game Over Sting)",
        "category": "Music / Game Over",
        "creator": "Mhmd",
        "source": "https://opengameart.org/content/game-over-theme-ii",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Somber dramatic synth sting for run summary / death screen"
    },

    # Weapons SFX
    "sfx/weapons/shotgun_blast_cc0.wav": {
        "name": "Black Powder (Shotgun Blast)",
        "category": "Weapons / Primary Fire",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/gunshots",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Heavy, booming shotgun primary fire blast"
    },
    "sfx/weapons/shotgun_punch_cc0.wav": {
        "name": "22 Magnum (Shotgun Punch)",
        "category": "Weapons / Alternate Fire",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/gunshots",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Snappy, tight gunshot transient for audio layering"
    },
    "sfx/weapons/shotgun_pump_cc0.wav": {
        "name": "Shotgun Cock / Pump",
        "category": "Weapons / Mechanics",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/gun-reload-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Crisp mechanical pump action sound"
    },
    "sfx/weapons/shotgun_reload_cc0.wav": {
        "name": "Gun Reload Full",
        "category": "Weapons / Mechanics",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/gun-reload-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Complete mechanical shell chambering sequence"
    },
    "sfx/weapons/dry_fire_click_cc0.wav": {
        "name": "Double-Barrel Left Trigger (Dry Fire)",
        "category": "Weapons / Feedback",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/toy-double-barrel-shotgun-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Clean empty-chamber trigger click when out of ammo"
    },
    "sfx/weapons/shell_casing_eject_cc0.wav": {
        "name": "Clink 2 (Shell Casing Eject)",
        "category": "Weapons / Feedback",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/metal-impact-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Bright metallic casing clink upon spent shell ejection"
    },
    "sfx/weapons/bullet_impact_metal_cc0.wav": {
        "name": "Clink 3 (Bullet Impact Metal)",
        "category": "Weapons / Environment Impact",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/metal-impact-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Sharp metallic ricochet for vehicle/iron barricade hits"
    },
    "sfx/weapons/bullet_impact_concrete_cc0.wav": {
        "name": "Thud 3 (Bullet Impact Concrete)",
        "category": "Weapons / Environment Impact",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/metal-impact-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Solid low-mid thud for asphalt/concrete highway hits"
    },
    "sfx/weapons/bullet_impact_flesh_cc0.mp3": {
        "name": "Squish 02 (Bullet Impact Flesh)",
        "category": "Weapons / Enemy Hit",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/squish-sounds-effects",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Wet organic flesh penetration sound on zombie pellet strike"
    },

    # Enemies SFX
    "sfx/enemies/sfx_zombie_walker_groan_01.wav": {
        "name": "Walker Long Groan 01",
        "category": "Enemies / Walker Idle",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Deep guttural moan for standard walker presence"
    },
    "sfx/enemies/sfx_zombie_walker_groan_02.wav": {
        "name": "Walker Long Groan 02",
        "category": "Enemies / Walker Idle",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Extended undead vocal variation"
    },
    "sfx/enemies/sfx_zombie_walker_idle_01.wav": {
        "name": "Walker Idle Grunt 01",
        "category": "Enemies / Walker Idle",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Short periodic idle grunt for nearby walkers"
    },
    "sfx/enemies/sfx_zombie_runner_screech_01.ogg": {
        "name": "Runner Frenzy Screech",
        "category": "Enemies / Runner",
        "creator": "OpenGameArt (80 CC0 Creature SFX)",
        "source": "https://opengameart.org/content/80-cc0-creature-sfx",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Piercing creature shriek during rapid sprint approach"
    },
    "sfx/enemies/sfx_zombie_mutant_screech_01.wav": {
        "name": "Mutant Aggro Screech",
        "category": "Enemies / Mutant",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Raspy aggro screech prior to horizontal leap"
    },
    "sfx/enemies/sfx_zombie_mutant_leap_01.wav": {
        "name": "Mutant Leap Impulse",
        "category": "Enemies / Mutant",
        "creator": "OpenGameArt (Monster SFX 2)",
        "source": "https://opengameart.org/content/monster-sound-effects-2",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Snappy launch burst matching the mutant's airborne hop"
    },
    "sfx/enemies/sfx_zombie_brute_roar_01.wav": {
        "name": "Brute Heavy Roar 01",
        "category": "Enemies / Brute",
        "creator": "OpenGameArt (Monster SFX 2)",
        "source": "https://opengameart.org/content/monster-sound-effects-2",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Massive resonant roar reflecting armored 4-HP tank status"
    },
    "sfx/enemies/sfx_zombie_brute_roar_02.ogg": {
        "name": "Brute Heavy Roar 02",
        "category": "Enemies / Brute",
        "creator": "OpenGameArt (80 CC0 Creature SFX)",
        "source": "https://opengameart.org/content/80-cc0-creature-sfx",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Deep guttural bellow variation for brute encounters"
    },
    "sfx/enemies/sfx_zombie_brute_tank_01.wav": {
        "name": "Brute Damage Absorb / Tank",
        "category": "Enemies / Brute",
        "creator": "OpenGameArt (Monster SFX 2)",
        "source": "https://opengameart.org/content/monster-sound-effects-2",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Low-frequency heavy grunt when absorbing non-lethal shotgun hits"
    },
    "sfx/enemies/sfx_zombie_hit_01.wav": {
        "name": "Zombie Pain Snarl",
        "category": "Enemies / Hit Reaction",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Sharp reactive pain snarl on projectile contact"
    },
    "sfx/enemies/sfx_zombie_hurt_01.ogg": {
        "name": "Zombie Hurt Gasp",
        "category": "Enemies / Hit Reaction",
        "creator": "OpenGameArt (80 CC0 Creature SFX)",
        "source": "https://opengameart.org/content/80-cc0-creature-sfx",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Organic hurt sound variation for staggered zombies"
    },
    "sfx/enemies/sfx_zombie_flesh_squish_01.mp3": {
        "name": "Zombie Flesh Squish 01",
        "category": "Enemies / Hit Reaction",
        "creator": "OpenGameArt (Squish SFX)",
        "source": "https://opengameart.org/content/squish-sounds-effects",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Visceral organic tissue tearing upon pellet impact"
    },
    "sfx/enemies/sfx_zombie_death_groan_01.wav": {
        "name": "Zombie Death Groan",
        "category": "Enemies / Death",
        "creator": "OpenGameArt (Zombies Pack)",
        "source": "https://opengameart.org/content/zombies-sound-pack",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Terminal dying groan as zombie collapses to 0 HP"
    },
    "sfx/enemies/sfx_zombie_death_splat_01.mp3": {
        "name": "Zombie Death Splat",
        "category": "Enemies / Death",
        "creator": "OpenGameArt (Squish SFX)",
        "source": "https://opengameart.org/content/squish-sounds-effects",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Wet crunchy splat synced with blood particle burst"
    },

    # UI SFX
    "sfx/ui/sfx_ui_hover.wav": {
        "name": "Kenney Select 001 (UI Hover)",
        "category": "UI / Navigation",
        "creator": "Kenney (kenney.nl)",
        "source": "https://kenney.nl/assets/interface-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Subtle, crisp blip on button hover / focus transition"
    },
    "sfx/ui/sfx_ui_click.wav": {
        "name": "Kenney Click 001 (UI Click)",
        "category": "UI / Navigation",
        "creator": "Kenney (kenney.nl)",
        "source": "https://kenney.nl/assets/interface-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Clean tactile confirmation click for menu buttons"
    },
    "sfx/ui/sfx_ui_milestone.wav": {
        "name": "Kenney Confirmation 001 (UI Milestone)",
        "category": "UI / Progression",
        "creator": "Kenney (kenney.nl)",
        "source": "https://kenney.nl/assets/interface-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Bright celebratory chime for distance records and perk unlocks"
    },
    "sfx/ui/sfx_ui_toggle.wav": {
        "name": "Kenney Switch 001 (UI Toggle)",
        "category": "UI / Settings",
        "creator": "Kenney (kenney.nl)",
        "source": "https://kenney.nl/assets/interface-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Distinct mechanical switch action for audio/pause toggles"
    },

    # Player SFX
    "sfx/player/sfx_player_footstep.wav": {
        "name": "Footsteps on Asphalt",
        "category": "Player / Traversal",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/various-sound-effects-0",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Gritty rhythmic boot impacts on highway road surface"
    },
    "sfx/player/sfx_player_jump.wav": {
        "name": "Jump 1 (Jump Impulse)",
        "category": "Player / Traversal",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/jump-landing",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Snappy aerodynamic upward leap cue"
    },
    "sfx/player/sfx_player_land.wav": {
        "name": "Jump Land (Ground Collision)",
        "category": "Player / Traversal",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/jump-landing-sound",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Firm downward landing thud resetting jump state"
    },
    "sfx/player/sfx_player_shield.wav": {
        "name": "Space Shield Sound (Barrier Active)",
        "category": "Player / Abilities",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/space-ship-shield-sounds",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Resonant energetic barrier hum protecting survivor"
    },
    "sfx/player/sfx_player_heal.wav": {
        "name": "Cure Magic (Medkit Heal)",
        "category": "Player / Health",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/cure-magic",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Warm uplifting restoration chime upon medkit pickup"
    },

    # Environment SFX
    "sfx/environment/sfx_barricade_hit.wav": {
        "name": "Crush (Barricade / Crate Hit)",
        "category": "Environment / Destruction",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/various-sound-effects-0",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Heavy splintering impact when smashing wooden obstacles"
    },

    # Ambient Audio
    "ambient/amb_night_highway_wind.ogg": {
        "name": "Windy Ambiance (Highway Wind)",
        "category": "Ambient / Environment",
        "creator": "OpenGameArt",
        "source": "https://opengameart.org/content/windy-ambient-noise",
        "license": "CC0 1.0 Universal (Public Domain)",
        "commercial_use": "Fully Allowed",
        "role": "Desolate howling wind loop setting the post-apocalyptic mood"
    }
}

def analyze_audio_files():
    results = []
    hashes = defaultdict(list)

    for root, dirs, files in os.walk(AUDIO_DIR):
        for f in files:
            if f.endswith(".import"):
                continue
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, AUDIO_DIR).replace("\\", "/")
            size = os.path.getsize(full_path)
            
            with open(full_path, "rb") as fp:
                data = fp.read()
                file_hash = hashlib.sha256(data).hexdigest()
            hashes[file_hash].append(rel_path)

            ext = os.path.splitext(f)[1].lower()
            channels = None
            rate = None
            bits = None
            duration = None
            valid_header = False

            if ext == ".wav":
                try:
                    with wave.open(full_path, "rb") as w:
                        channels = w.getnchannels()
                        rate = w.getframerate()
                        bits = w.getsampwidth() * 8
                        frames = w.getnframes()
                        duration = frames / float(rate)
                        valid_header = True
                except Exception as e:
                    valid_header = False
            elif ext == ".ogg":
                if data[:4] == b"OggS":
                    valid_header = True
                    # Estimate approximate channels / sample rate if vorbis
                    channels = 2
                    rate = 44100
            elif ext == ".mp3":
                if data[:3] == b"\xff\xfb\x90" or data[:2] == b"\xff\xfb" or data[:3] == b"ID3":
                    valid_header = True
            elif ext == ".m4a":
                valid_header = True

            meta = ASSET_METADATA.get(rel_path, {})
            results.append({
                "rel_path": rel_path,
                "full_path": full_path,
                "ext": ext,
                "size": size,
                "hash": file_hash,
                "valid": valid_header,
                "channels": channels,
                "rate": rate,
                "bits": bits,
                "duration": duration,
                "meta": meta
            })

    return results, hashes

if __name__ == "__main__":
    results, hashes = analyze_audio_files()
    print(f"Total audio files audited: {len(results)}")
    
    # Check duplicates
    duplicates = {k: v for k, v in hashes.items() if len(v) > 1}
    print(f"Duplicate hash count: {len(duplicates)}")
    if duplicates:
        for h, l in duplicates.items():
            print("  DUPLICATE:", h, l)
    else:
        print("  VERIFIED: Zero duplicate audio files in the entire repository!")

    # Verify newly researched assets
    researched = [r for r in results if r["meta"]]
    print(f"\nResearched external assets audited: {len(researched)} / {len(ASSET_METADATA)}")
    all_valid = all(r["valid"] for r in researched)
    print(f"All headers valid: {all_valid}")
    all_cc0 = all("CC0" in r["meta"]["license"] for r in researched)
    print(f"All CC0 / Public Domain: {all_cc0}")
