# Testing

Unit and widget tests run with `flutter test`. GitHub Actions workflow `analyze-test` runs `flutter pub get`, `flutter analyze`, and `flutter test` on pull requests and on pushes to `main`. Workflow `android-smoke` runs the Maestro flow below on an Android emulator. Both skip `docs/**` and root `*.md` changes. Neither workflow signs a Play bundle or uploads to App Distribution.

CI uses Flutter **3.47.7**. Local runs can use the same SDK.

## Maestro locally

The flow in [`.maestro/read_only_smoke.yaml`](../.maestro/read_only_smoke.yaml) is read-only against the production Firebase project baked into the app. If Firestore is empty or unreachable, the app falls back to the bundled sample temples. **Do not tap Seed, Admin sign-in, or Admin Panel.** Those write, or can write, and CI never runs them.

What it checks:

1. The app draws past the native saffron splash (`Temple Directory` is on screen).
2. Browse opens a list that shows temple cards.
3. Search for `Meenakshi` shows Meenakshi Amman Temple.
4. Opening that card reaches temple detail.
5. **Get Directions** leaves the app. Maps, a browser, or an Android chooser all count. The button still being on screen fails the flow.

Install [Maestro](https://maestro.mobile.dev/) and start an Android emulator (API 30 or newer; CI uses API 34 `google_apis` x86_64). The emulator needs something that can open `https://www.google.com/maps/...` (Chrome or the Maps app). Without that, Get Directions stays in the app and shows "Couldn't open directions on this device."

```bash
flutter pub get
flutter build apk --debug --dart-define=DEMO_BUILD=true
adb install -r build/app/outputs/flutter-apk/app-debug.apk
maestro test .maestro
```

`DEMO_BUILD=true` forces Google's test ad units. Debug builds already use those units; the define keeps a later release or profile smoke build on test units as well. CI builds a profile x86_64 APK so the emulator reaches the first Flutter frame sooner than a debug build. That profile manifest turns Impeller off; release builds keep it. The emulator uses `-no-snapshot-save -no-boot-anim -gpu swiftshader_indirect` with animations disabled. The smoke script waits for `sys.boot_completed`, installs the APK with adb, and Maestro relaunches up to twice if `Temple Directory` is not visible within 60 seconds.

A profile build without admin tools is:

```bash
flutter build apk --profile --dart-define=DEMO_BUILD=true
```

Do not pass `ENABLE_ADMIN_TOOLS` for this flow.

## Demo ads (`DEMO_BUILD`)

`--dart-define=DEMO_BUILD=true` makes `AdHelper` banner and interstitial ids the official Google test units in every mode, including release. KAN-89 is this `DEMO_BUILD` define. There is no `USE_TEST_ADS` define. The Android AdMob application id becomes Google's test app id `ca-app-pub-3940256099942544~3347511713` when Gradle sees `DEMO_BUILD` (Flutter passes it as `-Pdart-defines`). Otherwise Gradle supplies the production Android app id. The main manifest does not hard-code either id: `android/app/src/main/AndroidManifest.xml` sets `com.google.android.gms.ads.APPLICATION_ID` to `${admobAppId}`, and `manifestPlaceholders.admobAppId` in `android/app/build.gradle.kts` fills that placeholder. Test units still show the Test Ad label with the production app id; that is the same pairing debug builds already use.

iOS unit ids follow the same Dart rule. The iOS application id in `ios/Runner/Info.plist` stays the production value.

`scripts/build_play_aab.sh` refuses `DEMO_BUILD` and `ENABLE_ADMIN_TOOLS`, and it refuses a bundle signed with `CN=Android Debug`. CI does not have the Play upload key, so `analyze-test` runs `scripts/test_play_aab_guard.sh` instead of building an AAB. Signing setup is in [android-play-internal-test.md](android-play-internal-test.md).
