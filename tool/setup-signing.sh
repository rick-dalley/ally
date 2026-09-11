#!/usr/bin/env bash
#
# Creates the CWICare upload keystore if it doesn't exist yet, then writes
# android/key.properties into both the Ally and Wear OS projects so their
# release builds stop falling back to the debug key.
#
# One keystore signs both. The Wear Data Layer pairs nodes by application ID
# AND signing key, and the watch app declares standalone=false, so a watch
# signed with a different key would never find the phone.
#
# Safe to re-run: it never overwrites an existing keystore, and asks before
# replacing a key.properties that is already there.
#
#   ./tool/setup-signing.sh
#
set -euo pipefail

KEYSTORE="${KEYSTORE:-$HOME/keys/cwicare-upload.jks}"
ALIAS="${ALIAS:-upload}"

# This script lives in ally/tool, so the two project roots are siblings.
ALLY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEAR="$(cd "$ALLY/.." && pwd)/wear_os"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# --- 1. the keystore -------------------------------------------------------
if [[ -f "$KEYSTORE" ]]; then
  say "Keystore already exists: $KEYSTORE"
  echo "Leaving it alone. Delete it by hand if you really mean to start over —"
  echo "but once an app has been published under a key, replacing it is a"
  echo "support ticket with Google, not a local decision."
else
  say "Creating $KEYSTORE"
  echo "keytool will ask for a password, then some name/organization details."
  echo "The details are cosmetic. The password is NOT — there is no recovery"
  echo "for it. Put it in your password manager before this window closes."
  echo
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -v \
    -keystore "$KEYSTORE" \
    -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$ALIAS"
fi

# --- 2. the password -------------------------------------------------------
# PKCS12 keystores use one password for the store and the key alike, so this is
# asked once. Read silently; it is never echoed and never leaves this machine.
say "Password for $KEYSTORE"
read -r -s -p "Keystore password: " PASS
echo
if ! keytool -list -keystore "$KEYSTORE" -storepass "$PASS" >/dev/null 2>&1; then
  echo "That password does not open the keystore. Nothing was written." >&2
  exit 1
fi
echo "Password verified against the keystore."

# --- 3. key.properties in both projects ------------------------------------
write_props() {
  local root="$1" name="$2" target="$1/android/key.properties"

  if [[ ! -d "$root/android" ]]; then
    echo "  !! $name: no android/ directory at $root — skipped" >&2
    return
  fi
  if [[ -f "$target" ]]; then
    read -r -p "  $name already has key.properties. Replace it? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "  $name: left as it was."; return; }
  fi

  cat > "$target" <<EOF
# Written by ally/tool/setup-signing.sh — see ally/tool/README-signing.md.
# Gitignored, and must stay that way: this file holds the upload key password.
storeFile=$KEYSTORE
storePassword=$PASS
keyAlias=$ALIAS
keyPassword=$PASS
EOF
  chmod 600 "$target"
  echo "  $name: wrote $target"
}

say "Writing key.properties"
write_props "$ALLY" "ally"
write_props "$WEAR" "wear_os"

# --- 4. prove git cannot see them ------------------------------------------
say "Checking both files are ignored by git"
for root in "$ALLY" "$WEAR"; do
  [[ -f "$root/android/key.properties" ]] || continue
  if git -C "$root" check-ignore -q android/key.properties; then
    echo "  $(basename "$root"): ignored, good."
  else
    echo "  !! $(basename "$root"): key.properties is NOT gitignored. Fix before committing." >&2
  fi
done

say "Done"
echo "Verify the release build actually uses it:"
echo
echo "    cd \"$ALLY/android\" && ./gradlew :app:signingReport"
echo
echo "Under 'Variant: release' it should say Config: upload and name your"
echo "keystore — not Config: debug. Then tell Claude and it will check the"
echo "signature on a real release build."
