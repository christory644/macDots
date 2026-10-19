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
# Fix: the NEW-named folder is the real directory and the OLD name is a symlink
# to it, so both Macs keep writing into one synced folder during coexistence.
#
# DIRECTION MATTERS, and an earlier version of this script had it backwards.
# Claude Code refuses to write tool-results into a symlinked project folder
# ("tool-results path refused: … is a link or not a directory"), so large hook
# output was silently truncated and compaction-restore lost state. The real
# directory must be the one the LIVE machine uses. This script also converts an
# existing backwards layout, so running it again repairs machines that got the
# old behaviour.
#
# Quit agents first. A folder with a transcript written in the last 10 minutes
# is left alone rather than pulled out from under its writer.
#
# Usage: scripts/adopt-agent-state.sh [old-username]   (default: christopherstory)
#
# TEARDOWN: keep — the symlinks are what make the old history readable here.
set -euo pipefail

OLD="${1:-christopherstory}"
NEW="$(id -un)"
[ "$OLD" != "$NEW" ] || { echo "Old and new usernames are both '$NEW' — nothing to do."; exit 0; }

is_live() { [ -n "$(find "$1" -name '*.jsonl' -mmin -10 -print -quit 2>/dev/null)" ]; }

inverted=0 moved=0 merged=0 skipped=0 live=0
for cfg in "$HOME"/.claude "$HOME"/.claude-personal "$HOME"/.claude-work "$HOME"/.claude-work-sub; do
  P="$cfg/projects"
  [ -d "$P" ] || continue
  # names start with '-', so paths stay absolute and ln gets '--'
  for o in "$P/-Users-$OLD" "$P/-Users-$OLD-"*; do
    [ -e "$o" ] || continue
    old="${o##*/}"
    new="-Users-$NEW${old#-Users-$OLD}"
    n="$P/$new"

    # already correct: old name is a symlink, new name is the real directory
    if [ -L "$o" ] && [ -d "$n" ] && [ ! -L "$n" ]; then
      skipped=$((skipped + 1)); continue
    fi

    [ -d "$o" ] && [ ! -L "$o" ] || { skipped=$((skipped + 1)); continue; }

    if is_live "$o"; then
      echo "  skipped (live session): ${cfg##*/}/projects/$old — re-run with that agent quit" >&2
      live=$((live + 1)); continue
    fi

    if [ -L "$n" ]; then
      # BACKWARDS LAYOUT: new name is a symlink to the old real directory.
      # Drop the link, promote the real directory to the new name, point the
      # old name at it. The gap between mv and ln is where a live writer would
      # break, which is why is_live gates this.
      rm -- "$n"
      mv -- "$o" "$n"
      ln -s -- "$new" "$o"
      inverted=$((inverted + 1))
    elif [ -d "$n" ]; then
      # both names hold real files — fold the old into the new without clobbering
      (cd "$o" && find . -mindepth 1 -type f -print0) | while IFS= read -r -d '' f; do
        f="${f#./}"
        mkdir -p "$(dirname "$n/$f")"
        if [ -e "$n/$f" ]; then
          echo "  kept both: ${cfg##*/}/projects/$new/$f (renamed .from-$OLD)" >&2
          mv -- "$o/$f" "$n/$f.from-$OLD"
        else
          mv -- "$o/$f" "$n/$f"
        fi
      done
      find "$o" -depth -type d -empty -delete
      [ ! -e "$o" ] || { echo "  could not empty $o — left alone" >&2; continue; }
      ln -s -- "$new" "$o"
      merged=$((merged + 1))
    else
      mv -- "$o" "$n"
      ln -s -- "$new" "$o"
      moved=$((moved + 1))
    fi
  done
done

echo "inverted $inverted, moved $moved, merged $merged, $skipped already correct, $live left for a live session."
echo "Resume old sessions from the matching directory under /Users/$NEW with --resume <id>."
