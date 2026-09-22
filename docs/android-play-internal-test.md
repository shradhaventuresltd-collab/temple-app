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

```bash
flutter build appbundle --release
```

The bundle is `build/app/outputs/bundle/release/app-release.aab`.
