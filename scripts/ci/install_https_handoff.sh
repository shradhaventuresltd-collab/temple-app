#!/usr/bin/env bash
# Install a tiny https VIEW handler when the emulator has none.
#
# Get Directions opens
# https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>
# with LaunchMode.externalApplication. The CI image often has no
# browser and no Maps app, so the button stays in-app. This stub only
# matches that Maps URL. It is not the temple app and it does not touch
# Firebase.

set -euo pipefail

MAPS_URL="https://www.google.com/maps/dir/?api=1&destination=9.9195,78.1193"
resolved="$(adb shell pm resolve-activity -a android.intent.action.VIEW -d "$MAPS_URL" 2>/dev/null || true)"
if grep -q 'name=' <<<"$resolved"; then
  echo "https Maps handler already present; not installing a stub"
  exit 0
fi

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK" ]]; then
  echo "error: ANDROID_HOME is not set; cannot build the Maps handoff stub" >&2
  exit 1
fi

bt="$(find "$SDK/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)"
android_jar="$(find "$SDK/platforms" -name android.jar | sort -V | tail -1)"
if [[ -z "$bt" || -z "$android_jar" ]]; then
  echo "error: Android build-tools or platforms are missing under $SDK" >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/src" "$work/classes"

cat >"$work/src/HandoffActivity.java" <<'EOF'
package com.shradhaventures.handoff;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class HandoffActivity extends Activity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    TextView label = new TextView(this);
    label.setText("Directions handoff");
    label.setTextSize(24);
    setContentView(label);
  }
}
EOF

cat >"$work/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.shradhaventures.handoff">
  <application
      android:label="Directions handoff"
      android:theme="@android:style/Theme.DeviceDefault">
    <activity android:name=".HandoffActivity" android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data
            android:scheme="https"
            android:host="www.google.com"
            android:pathPrefix="/maps"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

javac --release 17 -classpath "$android_jar" -d "$work/classes" \
  "$work/src/HandoffActivity.java"
"$bt/d8" --output "$work" "$work/classes/com/shradhaventures/handoff/HandoffActivity.class"
"$bt/aapt2" link \
  -o "$work/unsigned.apk" \
  --manifest "$work/AndroidManifest.xml" \
  -I "$android_jar" \
  --min-sdk-version 30 \
  --target-sdk-version 34 \
  --rename-manifest-package com.shradhaventures.handoff
(
  cd "$work"
  zip -q -j unsigned.apk classes.dex
)
"$bt/zipalign" -f -p 4 "$work/unsigned.apk" "$work/aligned.apk"
keytool -genkeypair \
  -keystore "$work/debug.jks" \
  -storepass android \
  -keypass android \
  -alias androiddebugkey \
  -keyalg RSA \
  -keysize 2048 \
  -validity 1 \
  -dname "CN=Directions Handoff, O=CI, C=US" \
  >/dev/null
"$bt/apksigner" sign \
  --ks "$work/debug.jks" \
  --ks-pass pass:android \
  --key-pass pass:android \
  --out "$work/handoff.apk" \
  "$work/aligned.apk"
adb install -r "$work/handoff.apk"
echo "installed Maps https handoff stub"
