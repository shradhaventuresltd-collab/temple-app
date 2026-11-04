# Emulator flows

`run_one_flow.sh` sources `tool/emulator/lib/common.sh`, then the flow script.

Flows 17 and 19 call `select_labeled`, `apply_sheet`, `chip_exact`, `recover_sheet`, `clear_named`, and `scroll_chips_until`. Those functions, plus `scroll_chip_bar_at`, `find_filter_chip`, and `re_escape`, live in `tool/emulator/lib/common.sh`. Flow 06 keeps the helpers that only it uses (`remember_applied`, `section_for`, `open_state`, `open_deity`, `open_district`, `open_by_id`, `exercise_filter`).

`16_home_browse.sh` is flow 16 from main. The User Tester flows are 17–20 so they do not reuse that number. Bug Hunter flows 21–28 follow them: district close then another chip, filter combinations, near-me settings, gallery, directions, drawer stack, offline cold start, and small-screen overflow. Flow 29 is the User Tester filter matrix (every chip after every action, including a district selection). It was drafted as 21; that number is already the Bug Hunter district-close flow. The full tier runs it as one flow per entry x chip (`FILTER_MATRIX_PART=<entry>:<chip>`, ids 29a-29f and 30a-30g) plus `30s1`-`30s5` for the 3+ step sequences (`FILTER_MATRIX_PART=seqs:N`, one sequence each, round 4.4.8), and flow 17 as one flow per entry point (17a-17d), on 15 shards (limited by worst-case time, at most 39 min each, today 2139 s = 35.65 min worst case per shard; shard 15 holds 26, 08, 30s3 and 30s4): in run 41373837994 each of the old halves hit the 600 s cap a third of the way in.

## Tiers, shards, and caps

`tool/emulator/plan.sh` is the one list of flows (Confluence page 12353537):

- **smoke**: flows 01, 04, 05, 08, 14, 15 in one job, on every non-draft pull request.
- **full**: every flow in 15 parallel shards (`SHARD_COUNT` in `plan.sh`; worst case 2139 s = 35.65 min per shard including the boot, readiness and unlock, shard 12 1489 s, shards 11 and 15 2069 s, shard 9 2129 s; `plan_e2e_s` gives every end-to-end path, each at most 45 min), on `workflow_dispatch` (which can also pick smoke) and when a release or pre-release is published. The summary prints the tested 40-char SHA as the release gate.
- Flows 11, 23 and 30d-near-me are planned skips (location-dependent) and report `SKIPPED`. `EMULATOR_SKIP_FLOWS=""` runs them.

The `build` job builds the debug APK once and uploads it as the `emulator-apk` artifact. Each emulator job boots the emulator once from the cached AVD snapshot and runs `tool/emulator/run_shard.sh <tier> [shard]`. The first flow installs the APK. Every later flow resets device settings and runs `pm clear` instead of a reboot and reinstall.

Caps: `select_labeled` gives up after 20 s (`EMULATOR_PICKER_GIVEUP_S`; 45 s for the long district and deity lists, `EMULATOR_PICKER_LONG_GIVEUP_S`), each step after 150 s (`EMULATOR_STEP_BUDGET_S`: `ui_dump` refuses to run and the FAIL is tagged `[step timeout]`), each flow after 600 s (`FLOW_BUDGET`), and every workflow step has `timeout-minutes`. `plan.sh need-minutes` gives the worst case that `self_test.sh` checks against the step timeouts.

Local dry run: `EMULATOR_SHARD_DRY_RUN=1 bash tool/emulator/run_shard.sh full 3`.
