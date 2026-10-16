# Android Play internal-test prep

This prepares the Android identity and release-signing scaffold. It does not upload to Play. Directory search is already in the app. Draft Play listing copy is in [`play-store-listing.md`](play-store-listing.md).

| Item | Value |
| --- | --- |
| Application id | `com.shradhaventures.temple` |
| Namespace | `com.shradhaventures.temple` |
| Launcher label | Temple Directory India |
| Version | unchanged (`pubspec.yaml` `version`) |

`MainActivity` lives at `android/app/src/main/kotlin/com/shradhaventures/temple/MainActivity.kt`.

## Firebase Android app

Firebase project `temple-directory-india` now has an Android app for `com.shradhaventures.temple`. The checked-in `android/app/google-services.json` is the file Firebase generated for that registration. It still lists the old `com.example.temple_app` client as well as the new one. The Android `FirebaseOptions` in `lib/firebase_options.dart` use the new app id `1:109314154382:android:d34e6caea62c14124ccedf`. iOS, macOS, web, and Windows options are unchanged.

The Google Services plugin selects the client whose `package_name` matches `applicationId`.

## Upload keystore

Create the upload key on a machine you control. Do not commit the keystore or its passwords.

```bash
keytool -genkey -v \
  -keystore <path-to-upload-keystore>.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias <key-alias>
```

`keytool` prompts for the store password, the key password, and the certificate name fields. Current Java defaults to PKCS12, which uses one password: if `keytool` warns that a separate key password is ignored, put that same store password in both `storePassword` and `keyPassword`. Keep the passwords in a password manager. A lost upload key cannot be rotated the same way as a Play app signing key.

Prefer a path outside the repo. If the file sits inside the repo, `*.jks` and `*.keystore` are gitignored (repo root `.gitignore` and `android/.gitignore`).

## `android/key.properties`

Create `android/key.properties` locally. It is gitignored. Use placeholders only in git; put real values only on disk.

```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-upload-keystore>
```

`storeFile` is resolved from the `android/app` module:

- Absolute path: `/home/<user>/keys/upload-keystore.jks`
- Relative path: `../upload-keystore.jks` when the file is `android/upload-keystore.jks`

All four keys are required for a release build, and `storeFile` must point at a real keystore. Debug builds do not read this file.

If `android/key.properties` is missing, any of those keys is blank, or `storeFile` does not exist, `flutter build apk --release` and `flutter build appbundle --release` fail before signing. The error names what is missing and points at this document. The release build is not signed with the debug keystore.

Debug builds (`flutter run`, `flutter build apk --debug`) do not need the upload key.

A release build reports that signing error before it packages an artifact. Debug builds do not need the upload key. The Google Services plugin can match `com.shradhaventures.temple` from the checked-in `google-services.json`.

Build the Play bundle with `scripts/build_play_aab.sh`. It runs `flutter build appbundle --release` and then checks the bundle certificate with `apksigner` or `keytool`. The script refuses:

- `ENABLE_ADMIN_TOOLS` in `--dart-define=...` (`=` form), `--dart-define ...` (space form), the environment, or a `--dart-define-from-file` (equals or space form) whose file contains that name
- `DEMO_BUILD` in those same forms (that define forces AdMob test units)
- `DEMO_APP_ID_SUFFIX` in those same forms, plus `-Pdemo_suffix` and `ORG_GRADLE_PROJECT_demo_suffix`. Gradle applies `applicationIdSuffix` `.demo` for either of those. The Play bundle stays `com.shradhaventures.temple`. `bundleRelease` also fails if that suffix is on. The suffix belongs only on the App Distribution demo APK.
- a signing cert whose subject contains `CN=Android Debug`
- a HEAD SHA that does not have a successful `android-smoke` job from `schedule` or `workflow_dispatch`. A `pull_request` run does not count. Those runs carry the PR head SHA, not the merge ref. The script checks with `gh api` or `curl` using `GH_TOKEN`, `GITHUB_TOKEN`, or `gh auth token`. The only bypass of that check is exactly `SMOKE_GATE_OVERRIDE=1`. That prints a loud warning and continues. `SMOKE_GATE_OVERRIDE=0` and any other value do not bypass it. Do not set it for a Play upload unless you accept an unsmoked commit.
- a dirty working tree (`git status --porcelain` is non-empty). `SMOKE_GATE_OVERRIDE` does not bypass that. There is no separate release workflow; this script is the release gate. `--verify-signing` does not run the smoke gate.

Seed, CMS, and Upload stay out of the Play AAB, and a release bundle cannot ship signed with the Android debug key. Demo APKs pass their defines on their own `flutter build apk` command; do not use the Play script for those, and never upload a demo APK to Play. CI has no upload key, so it runs `scripts/test_play_aab_guard.sh` instead of producing an AAB. Local Maestro steps are in [testing.md](testing.md).

```bash
./scripts/build_play_aab.sh
```

The bundle is `build/app/outputs/bundle/release/app-release.aab`.
