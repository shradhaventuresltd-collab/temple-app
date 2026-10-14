# Testing

Unit and widget tests run with `flutter test`. GitHub Actions workflow `analyze-test` runs on every pull request (no path filter) and on pushes to `main`. It runs `flutter pub get`, `flutter analyze`, and `flutter test`. **KAN-90 required checks are `analyze-test` only.**

Workflow `android-smoke` does not run on pull requests and has no `push` trigger. A push trigger that would run smoke after three merges was not added. Smoke runs at 10:00, 17:00, 22:00, and 05:00 IST (`30 4,11,16,23 * * *` UTC) and via `workflow_dispatch`. The first job reads the Actions API for `android-smoke` runs on `branch=main`. It skips the emulator when `main` HEAD is already the last successful job's `head_sha`, and also when HEAD is the last failed attempt, so a red main is not retried on every schedule slot. A `failure` conclusion counts. A `cancelled` conclusion on a `schedule`-triggered run counts as failed. Setup usually takes about 6 to 7 minutes, so the 15-minute job limit fires before the 12-minute shell timeout (`timeout --kill-after=30s 12m`), and GitHub concludes that job `cancelled`. A `workflow_dispatch` cancel does not count. Manually cancelling a scheduled run does count, so that SHA is not retried until a new commit or a `workflow_dispatch`. `workflow_dispatch` always runs the emulator. The emulator job `timeout-minutes` stays 15. Gradle is cached with `actions/cache`. The pub cache is cached by `subosito/flutter-action` (`cache: true`). The emulator system image and the AVD snapshot are already cached with `actions/cache`, keyed on API level, ABI, and system image: `system-image-android-34-google_apis-x86_64` and `avd-34-x86_64-google_apis-pixel6-snapshot`. A cache hit keeps a run near 8 minutes. On an AVD cache miss the job boots once to save a snapshot, then runs smoke with `-no-snapshot-save`. The schedule stays four runs a day.

Concurrency uses `group: ${{ github.workflow }}-${{ github.ref }}` and cancels an in-progress run only for pull requests. Pushes to `main`, the smoke schedule, and manual dispatches are not cancelled.

If the smoke job or the skip/plan job fails, the workflow opens one issue labelled `smoke-failure`, or adds a comment when that issue is already open. Setup usually takes about 6 to 7 minutes, so the 15-minute job limit fires before the 12-minute shell timeout and the job is `cancelled`. A scheduled run that is `cancelled`, including a job-limit timeout and a manual cancel of that scheduled run, posts the same way and counts as the last failed SHA. A manually cancelled `workflow_dispatch` run does not post and does not block the next scheduled retry. The comment lists commits between the last green SHA and the failing SHA, plus links to the run and the `maestro-debug` artifact. It does not rewrite the existing issue body. `issues: write` is granted only on that job. The plan job has `actions: read` only.

Public legal pages, after Deployer runs `firebase deploy --only hosting --project temple-directory-india`:

- https://temple-directory-india.web.app/privacy-policy.html
- https://temple-directory-india.web.app/terms-of-service.html

Neither workflow signs a Play bundle or uploads to App Distribution.

A weekly workflow, `actions-minutes`, adds this repository's `analyze-test` minutes and `android-smoke` minutes into one total and compares that total with the 2,000 minute private-repo budget. It opens or updates an issue labelled `actions-minutes` when the total is at or above 1,500 minutes. The issue says: change the android-smoke cron to two runs a day, 10 AM and 10 PM IST (cron `30 4,16 * * *`). The workflow cron stays `30 4,11,16,23 * * *` (four runs a day) until that change is made. The optional repository secret `BILLING_TOKEN` is a fine-grained personal access token created by the owner of this user-owned account, with account permission **Plan: Read-only**. `GITHUB_TOKEN` cannot read billing here. When that secret works, the issue also records the account-wide billing figure. The 1,500 comparison stays the combined `analyze-test` and `android-smoke` total for this repository.

`scripts/build_play_aab.sh` refuses to build unless the `android-smoke` job has succeeded on that exact HEAD SHA (`GH_TOKEN`, `GITHUB_TOKEN`, or `gh auth token`), and it refuses when `git status --porcelain` is non-empty. The only bypass of the green-smoke check is exactly `SMOKE_GATE_OVERRIDE=1`, which prints a loud warning and continues. `0` and any other value are not a bypass. The override does not bypass a dirty tree. There is no release workflow; the script is the release gate. Do not set the override for a Play upload unless you accept an unsmoked commit.

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

`scripts/build_play_aab.sh` refuses `DEMO_BUILD` and `ENABLE_ADMIN_TOOLS`, a bundle signed with `CN=Android Debug`, a dirty working tree, and a HEAD SHA that does not have a successful `android-smoke` job. Exactly `SMOKE_GATE_OVERRIDE=1` bypasses only that smoke check, and it prints a loud warning. CI does not have the Play upload key, so `analyze-test` runs `scripts/test_play_aab_guard.sh` instead of building an AAB. Signing setup is in [android-play-internal-test.md](android-play-internal-test.md).
