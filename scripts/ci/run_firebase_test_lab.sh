#!/usr/bin/env bash
# One Firebase Test Lab Robo matrix for the Play package.
# preflight: secret, APIs, IAM, and device choice. No device run.
# run: release APK from the main checkout, then one matrix. No retry.
set -euo pipefail

phase="${1:-}"
PROJECT=temple-directory-india
REQUIRED_SHA=5d215d8599e68947f8462ea7fb8a3bc7f4b0bc76
APP_DIR="${APP_DIR:-app}"
HARNESS_DIR="${HARNESS_DIR:-harness}"
SECRET_NAME=FIREBASE_APP_DISTRIBUTION_SA_JSON
DOCUMENTED_ROLE=roles/firebaseappdistro.admin
REQUIRED_ROLE=roles/cloudtestservice.testAdmin
TESTING_API=testing.googleapis.com
TOOLRESULTS_API=toolresults.googleapis.com

stop_missing() {
  {
    echo "TEST_LAB_PREFLIGHT_FAIL"
    echo "project=${PROJECT}"
    echo "secret=${SECRET_NAME}"
    echo "documented_role=${DOCUMENTED_ROLE}"
    echo "required_role=${REQUIRED_ROLE}"
    echo "required_api=${TESTING_API}"
    echo "required_api=${TOOLRESULTS_API}"
    while [[ $# -gt 0 ]]; do
      echo "$1"
      shift
    done
    echo "No Test Lab device run was started."
  } >&2
  exit 1
}

install_gcloud() {
  if [[ -x /tmp/google-cloud-sdk/bin/gcloud ]]; then
    export PATH="/tmp/google-cloud-sdk/bin:${PATH}"
    hash -r
    return
  fi
  if command -v gcloud >/dev/null 2>&1; then
    return
  fi
  curl -fsSL https://sdk.cloud.google.com -o /tmp/install-gcloud.sh
  bash /tmp/install-gcloud.sh --disable-prompts --install-dir=/tmp
  export PATH="/tmp/google-cloud-sdk/bin:${PATH}"
  hash -r
}

activate_sa() {
  local sa
  if [[ -z "${FIREBASE_APP_DISTRIBUTION_SA_JSON:-}" ]]; then
    stop_missing "detail=secret ${SECRET_NAME} is empty or not set on this repository"
  fi
  sa="${RUNNER_TEMP:-/tmp}/test-lab-sa.json"
  umask 077
  printf '%s' "$FIREBASE_APP_DISTRIBUTION_SA_JSON" >"$sa"
  chmod 600 "$sa"
  # shellcheck disable=SC2064
  trap "rm -f -- '$sa'" EXIT
  if ! SA_EMAIL="$(python3 - "$sa" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    sys.exit(2)
if not isinstance(data, dict) or data.get("type") != "service_account":
    sys.exit(3)
email = data.get("client_email") or ""
if "@" not in email or "private_key" not in data:
    sys.exit(3)
print(email)
PY
  )"; then
    stop_missing "detail=secret ${SECRET_NAME} is not a service account JSON (the key was not printed)"
  fi
  echo "service_account=${SA_EMAIL}"
  install_gcloud
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  if ! gcloud auth activate-service-account "$SA_EMAIL" --key-file="$sa" --project="$PROJECT" >/dev/null; then
    stop_missing "service_account=${SA_EMAIL}" "detail=gcloud auth activate-service-account failed"
  fi
  gcloud config set project "$PROJECT" >/dev/null
}

assert_apis_and_role() {
  local email="$1"
  local services roles err
  err="$(mktemp)"
  if ! services="$(gcloud services list --enabled --project="$PROJECT" --format='value(config.name)' 2>"$err")"; then
    if grep -Eq 'PERMISSION_DENIED|403|permission' "$err"; then
      stop_missing \
        "service_account=${email}" \
        "detail=cannot list enabled APIs (serviceusage.services.list denied). ${DOCUMENTED_ROLE} does not include Cloud Testing."
    fi
    stop_missing \
      "service_account=${email}" \
      "detail=gcloud services list failed: $(tr '\n' ' ' <"$err")"
  fi
  if ! grep -q "$TESTING_API" <<<"$services"; then
    stop_missing \
      "service_account=${email}" \
      "missing_api=${TESTING_API}" \
      "detail=Cloud Testing API is not enabled on ${PROJECT}"
  fi
  if ! grep -q "$TOOLRESULTS_API" <<<"$services"; then
    stop_missing \
      "service_account=${email}" \
      "missing_api=${TOOLRESULTS_API}" \
      "detail=Cloud Tool Results API is not enabled on ${PROJECT}"
  fi
  if ! roles="$(gcloud projects get-iam-policy "$PROJECT" \
    --flatten='bindings[].members' \
    --filter="bindings.members:serviceAccount:${email}" \
    --format='value(bindings.role)' 2>"$err")"; then
    if grep -Eq 'PERMISSION_DENIED|403|permission' "$err"; then
      stop_missing \
        "service_account=${email}" \
        "detail=cannot read IAM policy (resourcemanager.projects.getIamPolicy denied). Documented role is ${DOCUMENTED_ROLE}; Test Lab needs ${REQUIRED_ROLE}."
    fi
    stop_missing \
      "service_account=${email}" \
      "detail=get-iam-policy failed: $(tr '\n' ' ' <"$err")"
  fi
  echo "roles=${roles//$'\n'/,}"
  if ! grep -Eq '^(roles/cloudtestservice\.testAdmin|roles/editor|roles/owner)$' <<<"$roles"; then
    stop_missing \
      "service_account=${email}" \
      "roles_found=${roles//$'\n'/,}" \
      "missing_role=${REQUIRED_ROLE}" \
      "detail=service account does not have Firebase Test Lab Admin, Editor, or Owner"
  fi
  rm -f "$err"
}

choose_devices() {
  local catalog picked
  catalog="$(mktemp)"
  if ! gcloud firebase test android models list --format=json --project="$PROJECT" >"$catalog"; then
    stop_missing "detail=could not list Test Lab device models (Cloud Testing API or ${REQUIRED_ROLE})"
  fi
  picker_err="$(mktemp)"
  if ! picked="$(python3 - "$catalog" 2>"$picker_err" <<'PY'
import json, sys
raw = json.load(open(sys.argv[1], encoding="utf-8"))
if isinstance(raw, dict):
    models = raw.get("models") or raw.get("androidModels") or []
else:
    models = raw

def field(model, *names):
    for name in names:
        value = model.get(name)
        if value:
            return str(value)
    return ""

def versions(model):
    found = []
    for value in model.get("supportedVersionIds") or []:
        text = str(value)
        if text.isdigit():
            found.append(int(text))
    return sorted(found)

def dp_width(model):
    try:
        width = float(model.get("screenX") or 0)
        density = float(model.get("screenDensity") or 0)
    except (TypeError, ValueError):
        return None
    if width <= 0 or density <= 0:
        return None
    return width * 160.0 / density

phones = []
for model in models:
    if field(model, "form").upper() != "PHYSICAL":
        continue
    if field(model, "formFactor").upper() not in ("", "PHONE"):
        continue
    if not versions(model):
        continue
    phones.append(model)

def prefer_pixel(model):
    name = field(model, "name", "id").lower()
    if "pixel" not in name or "tablet" in name or "fold" in name:
        return None
    rank = 50
    for needle, score in (("pixel 8", 0), ("pixel 7", 1), ("pixel 6", 2), ("pixel 5", 3)):
        if needle in name:
            rank = score
            break
    return (rank, -versions(model)[-1], name)

pixels = [(prefer_pixel(model), model) for model in phones]
pixels = [(rank, model) for rank, model in pixels if rank is not None]
if not pixels:
    names = ", ".join(sorted(field(model, "name", "id") for model in phones)) or "(none)"
    print(f"NO_PIXEL physical phones: {names}", file=sys.stderr)
    sys.exit(4)
pixels.sort(key=lambda item: item[0])
pixel = pixels[0][1]

def small_family(model):
    name = field(model, "name", "id", "codename").lower()
    maker = field(model, "manufacturer", "brand").lower()
    samsung_a = "samsung" in maker and (
        name.startswith("galaxy a") or " galaxy a" in f" {name}"
    )
    redmi = "redmi" in name or ("xiaomi" in maker and "redmi" in name)
    return samsung_a or redmi

smalls = [model for model in phones if small_family(model)]
if not smalls:
    names = ", ".join(sorted(field(model, "manufacturer", "brand") + " " + field(model, "name", "id") for model in phones))
    print(f"NO_SMALL_DEVICE no physical Samsung Galaxy A or Redmi. Catalog: {names}", file=sys.stderr)
    sys.exit(5)

def small_key(model):
    width = dp_width(model)
    distance = abs(width - 360.0) if width is not None else 10000.0
    return (distance, -versions(model)[-1])

smalls.sort(key=small_key)
small = smalls[0]

def emit(prefix, model):
    width = dp_width(model)
    width_text = f"{width:.0f}" if width is not None else "unknown"
    print(f"{prefix}_model={field(model, 'id')}")
    print(f"{prefix}_version={versions(model)[-1]}")
    print(f"{prefix}_name={field(model, 'name', 'id')}")
    print(f"{prefix}_dp={width_text}")
    print(f"{prefix}_maker={field(model, 'manufacturer', 'brand')}")

emit("pixel", pixel)
emit("small", small)
PY
  )"; then
    detail="$(tr '\n' ' ' <"$picker_err")"
    stop_missing "detail=${detail:-Test Lab catalog did not yield a Pixel and a Samsung Galaxy A or Redmi phone}"
  fi
  rm -f "$picker_err"
  printf '%s\n' "$picked"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    printf '%s\n' "$picked" >>"$GITHUB_ENV"
  fi
  rm -f "$catalog"
}

