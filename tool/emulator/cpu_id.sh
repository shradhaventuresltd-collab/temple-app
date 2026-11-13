#!/usr/bin/env bash
# Round 4.4.9b: host CPU identity for the AVD snapshot cache key.
# Run 41757362316: six shards restored the same cached snapshot, then zygote
# and native services died with SIGILL (signal 4, 39-43 times each) while
# nine shards on the same key ran fine; a snapshot carries the guest's view
# of the host CPU features, so it is restored only on the CPU it was saved
# on. Prints "<12 hex>" = sha256 of the 'model name' and the sorted, unique
# 'flags' of the first processor. Any difference in either gives a new key
# (no restore-keys fallback): a runner with another CPU misses the cache and
# takes the budgeted create path.
#   cpu_id.sh            hash only
#   cpu_id.sh --describe "model name | <hash>" (for logs)
# EMULATOR_CPUINFO overrides /proc/cpuinfo (self_test). Exit 1 and no output
# when the model name or the flags cannot be read.
set -uo pipefail
f="${EMULATOR_CPUINFO:-/proc/cpuinfo}"
model="$(sed -n 's/^model name[[:space:]]*:[[:space:]]*//p' "$f" 2>/dev/null | head -1)"
flags="$(sed -n 's/^flags[[:space:]]*:[[:space:]]*//p' "$f" 2>/dev/null | head -1 | tr -s ' \t' '\n' | sed '/^$/d' | LC_ALL=C sort -u | tr '\n' ' ')"
[[ -n "$model" && -n "$flags" ]] || exit 1
hash="$(printf 'model=%s\nflags=%s\n' "$model" "$flags" | sha256sum | cut -c1-12)"
if [[ "${1:-}" == --describe ]]; then echo "${model} | cpu ${hash}"; else echo "$hash"; fi
