#!/usr/bin/env bash
#
# verify-secrets.sh — confirm you still remember the age passphrase and that the
# encrypted SSH keys in secrets/ match the ones currently in ~/.ssh.
#
# Safe to run anytime: prints only fingerprints (never key material) and leaves
# nothing decrypted on disk. Run this before relying on a fresh-machine bootstrap.
#
set -euo pipefail

DOTS="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$DOTS/secrets"
AGE="$(command -v age || echo /run/current-system/sw/bin/age)"

TMP="$(mktemp -d)"; chmod 700 "$TMP"
trap 'rm -rf "$TMP"' EXIT

echo "==> Decrypting the age identity (enter your passphrase):"
if ! "$AGE" -d -o "$TMP/id" "$SECRETS/age-identity.txt"; then
  echo
  echo "✗ Could not decrypt the identity — wrong passphrase (or corrupt file)."
  echo "  If you've genuinely lost the passphrase, re-run scripts/encrypt-keys.sh"
  echo "  to generate a fresh keypair + set a new passphrase, then commit."
  exit 1
fi
echo "✓ Passphrase correct — identity decrypted."
echo

ok=1
for k in christory644 chris-certifyos; do
  # private key .age decrypts to a valid OpenSSH key? (header check, never printed)
  if "$AGE" -d -i "$TMP/id" "$SECRETS/${k}.age" 2>/dev/null | head -1 | grep -q 'BEGIN OPENSSH PRIVATE KEY'; then
    privok="yes"
  else
    privok="no"
  fi
  # public key matches the current ~/.ssh key? (fingerprints — no passphrase needed)
  "$AGE" -d -i "$TMP/id" -o "$TMP/${k}.pub" "$SECRETS/${k}.pub.age" 2>/dev/null || true
  enc="$(ssh-keygen -lf "$TMP/${k}.pub" 2>/dev/null | awk '{print $2}')"
  cur="$(ssh-keygen -lf "$HOME/.ssh/${k}.pub" 2>/dev/null | awk '{print $2}')"

  if [ "$privok" = "yes" ] && [ -n "$enc" ] && [ "$enc" = "$cur" ]; then
    echo "✓ ${k}: private key decrypts, public key matches current"
    echo "    ${enc}"
  else
    echo "✗ ${k}: privkey-decodes=${privok}  encrypted-pub=${enc:-<none>}  current-pub=${cur:-<missing>}"
    echo "    → keys differ or won't decrypt; re-run scripts/encrypt-keys.sh and commit"
    ok=0
  fi
done

# repos-private manifest just needs to decrypt cleanly
if "$AGE" -d -i "$TMP/id" "$SECRETS/repos-private.yml.age" >/dev/null 2>&1; then
  echo "✓ repos-private.yml: decrypts cleanly"
else
  echo "✗ repos-private.yml: failed to decrypt"
  ok=0
fi

echo
if [ "$ok" = 1 ]; then
  echo "==> All good — passphrase remembered, encrypted keys are current."
  echo "    A fresh-machine bootstrap (scripts/bootstrap.sh) will work."
else
  echo "==> Issues above — fix before relying on this for a new machine."
fi
