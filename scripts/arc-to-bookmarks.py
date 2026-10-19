#!/usr/bin/env python3
"""arc-to-bookmarks.py — turn Arc's sidebar into a bookmarks file Chrome imports.

Arc keeps spaces, pinned tabs, folders and favorites in StorableSidebar.json,
which no other browser reads. This writes them out as a Netscape bookmarks
HTML file (the format every browser's "Import bookmarks" accepts), one folder
per space with its pinned folders nested as they were, plus Favorites and each
space's open "Today" tabs.

Usage:
  scripts/arc-to-bookmarks.py [OUT.html]   (default: ~/Documents/arc-export/arc-bookmarks.html)

Then in Chrome: Settings → Import bookmarks and settings → Bookmarks HTML file.
Read-only against Arc; safe to run while Arc is open.
"""
import html
import json
import os
import sys
import time

SIDEBAR = os.path.expanduser("~/Library/Application Support/Arc/StorableSidebar.json")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Documents/arc-export/arc-bookmarks.html")

data = json.load(open(SIDEBAR))
container = next(c for c in data["sidebar"]["containers"] if "items" in c)
items = {x["id"]: x for x in container["items"] if isinstance(x, dict)}
spaces = [x for x in container["spaces"] if isinstance(x, dict)]
now = int(time.time())
counts = {"links": 0, "folders": 0}


def title_of(item):
    tab = item.get("data", {}).get("tab", {})
    return item.get("title") or tab.get("savedTitle") or tab.get("savedURL") or "Untitled"


def render(item_id, depth):
    """Lines for one sidebar item: a link for a tab, a folder for anything with children."""
    item = items.get(item_id)
    if not item:
        return []
    pad = "    " * depth
    tab = item.get("data", {}).get("tab")
    if tab and tab.get("savedURL"):
        counts["links"] += 1
        return [f'{pad}<DT><A HREF="{html.escape(tab["savedURL"], quote=True)}" ADD_DATE="{now}">'
                f"{html.escape(title_of(item))}</A>"]
    children = [line for ch in item.get("childrenIds", []) for line in render(ch, depth + 1)]
    if not children:
        return []
    counts["folders"] += 1
    return [f'{pad}<DT><H3 ADD_DATE="{now}">{html.escape(item.get("title") or "Folder")}</H3>',
            f"{pad}<DL><p>", *children, f"{pad}</DL><p>"]


def folder(name, child_ids, depth):
    pad = "    " * depth
    body = [line for ch in child_ids for line in render(ch, depth + 1)]
    if not body:
        return []
    counts["folders"] += 1
    return [f'{pad}<DT><H3 ADD_DATE="{now}">{html.escape(name)}</H3>', f"{pad}<DL><p>", *body, f"{pad}</DL><p>"]


lines = []
for fav in container.get("topAppsContainerIDs", []):
    if isinstance(fav, str) and fav in items:
        lines += folder("Favorites", items[fav].get("childrenIds", []), 1)
for n, space in enumerate(spaces, 1):
    ids = space.get("containerIDs", [])
    slots = dict(zip(ids[::2], ids[1::2]))
    name = space.get("title") or f"Space {n}"
    space_lines = []
    for slot, label in (("pinned", "Pinned"), ("unpinned", "Today (open tabs)")):
        cid = slots.get(slot)
        if cid in items:
            space_lines += folder(label, items[cid].get("childrenIds", []), 2)
    if space_lines:
        counts["folders"] += 1
        lines += [f'    <DT><H3 ADD_DATE="{now}">{html.escape(name)}</H3>', "    <DL><p>", *space_lines, "    </DL><p>"]

doc = "\n".join([
    "<!DOCTYPE NETSCAPE-Bookmark-file-1>",
    '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
    "<TITLE>Bookmarks</TITLE>",
    "<H1>Bookmarks</H1>",
    "<DL><p>",
    f'    <DT><H3 ADD_DATE="{now}">From Arc</H3>',
    "    <DL><p>",
    *["    " + line for line in lines],
    "    </DL><p>",
    "</DL><p>",
])
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    f.write(doc + "\n")
print(f"wrote {OUT}: {counts['links']} links in {counts['folders']} folders from {len(spaces)} spaces")
