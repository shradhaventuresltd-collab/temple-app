#!/usr/bin/env bash
# Flow 16. Home -> "Browse N temples" -> the filter chips on that list.
# The drawer "All Temples" entry is a different path and is not used here.
launch_app
if ! accept_policy_if_shown; then
  fail_step launch "policy gate or home did not appear"
  return 0
fi
if ! wait_for_home; then
  fail_step launch "home did not appear"
  return 0
fi
pass_step home

open_home_browse() {
  local i width height
  read -r width height < <(ui_screen_size) || return 1
  # Home may already have been flung past the button. Return to the top,
  # then move down until "Browse N temples" is on screen.
  for i in $(seq 1 6); do
    adb_shell_capped 8 input swipe \
      $((width / 2)) $((height * 32 / 100)) \
      $((width / 2)) $((height * 78 / 100)) 180 || {
      echo "open_home_browse: swipe timed out" >&2
      return 1
    }
    sleep 0.2
  done
  for i in $(seq 1 12); do
    if ui_dump && { ui_find --resource-id home-browse-temples || ui_find --text-regex '^Browse .+[Tt]emples?$'; }; then
      if (( UI_CY > 48 && UI_CY < height - 48 )); then
        ui_tap
        sleep 1
        return 0
      fi
    fi
    adb_shell_capped 8 input swipe \
      $((width / 2)) $((height * 68 / 100)) \
      $((width / 2)) $((height * 50 / 100)) 220 || {
      echo "open_home_browse: swipe timed out" >&2
      return 1
    }
    sleep 0.4
  done
  echo "open_home_browse: gave up after 12 scrolls" >&2
  return 1
}

scroll_chip_bar() {
  local width height y
  read -r width height < <(ui_screen_size) || return 1
  y=$((height * 18 / 100))
  if ui_dump && ui_find --resource-id filter-chip-state; then
    y=$UI_CY
  fi
  adb_shell_capped 8 input swipe \
    $((width * 80 / 100)) "$y" \
    $((width * 25 / 100)) "$y" 250 || {
    echo "scroll_chip_bar: swipe timed out" >&2
    return 1
  }
}

if ! open_home_browse; then
  fail_step browse-from-home "Browse temples was not on the home screen"
  return 0
fi
pass_step browse-from-home

if ! err="$(wait_browse_ready)"; then
  fail_step filter-chips "${err:-browse list did not finish loading}"
  return 0
fi

state_ok=0
deity_ok=0
for _try in 1 2 3 4 5 6; do
  ui_dump || true
  if ui_find --resource-id filter-chip-state || ui_find --text-regex '^State$'; then
    state_ok=1
  fi
  if ui_find --text-regex '^Deity$' || ui_find --content-desc "Choose a deity"; then
    deity_ok=1
  fi
  if [[ "$state_ok" -eq 1 && "$deity_ok" -eq 1 ]]; then
    break
  fi
  scroll_chip_bar || true
  sleep 0.4
done
if [[ "$state_ok" -eq 1 && "$deity_ok" -eq 1 ]]; then
  pass_step filter-chips
else
  fail_step filter-chips "state and deity chips were not on the browse bar"
fi