case "$phase" in
  preflight)
    activate_sa
    assert_apis_and_role "$SA_EMAIL"
    choose_devices
    echo "TEST_LAB_PREFLIGHT_OK"
    ;;
  run)
    activate_sa
    app="${APP_DIR}"
    sha="$(git -C "$app" rev-parse HEAD)"
    echo "apk_source=${sha}"
    status="$(gh api "repos/${GITHUB_REPOSITORY}/compare/${REQUIRED_SHA}...${sha}" --jq .status)"
    if [[ "$status" != "ahead" && "$status" != "identical" ]]; then
      echo "error: ${sha} is not ${REQUIRED_SHA} or a descendant (compare status ${status})" >&2
      exit 1
    fi
    for var in pixel_model pixel_version small_model small_version; do
      if [[ -z "${!var:-}" ]]; then
        echo "error: ${var} was not set by preflight" >&2
        exit 1
      fi
    done
    bash "${app}/scripts/ci/free_runner_disk.sh"
    (
      cd "$app"
      sed -i 's/^org\.gradle\.jvmargs=.*/org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=1g -XX:ReservedCodeCacheSize=256m -Dfile.encoding=UTF-8/' android/gradle.properties
      grep -q '^kotlin.daemon.jvmargs=' android/gradle.properties \
        || echo 'kotlin.daemon.jvmargs=-Xmx1g' >> android/gradle.properties
      keytool -genkeypair -keystore android/ci-test-lab-keystore.jks \
        -storepass android -keypass android -alias upload \
        -keyalg RSA -keysize 2048 -validity 1 \
        -dname "CN=CI Test Lab, OU=CI, O=Shradha Ventures, L=Bengaluru, ST=KA, C=IN"
      cat > android/key.properties <<'EOF'
storePassword=android
keyPassword=android
keyAlias=upload
storeFile=../ci-test-lab-keystore.jks
EOF
      flutter pub get
      flutter build apk --release --target-platform android-arm,android-arm64
    )
    apk="${app}/build/app/outputs/flutter-apk/app-release.apk"
    if [[ ! -f "$apk" ]]; then
      echo "error: release apk was not produced" >&2
      exit 1
    fi
    sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/usr/local/lib/android/sdk}}"
    aapt="$(find "$sdk" -type f -name aapt | sort | tail -n 1)"
    if [[ -z "$aapt" ]]; then
      echo "error: aapt not found under ${sdk}" >&2
      exit 1
    fi
    package="$("$aapt" dump badging "$apk" | awk -F"'" '/^package: name=/{print $2; exit}')"
    echo "package=${package}"
    if [[ "$package" != "com.shradhaventures.temple" ]]; then
      echo "error: package is ${package}, expected com.shradhaventures.temple" >&2
      exit 1
    fi
    robo="${HARNESS_DIR}/scripts/ci/firebase_test_lab_robo.json"
    echo "TEST_LAB_MATRIX_START pixel=${pixel_model}/${pixel_version} small=${small_model}/${small_version}"
    set +e
    gcloud firebase test android run \
      --type=robo \
      --project="$PROJECT" \
      --app="$apk" \
      --robo-script="$robo" \
      --timeout=12m \
      --num-flaky-test-attempts=0 \
      --record-video \
      --results-history-name="temple-main-physical" \
      --device "model=${pixel_model},version=${pixel_version},locale=en,orientation=portrait" \
      --device "model=${small_model},version=${small_version},locale=en,orientation=portrait" \
      | tee /tmp/test-lab-gcloud.txt
    gcloud_status=${PIPESTATUS[0]}
    set -e
    echo "TEST_LAB_GCLOUD_EXIT=${gcloud_status}"
    python3 - /tmp/test-lab-gcloud.txt <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text(errors="replace")
urls = re.findall(r"https://console\.firebase\.google\.com/\S+", text)
gcs = re.findall(r"gs://\S+", text)
print("TEST_LAB_CONSOLE")
for url in dict.fromkeys(urls):
    print(url.rstrip("].)"))
print("TEST_LAB_GCS")
for url in dict.fromkeys(gcs):
    print(url.rstrip("].)"))
if not urls and not gcs:
    print("TEST_LAB_LINKS_MISSING")
PY
    exit "$gcloud_status"
    ;;
  *)
    echo "usage: run_firebase_test_lab.sh preflight|run" >&2
    exit 2
    ;;
esac
