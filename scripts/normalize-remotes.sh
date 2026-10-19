#!/usr/bin/env bash
# Rewrite github remotes from the machine-local host aliases back to canonical
# addresses: git@github.com-<account>:OWNER/REPO -> git@github.com:OWNER/REPO.
#
# WHY. The aliases were how a repo got bound to the right ssh key, so they had
# to be typed into every remote. That put a hostname that exists only on this
# machine into 133 .git/config files: not portable, not what anyone else's
# clone looks like, and the reason gh-stack needs GH_REPO= set (it resolves the
# repo from the remote and does not understand the alias).
#
# home/git.nix now routes plain addresses by OWNER — CertifyOS to the work key,
# everything else to the personal one — and asserts the work identity on the
# plain form too. So the alias in the remote is redundant, and removing it
# costs nothing while making every config canonical again.
#
# SAFETY: refuses to run until those rules are actually live, because until the
# rebuild lands a plain CertifyOS address resolves with the PERSONAL key and
# every work repo would break.
#
# Usage: normalize-remotes.sh [--apply]      (default: dry run)
set -uo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# Gate: the insteadOf rules must be in the live git config.
need_work=$(git config --get-regexp '^url\.git@github\.com-chris-certifyos:CertifyOS/\.insteadof$' 2>/dev/null | head -1)
need_pers=$(git config --get-regexp '^url\.git@github\.com-christory644:\.insteadof$' 2>/dev/null | head -1)
if [ -z "$need_work" ] || [ -z "$need_pers" ]; then
  echo "REFUSING: the url.*.insteadOf rules from home/git.nix are not live yet." >&2
  echo "Rebuild first:  sudo darwin-rebuild switch --flake ~/repos/macDots" >&2
  echo "Without them, a plain CertifyOS address uses the PERSONAL key and every" >&2
  echo "work repo breaks." >&2
  exit 1
fi

cd "$HOME/repos" || exit 1
changed=0 repos=0
for d in */; do
  d="${d%/}"
  git -C "$d" rev-parse --git-dir >/dev/null 2>&1 || continue
  touched=0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    url=$(git -C "$d" remote get-url "$name" 2>/dev/null) || continue
    case "$url" in
      git@github.com-chris-certifyos:*) new="git@github.com:${url#git@github.com-chris-certifyos:}" ;;
      git@github.com-christory644:*)    new="git@github.com:${url#git@github.com-christory644:}" ;;
      *) continue ;;
    esac
    if [ "$APPLY" -eq 1 ]; then
      git -C "$d" remote set-url "$name" "$new" && changed=$((changed+1)) && touched=1
    else
      echo "  $d [$name]"
      echo "      $url"
      echo "   -> $new"
      changed=$((changed+1)); touched=1
    fi
  done < <(git -C "$d" remote 2>/dev/null)
  [ "$touched" -eq 1 ] && repos=$((repos+1))
done

echo
if [ "$APPLY" -eq 1 ]; then echo "rewrote $changed remotes across $repos repos"
else echo "would rewrite $changed remotes across $repos repos  (re-run with --apply)"; fi
