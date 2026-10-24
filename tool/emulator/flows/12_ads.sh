#!/usr/bin/env bash
# Flow 12. Banner on the temple list. Debug builds request Google's test unit.
if ! err="$(reach_browse)"; then
  fail_step browse "${err:-could not open the temple list}"
  return 0
fi
pass_step browse

found=0
start="$SECONDS"
while (( SECONDS - start < 35 )); do
  ui_dump || true
  if ui_find --text-contains "Test Ad" || ui_find --class-contains "ads"; then
    found=1
    break
  fi
  ui_fling up || true
  sleep 2
done

adb logcat -d -t 800 > "${LOG_DIR}/${FLOW}-ads.txt" 2>/dev/null || true
if [[ "$found" -eq 1 ]]; then
  pass_step banner
elif grep -q 'ca-app-pub-3940256099942544/6300978111' "${LOG_DIR}/${FLOW}-ads.txt"; then
  if grep -Eiq 'failed to load|Ad failed to load' "${LOG_DIR}/${FLOW}-ads.txt"; then
    fail_step banner "test banner was requested but load failed"
  else
    pass_step banner
  fi
else
  fail_step banner "no Test Ad on screen and logcat had no test banner unit"
fi
