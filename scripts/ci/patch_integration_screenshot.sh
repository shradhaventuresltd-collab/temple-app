#!/usr/bin/env bash
# Tester-checks only. Home screenshots are larger than the Android binder
# limit, so the Flutter integration_test plugin keeps the PNG and serves it
# in small chunks. Play builds do not run this script.
set -euo pipefail

sdk="${FLUTTER_ROOT:-}"
if [[ -z "$sdk" ]]; then
  sdk="$(flutter sdk-path)"
fi
java_dir="$sdk/packages/integration_test/android/src/main/java/dev/flutter/plugins/integration_test"
shot="$java_dir/FlutterDeviceScreenshot.java"
plugin="$java_dir/IntegrationTestPlugin.java"
if [[ ! -f "$shot" || ! -f "$plugin" ]]; then
  echo "integration_test Java sources missing under $java_dir" >&2
  exit 1
fi

python3 - "$shot" "$plugin" <<'PY'
import pathlib, sys

shot = pathlib.Path(sys.argv[1])
plugin = pathlib.Path(sys.argv[2])
shot_text = shot.read_text()
plugin_text = plugin.read_text()

if "static byte[] lastPng;" not in shot_text:
    needle = "class FlutterDeviceScreenshot {\n"
    if needle not in shot_text:
        raise SystemExit(f"{shot} is missing the FlutterDeviceScreenshot class")
    shot_text = shot_text.replace(
        needle,
        needle
        + "  // Tester-checks: retained when result.success exceeds the binder limit.\n"
        + "  static byte[] lastPng;\n\n",
        1,
    )

lines = shot_text.splitlines(keepends=True)
out = []
patched = shot_text.count("lastPng = png;")
for index, line in enumerate(lines):
    if "result.success(output.toByteArray());" not in line:
        out.append(line)
        continue
    window = "".join(lines[max(0, index - 3) : index])
    if "lastPng = png;" in window:
        out.append(line)
        continue
    indent = line[: len(line) - len(line.lstrip(" "))]
    newline = "\n" if line.endswith("\n") else ""
    out.append(f"{indent}byte[] png = output.toByteArray();{newline}")
    out.append(f"{indent}lastPng = png;{newline}")
    # Binder transactions above ~1MB kill the app. Large frames are read back
    # in chunks; a null success is the signal to do that.
    out.append(f"{indent}if (png.length > 400000) {{{newline}")
    out.append(f"{indent}  result.success(null);{newline}")
    out.append(f"{indent}}} else {{{newline}")
    out.append(f"{indent}  result.success(png);{newline}")
    out.append(f"{indent}}}{newline}")
    patched += 1
shot_text = "".join(out)
if patched < 2:
    raise SystemExit(f"{shot} expected 2 PNG success sites, found {patched}")
shot.write_text(shot_text)

if "import java.util.Arrays;" not in plugin_text:
    needle = "import java.io.IOException;\n"
    if needle not in plugin_text:
        raise SystemExit(f"{plugin} is missing the IOException import")
    plugin_text = plugin_text.replace(needle, needle + "import java.util.Arrays;\n", 1)

if 'case "screenshotLength":' not in plugin_text:
    needle = "      default:\n"
    insert = """      case "screenshotLength":
        result.success(
            FlutterDeviceScreenshot.lastPng == null
                ? 0
                : FlutterDeviceScreenshot.lastPng.length);
        return;
      case "readScreenshotChunk": {
        final byte[] png = FlutterDeviceScreenshot.lastPng;
        if (png == null) {
          result.error("no screenshot", "lastPng is null", null);
          return;
        }
        final Integer offsetArg = call.argument("offset");
        final Integer lengthArg = call.argument("length");
        final int offset = offsetArg == null ? 0 : offsetArg;
        final int length = lengthArg == null ? 0 : lengthArg;
        if (offset < 0 || length < 0 || offset > png.length) {
          result.error("bad chunk", "offset " + offset + " length " + length, null);
          return;
        }
        final int end = Math.min(png.length, offset + Math.min(length, 200000));
        result.success(Arrays.copyOfRange(png, offset, end));
        return;
      }
      default:
"""
    if needle not in plugin_text:
        raise SystemExit(f"{plugin} is missing the default method branch")
    plugin_text = plugin_text.replace(needle, insert, 1)
plugin.write_text(plugin_text)
print(f"patched integration_test screenshots in {shot.parent}")
PY
