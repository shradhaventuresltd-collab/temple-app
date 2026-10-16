#!/usr/bin/env bash
# Tester-checks only. The API 34 google_atd emulator uses SwiftShader, and
# Impeller does not present frames there. Profile smoke already sets
# EnableImpeller false. Play release checkouts do not run this script, so
# the committed manifest stays on Impeller.
set -euo pipefail

manifest="${1:-android/app/src/main/AndroidManifest.xml}"
python3 - "$manifest" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
marker = 'android:name="io.flutter.embedding.android.EnableImpeller"'
if marker in text:
    raise SystemExit(f"{path} already sets EnableImpeller")
needle = '''        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />'''
insert = needle + '''
        <!-- Tester-checks emulator APK only. This script is not the Play build. -->
        <meta-data
            android:name="io.flutter.embedding.android.EnableImpeller"
            android:value="false" />'''
if needle not in text:
    raise SystemExit(f"{path} is missing the flutterEmbedding meta-data")
path.write_text(text.replace(needle, insert, 1))
print(f"disabled Impeller in {path}")
PY
