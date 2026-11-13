import os
import re

for root, _, files in os.walk("scenes"):
    for f in files:
        if f.endswith(".tscn"):
            p = os.path.join(root, f)
            with open(p, "r", encoding="utf-8") as fh:
                content = fh.read()
            cleaned = re.sub(r' uid="uid://[^"]*"', "", content)
            if cleaned != content:
                with open(p, "w", encoding="utf-8") as fh:
                    fh.write(cleaned)
                print("Cleaned UIDs in", p)
print("UID cleanup complete!")
