#!/usr/bin/env python3
"""Re-key Claude Code per-project entries from the old home path to the new one.

Claude stores per-project state in .claude.json under a `projects` map keyed by
ABSOLUTE PATH. After the username change those keys still read
/Users/christopherstory/..., so nothing matches under the new home. The failure
is silent and specific: the workspace reads as untrusted ("Ignoring N
permissions.allow entries ... this workspace has not been trusted") and any
local-scoped MCP server stored on that entry never loads. ~/repos/agentOS lost
`agentos-local` exactly this way.

DO NOT run this against a profile that has a live session. Claude rewrites
.claude.json on exit and will clobber the edit — or worse, write back its
in-memory copy of the old key. Quit first; the script refuses by default if it
can see a matching process.

Usage:
  rekey-claude-projects.py <file> [--apply] [--force]
"""
import json, os, shutil, subprocess, sys
from datetime import date

OLD = "/Users/christopherstory"
NEW = os.path.expanduser("~")
# Fields that represent a decision made about a folder, which must survive a
# merge. Everything else is runtime state and the newer entry's copy wins.
UNION_KEYS = ["allowedTools", "enabledMcpjsonServers", "disabledMcpjsonServers"]
DICT_UNION = ["mcpServers"]


def live_session(path: str) -> bool:
    """True if something looks like it is holding this profile open."""
    prof = os.path.basename(os.path.dirname(path)) or "~"
    try:
        out = subprocess.run(["pgrep", "-fl", "claude"], capture_output=True, text=True).stdout
    except Exception:
        return False
    if prof.startswith(".claude") and prof in out:
        return True
    # the default profile's file is ~/.claude.json, owned by Desktop
    if path == os.path.expanduser("~/.claude.json") and "Claude.app/Contents/MacOS/Claude" in out:
        return True
    return False


def merge(old: dict, new: dict) -> tuple[dict, list[str]]:
    """New entry wins on runtime state; decisions are unioned in from old."""
    out, notes = dict(new), []
    if old.get("hasTrustDialogAccepted") and not new.get("hasTrustDialogAccepted"):
        out["hasTrustDialogAccepted"] = True
        notes.append("trust")
    for k in UNION_KEYS:
        a, b = old.get(k) or [], new.get(k) or []
        if a:
            merged = list(dict.fromkeys(list(b) + list(a)))
            if merged != list(b):
                out[k] = merged
                notes.append(f"{k}+{len(merged) - len(b)}")
    for k in DICT_UNION:
        a, b = old.get(k) or {}, new.get(k) or {}
        if a:
            merged = {**a, **b}          # new wins on a name collision
            if merged != b:
                out[k] = merged
                notes.append(f"{k}+{len(merged) - len(b)}")
    return out, notes


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__); return 2
    path = os.path.expanduser(sys.argv[1])
    apply_ = "--apply" in sys.argv
    force = "--force" in sys.argv

    if not os.path.isfile(path):
        print(f"no such file: {path}"); return 1
    if live_session(path) and not force:
        print(f"REFUSING: a session appears to be using {path}.")
        print("Claude rewrites this file on exit and would clobber the edit.")
        print("Quit it first, or pass --force if you are certain.")
        return 1

    with open(path) as fh:
        data = json.load(fh)
    projects = data.get("projects") or {}
    old_keys = [k for k in projects if k.startswith(OLD)]
    if not old_keys:
        print(f"{path}: nothing to do"); return 0

    moved = merged = 0
    for k in sorted(old_keys):
        nk = NEW + k[len(OLD):]
        if nk in projects:
            projects[nk], notes = merge(projects[k], projects[nk])
            del projects[k]
            merged += 1
            print(f"  MERGE {k.replace(NEW,'~')}\n     -> {nk.replace(NEW,'~')}  [{', '.join(notes) or 'no decisions to carry'}]")
        else:
            projects[nk] = projects.pop(k)
            moved += 1
            e = projects[nk]
            extra = []
            if e.get("hasTrustDialogAccepted"): extra.append("trusted")
            if e.get("mcpServers"): extra.append("mcp:" + ",".join(e["mcpServers"]))
            print(f"  move  {nk.replace(NEW,'~')}  {' '.join(extra)}")

    print(f"\n{os.path.basename(path)}: moved {moved}, merged {merged}, "
          f"{len(projects)} projects total")
    if not apply_:
        print("(dry run — re-run with --apply)")
        return 0

    bak = f"{path}.pre-rekey-{date.today().isoformat()}"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
        print(f"backup: {bak}")
    data["projects"] = projects
    tmp = path + ".tmp-rekey"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=2)
    json.load(open(tmp))            # parse it back before trusting it
    os.replace(tmp, path)
    print("written and re-parsed OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
