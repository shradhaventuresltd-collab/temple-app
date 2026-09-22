# Android Play internal-test prep

This prepares the Android identity and release-signing scaffold. It does not upload to Play, and it does not add directory search. The first internal-test upload still waits on that separate search work.

| Item | Value |
| --- | --- |
| Application id | `com.shradhaventures.temple` |
| Namespace | `com.shradhaventures.temple` |
| Launcher label | Temple Directory India |
| Version | unchanged (`pubspec.yaml` `version`) |

`MainActivity` lives at `android/app/src/main/kotlin/com/shradhaventures/temple/MainActivity.kt`.

## Firebase follow-up (Sanu)

The existing Firebase config files were left unchanged on purpose. They still belong to the old Android package `com.example.temple_app`:

- `android/app/google-services.json` (`package_name`)
- `lib/firebase_options.dart` (generated Android `FirebaseOptions`)

Do not invent API keys, app ids, or a replacement `google-services.json`.

Before an Android build that applies the Google Services plugin, or before any Play upload:

1. In Firebase project `temple-directory-india`, register a **new Android app** with package name `com.shradhaventures.temple`.
2. Download that app's generated config and replace `android/app/google-services.json`.
3. Regenerate `lib/firebase_options.dart` (FlutterFire) so the Android options match the new app. Leave iOS, macOS, web, and Windows entries as the CLI emits them.

The Google Services Gradle plugin matches `applicationId` to `package_name`. Until step 2 lands, Android assemble fails with no matching client for `com.shradhaventures.temple`.

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

After signing is configured, Android assemble is still blocked until the Firebase follow-up above is done. The Google Services plugin fails while `google-services.json` names `com.example.temple_app`. A release build reports the signing error first when the upload key is absent, so that message appears before the Firebase package error.

```bash
flutter build appbundle --release
```

The bundle is `build/app/outputs/bundle/release/app-release.aab`.
