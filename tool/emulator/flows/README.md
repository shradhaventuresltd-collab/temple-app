# Emulator flows

`run_one_flow.sh` sources `tool/emulator/lib/common.sh`, then the flow script.

Flows 17 and 19 call `select_labeled`, `apply_sheet`, `chip_exact`, `recover_sheet`, `clear_named`, and `scroll_chips_until`. Those functions, plus `scroll_chip_bar_at`, `find_filter_chip`, and `re_escape`, live in `tool/emulator/lib/common.sh`. Flow 06 keeps the helpers that only it uses (`remember_applied`, `section_for`, `open_state`, `open_deity`, `open_district`, `open_by_id`, `exercise_filter`).

`16_home_browse.sh` is flow 16 from main. The User Tester flows are 17–20 so they do not reuse that number. Bug Hunter flows 21–28 follow them: district close then another chip, filter combinations, near-me settings, gallery, directions, drawer stack, offline cold start, and small-screen overflow.
