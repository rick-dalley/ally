# Android release signing

Ally's release build was signing with the debug key — the throwaway key every
Flutter install shares, sitting in `~/.android/debug.keystore`. Play rejects any
bundle signed with it, so Ally could not have been uploaded at all.

This describes the one keystore that signs **both** Ally and the Wear OS
companion. They must share it: the Wear Data Layer pairs nodes by application ID
*and* signing key, so a watch signed with a different key never finds the phone.

## The two keys, which are not the same thing

With **Play App Signing** (accept it when Play Console offers — it is the
default for new apps) there are two keys, and it matters which is which:

- **The app signing key** is what users' devices verify. Google generates and
  holds it. You never see it. It never expires and can never be replaced.
- **The upload key** is what you sign with. Play checks it, strips it, and
  re-signs with the app signing key before distributing. *This* is the key the
  steps below create.

The practical consequence: **losing the upload key is recoverable** — Play
support can register a new one — while losing the app signing key would end the
app, which is exactly why letting Google hold it is the safer arrangement.

## The short way

`./tool/setup-signing.sh` does everything below: creates the keystore if it is
missing, verifies the password you give it actually opens it, writes
`key.properties` into both `ally/` and `wear_os/` with the right absolute path,
and checks git is ignoring both. It never overwrites an existing keystore, and
asks before replacing a `key.properties`.

The rest of this file is what the script does, for when you would rather do it
by hand or something goes wrong.

## Creating the keystore

Run this once, anywhere outside both repos. `~/keys/` is as good a place as any;
whatever you choose, it must not be inside a git working tree.

    mkdir -p ~/keys
    keytool -genkeypair -v -keystore ~/keys/cwicare-upload.jks \
      -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
      -alias upload

It prompts for a password and for name/organization details. The details are
cosmetic — nothing displays them to users — but the password is not: there is no
recovery for it, so put it in a password manager before you close the terminal.

`-validity 10000` is about 27 years. Play requires a key valid past 2033, and an
expired upload key is an avoidable annoyance, so do not shorten it.

## Pointing the builds at it

Create `android/key.properties` in **both** `ally/` and `wear_os/`, with an
absolute path (Gradle does not expand `~`):

    storeFile=/Users/you/keys/cwicare-upload.jks
    storePassword=...
    keyAlias=upload
    keyPassword=...

Both repos already gitignore `key.properties`, `*.jks` and `*.keystore`, so
neither the file nor the keystore can be committed by accident. Nothing else
needs editing — `android/app/build.gradle.kts` reads this file if it is there.

## Checking it worked

    flutter build apk --release
    ~/Library/Android/sdk/build-tools/*/apksigner verify --print-certs \
      build/app/outputs/flutter-apk/app-release.apk

The certificate DN it prints should be the one you entered, not
`CN=Android Debug`. `cd android && ./gradlew :app:signingReport` answers the same
question without a full build.

If `key.properties` is missing, the release build still works — it falls back to
the debug key so a fresh clone is not broken — but it logs a warning saying so.
Take that warning seriously: it means the artifact cannot be uploaded.

## What to upload

Play wants an app bundle, not an APK:

    flutter build appbundle --release

The result is `build/app/outputs/bundle/release/app-release.aab`.

## Back it up

The keystore is a single file that cannot be regenerated. Copy it somewhere that
survives this machine dying, and store the password separately from it.
