#!/usr/bin/env bash
#
# encrypt-keys.sh — encrypt SSH keys into the repo with a passphrase
#
# Run this whenever you add/rotate SSH keys.
# The encrypted files are safe to commit to the repo.
#
set -euo pipefail

SECRETS_DIR="$(cd "$(dirname "$0")/../secrets" && pwd)"
AGE="age"
command -v age &>/dev/null || AGE="nix run nixpkgs#age --"

echo "==> Encrypting SSH keys (you'll be prompted for a passphrase)"
echo "    Use the same passphrase for all keys — you'll need it on setup."
echo ""

for key in ~/.ssh/christory644 ~/.ssh/chris-certifyos; do
  name="$(basename "$key")"
  echo "--- Encrypting $name ---"
  $AGE -p -o "$SECRETS_DIR/${name}.age" "$key"
  echo "--- Encrypting ${name}.pub ---"
  $AGE -p -o "$SECRETS_DIR/${name}.pub.age" "${key}.pub"
done

echo ""
echo "==> Done. Encrypted files in secrets/:"
ls -la "$SECRETS_DIR"/*.age
echo ""
echo "    Commit these files to the repo."
