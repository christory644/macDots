#!/usr/bin/env bash
#
# repo-triage.sh — decide, per repo, whether git or Syncthing should carry it.
#
# Migration default was "Syncthing carries all of ~/repos". That is correct for
# what git structurally cannot hold, and wasteful (and a needless bidirectional
# .git replication risk) for anything a plain `git clone` would restore exactly.
#
#   CLONE  — has an origin remote, clean worktree, no stashes, every local
#            branch pushed, and no gitignored local config sitting on disk.
#            Restore with clone-repos.sh; exclude from the Syncthing seed.
#   SYNC   — anything else. git would silently lose something.
#
# Usage:
#   scripts/repo-triage.sh                      # audit ~/repos here
#   scripts/repo-triage.sh --host user@oldmac   # audit ~/repos over ssh
#   scripts/repo-triage.sh --emit OUTDIR        # also write manifest + ignore list
#
# Emitted into OUTDIR:
#   repos-clone.public.yml   manifest lines for personal remotes
#   repos-clone.private.yml  manifest lines for work remotes (merge into the
#                            encrypted repos-private.yml, then encrypt-keys.sh)
#   stignore-clone           one repo name per line — append to repos/.stignore
#                            (or to the file it #includes) so the seed skips them
#
# Names of private repos are deliberately NOT committed; OUTDIR should be a
# scratch path, and only the encrypted manifest ever lands in git.
set -uo pipefail

HOST=""; EMIT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --emit) EMIT="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

read -r -d '' REMOTE_SCRIPT <<'EOS'
cd "$HOME/repos" || exit 1
for d in */; do
  d=${d%/}
  if [ ! -d "$d/.git" ]; then
    printf 'SYNC\t%s\t-\tnot-a-git-repo\n' "$d"; continue
  fi
  why=""
  url=$(git -C "$d" remote get-url origin 2>/dev/null)
  [ -z "$url" ] && why="$why,no-remote"
  [ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ] && why="$why,dirty"
  [ -n "$(git -C "$d" stash list 2>/dev/null)" ] && why="$why,stash"
  while read -r br; do
    [ -z "$br" ] && continue
    if git -C "$d" rev-parse --abbrev-ref "$br@{u}" >/dev/null 2>&1; then
      n=$(git -C "$d" rev-list --count "$br@{u}..$br" 2>/dev/null || echo 0)
      if [ "${n:-0}" -gt 0 ]; then why="$why,unpushed"; break; fi
    else
      why="$why,local-only-branch"; break
    fi
  done < <(git -C "$d" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
  # gitignored local config a clone would silently drop (.env, *.local, keys)
  if git -C "$d" ls-files --others --ignored --exclude-standard 2>/dev/null \
       | grep -avE '(^|/)(node_modules|target|dist|build|\.next|\.venv|__pycache__|\.pytest_cache|result)/' \
       | grep -aqiE '(^|/)\.env($|\..*)|(^|/)[^/]*\.local($|\.)|\.pem$|\.key$|(^|/)\.envrc$|credentials'; then
    why="$why,local-config"
  fi
  if [ -z "$why" ]; then printf 'CLONE\t%s\t%s\t-\n' "$d" "$url"
  else printf 'SYNC\t%s\t%s\t%s\n' "$d" "${url:--}" "${why#,}"; fi
done
EOS

if [ -n "$HOST" ]; then
  TSV="$(ssh -o BatchMode=yes "$HOST" "bash -s" <<<"$REMOTE_SCRIPT")"
else
  TSV="$(bash -c "$REMOTE_SCRIPT")"
fi
[ -n "$TSV" ] || { echo "no repos found" >&2; exit 1; }

printf '%s\n' "$TSV" | awk -F'\t' '
  {n[$1]++}
  END {printf "CLONE %d repos   SYNC %d repos\n\n", n["CLONE"], n["SYNC"]}'
echo "reasons a repo must sync:"
printf '%s\n' "$TSV" | awk -F'\t' '$1=="SYNC"{print $4}' | tr ',' '\n' \
  | sort | uniq -c | sort -rn | sed 's/^/  /'

if [ -n "$EMIT" ]; then
  mkdir -p "$EMIT"
  printf '%s\n' "$TSV" | awk -F'\t' '$1=="CLONE" && $3 ~ /christory644/ {print $2": "$3}' \
    > "$EMIT/repos-clone.public.yml"
  printf '%s\n' "$TSV" | awk -F'\t' '$1=="CLONE" && $3 !~ /christory644/ {print $2": "$3}' \
    > "$EMIT/repos-clone.private.yml"
  printf '%s\n' "$TSV" | awk -F'\t' '$1=="CLONE"{print $2}' > "$EMIT/stignore-clone"
  echo
  echo "wrote:"
  for f in repos-clone.public.yml repos-clone.private.yml stignore-clone; do
    printf '  %-26s %4d lines\n' "$EMIT/$f" "$(wc -l < "$EMIT/$f")"
  done
fi
