#!/usr/bin/env bash
#
# adopt-agent-state.sh — make synced agent history usable under a new username.
#
# Claude Code files each project's transcripts AND auto-memory under
# <config>/projects/<absolute path with every non-alphanumeric turned into '-'>.
# The old Mac's user is `christopherstory`, the new Mac's is `christory`, so the
# same repo is `-Users-christopherstory-repos-x` there and `-Users-christory-repos-x`
# here. Syncthing carries the old folders over intact, but nothing here ever
# looks in them: `claude --resume <id>` says the session doesn't exist and every
# project starts with no memory.
#
# Fix: for each old-named project folder, link the new name to it (a relative
# symlink, so both Macs keep writing to one synced folder during coexistence).
# A new-named folder that already holds real files is merged into the old one
# first. Idempotent; run on the NEW Mac after scripts/sync-status.sh settles.
#
# Usage: scripts/adopt-agent-state.sh [old-username]   (default: christopherstory)
#
# TEARDOWN: keep — the symlinks are what make the old history readable here.
set -euo pipefail

OLD="${1:-christopherstory}"
NEW="$(id -un)"
[ "$OLD" != "$NEW" ] || { echo "Old and new usernames are both '$NEW' — nothing to do."; exit 0; }

linked=0 merged=0 skipped=0 live=0
for cfg in "$HOME"/.claude "$HOME"/.claude-personal "$HOME"/.claude-work "$HOME"/.claude-work-sub; do
  P="$cfg/projects"
  [ -d "$P" ] || continue
  # names start with '-', so paths stay absolute and ln gets '--'
  for o in "$P/-Users-$OLD" "$P/-Users-$OLD-"*; do
    [ -d "$o" ] && [ ! -L "$o" ] || continue
    old="${o##*/}"
    new="-Users-$NEW${old#-Users-$OLD}"
    n="$P/$new"

    if [ -L "$n" ]; then
      skipped=$((skipped + 1)); continue
    elif [ -d "$n" ]; then
      # a transcript written in the last 10 minutes belongs to a live session —
      # quite possibly the one running this script. Moving it would pull the
      # file out from under its writer; leave the folder for a later run.
      if [ -n "$(find "$n" -name '*.jsonl' -mmin -10 -print -quit)" ]; then
        echo "  skipped (live session): ${cfg##*/}/projects/$new — re-run with that agent quit" >&2
        live=$((live + 1)); continue
      fi
      # this Mac already started a history here; fold it in without clobbering
      (cd "$n" && find . -mindepth 1 -type f -print0) | while IFS= read -r -d '' f; do
        f="${f#./}"
        mkdir -p "$(dirname "$o/$f")"
        if [ -e "$o/$f" ]; then
          echo "  kept both: ${cfg##*/}/projects/$old/$f (renamed .from-$NEW)" >&2
          mv "$n/$f" "$o/$f.from-$NEW"
        else
          mv "$n/$f" "$o/$f"
        fi
      done
      find "$n" -depth -type d -empty -delete
      [ ! -e "$n" ] || { echo "  could not empty $n — left alone" >&2; continue; }
      merged=$((merged + 1))
    fi

    ln -s -- "$old" "$n"
    linked=$((linked + 1))
  done
done

echo "linked $linked project folders ($merged merged first), $skipped already linked, $live left for a live session."
echo "Resume old sessions from the matching directory under /Users/$NEW with --resume <id>."
