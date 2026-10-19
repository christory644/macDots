#!/usr/bin/env python3
"""Merge macOS keyboard shortcut settings, preserving value types.

Carried from the old Mac's `defaults export`. Two things make this fiddly
enough to be worth a script rather than a line of shell:

1. TYPES. `defaults write … -dict-add 64 '{enabled = 0;}'` writes the STRING
   "0", not the integer 0 or boolean false, because old-style plist syntax has
   no way to say which was meant. macOS reads a string-typed `enabled` as
   nothing useful, so the shortcut silently stays on. The first attempt at
   this did exactly that: every value landed as a string and Cmd+Space kept
   opening Spotlight. plistlib round-trips the real types.

2. MERGE, NOT WRITE. AppleSymbolicHotKeys is a single dictionary holding every
   shortcut on the machine. `defaults write` on it replaces the whole thing,
   silently resetting shortcuts nobody asked to change. This reads the current
   dictionary, updates only the ids below, and writes it back.

Idempotent: exits without writing when everything already matches.
"""
import plistlib
import subprocess
import sys

DOMAIN = "com.apple.symbolichotkeys"

# id: (enabled, parameters or None)
#   64/65  Spotlight + Finder search — off, so Raycast owns Cmd+Space
#   79/81  Move left/right a space   — off, AeroSpace binds these itself
WANTED = {
    "32": (False, [65535, 126, 8650752]),
    "33": (False, [65535, 125, 8650752]),
    "34": (False, None),
    "35": (True, [65535, 125, 8781824]),
    "36": (False, [65535, 103, 8388608]),
    "37": (True, [65535, 103, 8519680]),
    "44": (False, None),
    "45": (False, None),
    "46": (False, None),
    "48": (False, None),
    "49": (False, None),
    "52": (False, [100, 2, 1572864]),
    "64": (False, [32, 49, 1048576]),
    "65": (False, [32, 49, 1572864]),
    "79": (False, [65535, 123, 8650752]),
    "81": (False, [65535, 124, 8650752]),
    "82": (True, [65535, 124, 8781824]),
    "118": (False, [65535, 18, 262144]),
    "190": (False, [113, 12, 8388608]),
}


def current():
    try:
        r = subprocess.run(["/usr/bin/defaults", "export", DOMAIN, "-"],
                           capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"symbolichotkeys: cannot read {DOMAIN}: {exc}", file=sys.stderr)
        raise SystemExit(0)          # never fail activation over a preference
    if r.returncode != 0 or not r.stdout:
        return {}
    try:
        return plistlib.loads(r.stdout)
    except Exception:
        return {}


def main():
    doc = current()
    keys = doc.setdefault("AppleSymbolicHotKeys", {})

    changed = []
    for key, (enabled, params) in WANTED.items():
        entry = {"enabled": enabled}
        if params is not None:
            entry["value"] = {"parameters": params, "type": "standard"}
        if keys.get(key) != entry:
            keys[key] = entry
            changed.append(key)

    if not changed:
        print("symbolichotkeys: already correct")
        return

    try:
        subprocess.run(["/usr/bin/defaults", "import", DOMAIN, "-"],
                       input=plistlib.dumps(doc), timeout=30, check=True)
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"symbolichotkeys: write failed: {exc}", file=sys.stderr)
        raise SystemExit(0)
    print(f"symbolichotkeys: set {len(changed)} ids ({', '.join(changed)})")


if __name__ == "__main__":
    main()
