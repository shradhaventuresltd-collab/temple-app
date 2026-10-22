# CI and demo signing

CI profile builds, the demo-seed release APK, and tester-checks sign with one fixed keystore so the certificate SHA-1 stays the same from run to run. That SHA-1 is what you register before restricting the Android Firebase API key. This keystore is not the Play upload key. Play release signing stays in [android-play-internal-test.md](android-play-internal-test.md).

The application id stays `com.shradhaventures.temple`. `scripts/build_play_aab.sh` still refuses `ENABLE_ADMIN_TOOLS` and `DEMO_BUILD`. Do not put those defines on the Play bundle.

Do not commit the keystore, its base64, its passwords, a `google-services` file, or a service-account JSON. `*.jks`, `*.keystore`, `*.p12`, and `android/key.properties` are gitignored.

## Generate the keystore locally

Run this on a machine you control. `keytool` prompts for the store password and the key password. Do not pass those passwords on the command line; they would land in shell history.

```bash
mkdir -p "$HOME/keys"
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore "$HOME/keys/temple-ci-debug.p12" \
  -alias ci-debug \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Temple Directory CI, OU=CI, O=Shradha Ventures, L=Bengaluru, ST=KA, C=IN"
```

Keep the file outside the repo. Current Java defaults to PKCS12, which uses one password: if `keytool` warns that a separate key password is ignored, put that same store password in both `CI_DEBUG_KEYSTORE_PASSWORD` and `CI_DEBUG_KEY_PASSWORD`.

`storeType` is hard-coded to PKCS12 in two places. `scripts/ci/prepare_ci_debug_keystore.sh` always writes `storeType=PKCS12` into the temporary `key.properties`. `android/app/build.gradle.kts` sets `storeType = "PKCS12"` on the debug signing config when `CI_DEBUG_KEYSTORE_FILE` points at this keystore. Gradle would otherwise treat that file as JKS. Play `android/key.properties` can omit `storeType`; the release signing config still uses the AGP default unless that file sets it. Do not point the CI debug signing config at a JKS upload key.

Do not reuse the Play upload key. A CI secret is a different trust boundary from the upload key.

## Read the SHA-1 and SHA-256

`keytool` prompts for the store password. Copy the `SHA1` and `SHA256` lines. Do not copy the password into git, a workflow file, or Firebase.

```bash
keytool -list -v \
  -keystore "$HOME/keys/temple-ci-debug.p12" \
  -alias ci-debug
```

After the secrets below are set, the same fingerprints are printed in the GitHub Actions log as:

```text
signing SHA-1: AA:BB:...
signing SHA-256: CC:DD:...
```

Those lines are the certificate fingerprints only. The jobs do not print the keystore or the passwords.

## Add the four repository secrets

In GitHub: Settings → Secrets and variables → Actions → New repository secret.

| Secret | Value |
| --- | --- |
| `CI_DEBUG_KEYSTORE_BASE64` | base64 of the `.p12` file, one line |
| `CI_DEBUG_KEYSTORE_PASSWORD` | store password |
| `CI_DEBUG_KEY_ALIAS` | alias passed to `keytool` (`ci-debug` if you used the command above) |
| `CI_DEBUG_KEY_PASSWORD` | key password (same as the store password on PKCS12) |

Print the base64 locally and paste it into the secret. Do not commit it.

```bash
# Linux
base64 -w0 "$HOME/keys/temple-ci-debug.p12"

# macOS
base64 -i "$HOME/keys/temple-ci-debug.p12" | tr -d '\n'
```

## Which builds use it

| Workflow | Build | Secrets missing |
| --- | --- | --- |
| `android-smoke` | profile APK, `DEMO_BUILD`, no `ENABLE_ADMIN_TOOLS` | default debug keystore |
| `demo-seed-launch` | release APK, `DEMO_BUILD` and `ENABLE_ADMIN_TOOLS` | job fails |
| `tester-checks` | release APK, neither define | job fails |

Each job decodes `CI_DEBUG_KEYSTORE_BASE64` to a temp file under the runner temp directory and deletes that file after the build. Release CI jobs also write gitignored `android/key.properties` so the existing release signing config can use the temp file. They delete that properties file after signing. None of this changes the Play upload-key block in `android/app/build.gradle.kts`.

`demo-app-distribution` is a separate fixed keystore (`DEMO_KEYSTORE_B64`, `DEMO_KEYSTORE_PASSWORD`, `DEMO_KEY_ALIAS`, `DEMO_KEY_PASSWORD`). That APK is `com.shradhaventures.temple.demo`. Its job prints its own SHA-1 and SHA-256. See [testing.md](testing.md).

## Local builds

Debug and profile builds (`flutter run`, `flutter build apk --debug`, `flutter build apk --profile`) do not need these secrets. Gradle keeps the Android default debug signing config when `CI_DEBUG_KEYSTORE_FILE` is unset.

To sign a local debug or profile build with the CI certificate, point Gradle at the `.p12` file and export the alias and the two passwords in your shell. Do not export `CI_DEBUG_KEYSTORE_BASE64` into Gradle, and do not commit the passwords.

```bash
export CI_DEBUG_KEYSTORE_FILE="$HOME/keys/temple-ci-debug.p12"
export CI_DEBUG_KEY_ALIAS=ci-debug
export CI_DEBUG_KEYSTORE_PASSWORD
export CI_DEBUG_KEY_PASSWORD
```

`export NAME` with no value keeps the value already set in the shell. Type the password at the prompt when you set it, not in a file in this repo.

A local release build still requires `android/key.properties` and the Play upload key. It does not fall back to this CI keystore or to the debug keystore. If `CI_DEBUG_KEYSTORE_FILE` is set but the file or the other three variables are missing, the build fails instead of silently using the debug key.

The machine debug keystore is a different certificate on each computer. Its well-known store password is `android` and its alias is `androiddebugkey`:

```bash
keytool -list -v \
  -keystore "$HOME/.android/debug.keystore" \
  -alias androiddebugkey \
  -storepass android
```

## Register the fingerprints in Firebase

Firebase console → project `temple-directory-india` → Project settings → Your apps → the Android app `com.shradhaventures.temple` → Add fingerprint. Add the CI keystore SHA-1 and SHA-256.

When you restrict the Android API key (Google Cloud console → APIs & Services → Credentials → the Android key → Application restrictions → Android apps), add:

- package `com.shradhaventures.temple` and the CI keystore SHA-1
- package `com.shradhaventures.temple` and the Play App Signing SHA-1 (Play Console → App integrity → App signing)
- package `com.shradhaventures.temple.demo` and the `DEMO_KEYSTORE_*` SHA-1 from the demo-app-distribution log
- package `com.shradhaventures.temple` and each developer machine's debug SHA-1, if local debug builds must keep calling that API key

Restricting the key to only the CI SHA-1 stops local debug builds and Play-signed builds from using it until those SHA-1s are listed too.
