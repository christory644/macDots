#!/usr/bin/env bash
#
# encrypt-keys.sh — encrypt SSH keys into the repo with an age keypair
#
# First run generates an age keypair in secrets/. The private key is
# passphrase-protected — you'll only need the passphrase when decrypting
# on a new machine.
#
# Run this whenever you add/rotate SSH keys or update repos-private.yml.
#
set -euo pipefail

DOTS="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_DIR="$DOTS/secrets"
AGE_PKG="$(nix build nixpkgs#age --no-link --print-out-paths 2>/dev/null)"
AGE="${AGE_PKG}/bin/age"
KEYGEN="${AGE_PKG}/bin/age-keygen"

IDENTITY="$SECRETS_DIR/age-identity.txt"
RECIPIENT=""

# ── Generate or load age keypair ─────────────────────────────────────
if [ ! -f "$IDENTITY" ]; then
  echo "==> First run — generating age keypair"
  echo "    The private key will be passphrase-protected."
  echo "    Remember this passphrase — you'll need it on your new machine."
  echo ""

  # Generate a keypair to a temp file (age-keygen won't overwrite, so delete first)
  KEY_TMP="$(mktemp)"; rm -f "$KEY_TMP"
  $KEYGEN -o "$KEY_TMP"
  RECIPIENT="$(grep "public key:" "$KEY_TMP" | sed 's/.*: //')"

  # Encrypt the private key with a passphrase (reads from file, not pipe)
  $AGE -p -a -o "$IDENTITY" "$KEY_TMP"

  # Shred the plaintext key
  rm -f "$KEY_TMP"

  # Store the public key separately (not secret)
  echo "$RECIPIENT" > "$SECRETS_DIR/age-recipient.txt"

  echo ""
  echo "==> Keypair generated. Public key: $RECIPIENT"
else
  RECIPIENT="$(cat "$SECRETS_DIR/age-recipient.txt")"
  echo "==> Using existing age keypair (public key: $RECIPIENT)"
fi

# ── Encrypt function (no passphrase prompt — uses public key) ────────
encrypt() {
  local src="$1" dst="$2"
  echo "  $(basename "$dst")"
  $AGE -r "$RECIPIENT" -o "$dst" "$src"
}

echo ""
echo "==> Encrypting secrets..."

# ── SSH keys ─────────────────────────────────────────────────────────
for key in ~/.ssh/christory644 ~/.ssh/chris-certifyos; do
  name="$(basename "$key")"
  encrypt "$key" "$SECRETS_DIR/${name}.age"
  encrypt "${key}.pub" "$SECRETS_DIR/${name}.pub.age"
done

# ── Private repo manifest ────────────────────────────────────────────
if [ -f "$DOTS/repos-private.yml" ]; then
  encrypt "$DOTS/repos-private.yml" "$SECRETS_DIR/repos-private.yml.age"
fi

echo ""
echo "==> Done. Encrypted files in secrets/:"
ls -la "$SECRETS_DIR"/*.age
echo ""
echo "    Commit these files to the repo."
