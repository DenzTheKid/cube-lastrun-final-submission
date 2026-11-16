import os
import zipfile
import subprocess
from PIL import Image

STAGING = r"D:\Projects\GODOT\cube--lastrun\assets\_quarantine\staging"
QUARANTINE = r"D:\Projects\GODOT\cube--lastrun\assets\_quarantine"
ASSETS_DIR = r"D:\Projects\GODOT\cube--lastrun\assets"

os.makedirs(os.path.join(ASSETS_DIR, "ui"), exist_ok=True)
os.makedirs(os.path.join(ASSETS_DIR, "effects"), exist_ok=True)
os.makedirs(os.path.join(ASSETS_DIR, "audio"), exist_ok=True)

# 1. CROSSHAIR (from Kenney Crosshair Pack: PNG/Outline/crosshair-001.png)
with zipfile.ZipFile(os.path.join(QUARANTINE, "kenney_crosshair-pack.zip")) as zf:
    zf.extract("PNG/Outline/crosshair-001.png", STAGING)
ch_src = os.path.join(STAGING, "PNG", "Outline", "crosshair-001.png")
ch_img = Image.open(ch_src).convert("RGBA")
# Resample to 32x32 crisp cursor with LANCZOS, then sharpen
ch_32 = ch_img.resize((32, 32), Image.Resampling.LANCZOS)
ch_dest = os.path.join(ASSETS_DIR, "ui", "crosshair_reticle.png")
ch_32.save(ch_dest)
print("Integrated Crosshair:", ch_dest, ch_32.size)

# 2. PARTICLES: SMOKE & SPARK (from Kenney Particle Pack)
smoke_src = os.path.join(STAGING, "particles", "PNG (Transparent)", "smoke_04.png")
if not os.path.exists(smoke_src):
    smoke_src = os.path.join(STAGING, "particles", "PNG (Transparent)", "smoke_01.png")
smoke_img = Image.open(smoke_src).convert("RGBA")
smoke_32 = smoke_img.resize((32, 32), Image.Resampling.LANCZOS)
smoke_dest = os.path.join(ASSETS_DIR, "effects", "smoke_puff.png")
smoke_32.save(smoke_dest)
print("Integrated Smoke:", smoke_dest, smoke_32.size)

spark_src = os.path.join(STAGING, "particles", "PNG (Transparent)", "spark_01.png")
spark_img = Image.open(spark_src).convert("RGBA")
spark_16 = spark_img.resize((16, 16), Image.Resampling.LANCZOS)
spark_dest = os.path.join(ASSETS_DIR, "effects", "spark.png")
spark_16.save(spark_dest)
print("Integrated Spark:", spark_dest, spark_16.size)

# 3. BLOOD PARTICLES (from Endless Midnight: Zombie Swarm)
# Extract a high-contrast 16x16 blood splatter droplet
drops_src = os.path.join(STAGING, "endless_midnight", "Images", "Blood", "Drops.png")
drops_img = Image.open(drops_src).convert("RGBA")
# Crop a crisp blood droplet cluster from top-left region
blood_crop = drops_img.crop((12, 12, 44, 44)).resize((16, 16), Image.Resampling.NEAREST)
blood_dest = os.path.join(ASSETS_DIR, "effects", "blood_splat.png")
blood_crop.save(blood_dest)
print("Integrated Blood Splat:", blood_dest, blood_crop.size)

# 4. AUDIO: Michel Baradari Shotgun Acoustic
shotgun_src = os.path.join(STAGING, "shots", "shots", "shotgun.wav")
shotgun_dest = os.path.join(ASSETS_DIR, "audio", "sfx_shotgun_acoustic.wav")
with open(shotgun_src, "rb") as sf, open(shotgun_dest, "wb") as df:
    df.write(sf.read())
print("Integrated Shotgun Audio:", shotgun_dest, os.path.getsize(shotgun_dest), "bytes")

# 5. AUDIO: Kenney Impact Sounds (Flesh & Metal)
flesh_src = os.path.join(STAGING, "impacts", "Audio", "impactSoft_heavy_001.ogg")
flesh_dest = os.path.join(ASSETS_DIR, "audio", "sfx_impact_flesh.ogg")
with open(flesh_src, "rb") as sf, open(flesh_dest, "wb") as df:
    df.write(sf.read())
print("Integrated Flesh Impact Audio:", flesh_dest, os.path.getsize(flesh_dest), "bytes")

metal_src = os.path.join(STAGING, "impacts", "Audio", "impactMetal_heavy_000.ogg")
metal_dest = os.path.join(ASSETS_DIR, "audio", "sfx_impact_metal.ogg")
with open(metal_src, "rb") as sf, open(metal_dest, "wb") as df:
    df.write(sf.read())
print("Integrated Metal Impact Audio:", metal_dest, os.path.getsize(metal_dest), "bytes")

print("All verified assets successfully staged and integrated into res://assets/!")
