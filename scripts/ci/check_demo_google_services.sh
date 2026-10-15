#!/usr/bin/env bash
# Confirm google-services.json can build com.shradhaventures.temple.demo.
# Does not print mobilesdk_app_id or api keys.
#
# The Play client must stay. The demo client is added by Deployer from the
# Firebase console download. This script does not invent either value.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
json="${1:-$root/android/app/google-services.json}"

python3 - "$json" <<'PY'
import json
import sys

path = sys.argv[1]
play_package = "com.shradhaventures.temple"
demo_package = "com.shradhaventures.temple.demo"

try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    sys.stderr.write("error: google-services.json is missing or is not JSON\n")
    sys.exit(1)

clients = data.get("client")
if not isinstance(clients, list):
    sys.stderr.write("error: google-services.json has no client array\n")
    sys.exit(1)

def package_name(client):
    info = client.get("client_info") if isinstance(client, dict) else None
    android = info.get("android_client_info") if isinstance(info, dict) else None
    if not isinstance(android, dict):
        return ""
    return android.get("package_name") or ""

play = any(package_name(client) == play_package for client in clients)
demo = next((client for client in clients if package_name(client) == demo_package), None)

if not play:
    sys.stderr.write(
        "error: google-services.json is missing the Play client for "
        f"{play_package}. Do not remove it when adding the demo client.\n"
    )
    sys.exit(1)

if demo is None:
    sys.stderr.write(
        "error: google-services.json has no client for "
        f"{demo_package}.\n"
        "\n"
        "The demo application id is applied only when DEMO_APP_ID_SUFFIX is set.\n"
        "The only remaining Firebase config step is to add that client:\n"
        "\n"
        "1. In Firebase project temple-directory-india, register an Android\n"
        "   app with package name com.shradhaventures.temple.demo.\n"
        "2. Download the google-services.json Firebase generates for it.\n"
        "3. Copy that file's client object into the client array of\n"
        "   android/app/google-services.json. Leave the Play client\n"
        "   (package_name com.shradhaventures.temple) in place.\n"
        "4. The pasted client must include the console values, not invented ones:\n"
        "   client_info.mobilesdk_app_id\n"
        "   client_info.android_client_info.package_name = "
        "com.shradhaventures.temple.demo\n"
        "   api_key[0].current_key\n"
        "5. Set the GitHub secret FIREBASE_ANDROID_APP_ID to that same\n"
        "   mobilesdk_app_id.\n"
        "\n"
        "No other code change is required after that client is added.\n"
    )
    sys.exit(1)

info = demo.get("client_info") if isinstance(demo, dict) else None
app_id = ""
if isinstance(info, dict):
    app_id = (info.get("mobilesdk_app_id") or "").strip()
keys = demo.get("api_key") if isinstance(demo, dict) else None
current = ""
if isinstance(keys, list) and keys and isinstance(keys[0], dict):
    current = (keys[0].get("current_key") or "").strip()
placeholder = ("REPLACE", "TODO", "CHANGEME", "your-")
if (
    not app_id
    or not current
    or any(app_id.startswith(token) or current.startswith(token) for token in placeholder)
):
    sys.stderr.write(
        "error: the .demo client is missing a real mobilesdk_app_id or "
        "api_key.current_key from the Firebase console download.\n"
    )
    sys.exit(1)

sys.stdout.write("ok: demo google-services client is present\n")
PY
