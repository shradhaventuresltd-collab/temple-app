# Emulator flows

`run_one_flow.sh` sources `tool/emulator/lib/common.sh`, then the flow script.

Flows 17 and 19 call `select_labeled`, `apply_sheet`, `chip_exact`, `recover_sheet`, `clear_named`, and `scroll_chips_until`. Those functions, plus `scroll_chip_bar_at`, `find_filter_chip`, and `re_escape`, live in `tool/emulator/lib/common.sh`. Flow 06 keeps the helpers that only it uses (`remember_applied`, `section_for`, `open_state`, `open_deity`, `open_district`, `open_by_id`, `exercise_filter`).

`16_home_browse.sh` is flow 16 from main. The User Tester flows are 17–20 so they do not reuse that number. Bug Hunter flows 21–28 follow them: district close then another chip, filter combinations, near-me settings, gallery, directions, drawer stack, offline cold start, and small-screen overflow. Flow 29 is the User Tester filter matrix (every chip after every action, including a district selection). It was drafted as 21; that number is already the Bug Hunter district-close flow.

## Tiers, shards, and caps

`tool/emulator/plan.sh` is the one list of flows (Confluence page 12353537):

- **smoke**: flows 01, 04, 05, 08, 14, 15 in one job, on every non-draft pull request.
- **full**: every flow in 6 parallel shards, on merge to main, nightly (02:00 IST), and when a pre-release is published. `workflow_dispatch` picks either tier.
- Flows 11 and 23 (and 30d once the split matrix lands) are skipped as location-dependent and report `SKIPPED`. `EMULATOR_SKIP_FLOWS=""` runs them.

The `build` job builds the debug APK once and uploads it as the `emulator-apk` artifact. Each emulator job boots the emulator once from the cached AVD snapshot and runs `tool/emulator/run_shard.sh <tier> [shard]`. The first flow installs the APK. Every later flow resets device settings and runs `pm clear` instead of a reboot and reinstall.

Caps: `select_labeled` gives up after 20 s (`EMULATOR_PICKER_GIVEUP_S`), each flow after 600 s (`FLOW_BUDGET`), and every workflow step has `timeout-minutes`. `plan.sh need-minutes` gives the worst case that `self_test.sh` checks against the step timeouts.

Local dry run: `EMULATOR_SHARD_DRY_RUN=1 bash tool/emulator/run_shard.sh full 3`.
