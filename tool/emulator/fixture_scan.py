#!/usr/bin/env python3
"""Fail if any fixture under the given dirs holds an identifier that must
not be in this public repo (round 4.4.1, Sanu's rule; round 4.4.2 nits).

Checked:
- ad-click ids (gclid, gbraid, wbraid, dclid, fbclid, msclkid) unless
  REDACTED, after =, %3D, %253D or &#61;
- email addresses (@, %40 or &#64;)
- OAuth tokens (ya29., 1//0 refresh tokens), Google API keys (AIza...),
  JWTs, GitHub/Slack tokens, private keys
- device ids: android_id, advertising ids (UUID; the all-zero opt-out id is
  allowed), ro.serialno / ro.boot.serialno values, adb serials, IMEIs
  (after an imei keyword, hyphenated 2-6-6-1, or a bare 15-digit number
  that passes the Luhn check)
The generic emulator-NNNN serial names a local adb port, not a device, so
it is allowed.

Usage: fixture_scan.py DIR...  Prints "path:line: kind: excerpt" per hit;
exit 1 on any hit.
"""
import os
import re
import sys

EQ = r"(?:=|%3D|%253D|&#61;|&#x3[dD];)"
PATTERNS = [
    ("ad-click id", re.compile(r"(?i)(gclid|gbraid|wbraid|dclid|fbclid|msclkid)" + EQ + r"(?!REDACTED\b)[A-Za-z0-9_-]{6,}")),
    ("email", re.compile(r"[A-Za-z0-9._%+-]+(?:@|%40|&#64;)[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}")),
    ("oauth token", re.compile(r"\bya29\.[A-Za-z0-9_-]{10,}|\b1//0[A-Za-z0-9_-]{20,}")),
    ("api key", re.compile(r"\bAIza[0-9A-Za-z_-]{30,}")),
    ("jwt", re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}")),
    ("vcs/chat token", re.compile(r"\b(ghp_|gho_|ghs_|github_pat_|xox[abpors]-)[A-Za-z0-9_-]{16,}")),
    ("private key", re.compile(r"BEGIN [A-Z ]*PRIVATE KEY")),
    ("android_id", re.compile(r"(?i)android_id\W{0,6}[0-9a-f]{16}\b")),
    ("advertising id", re.compile(r"(?i)(advertising_?id|adid|gaid)\W{0,8}(?!0{8}-0{4})[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")),
    ("serial", re.compile(r"(?i)\bro\.(boot\.)?serialno\W{1,6}(?!emulator-\d{4}\b)[A-Za-z0-9]{6,}")),
    ("adb serial", re.compile(r"(?m)^(?!emulator-\d{4}\b)[A-Za-z0-9]{8,20}\t(device|offline|unauthorized)\b")),
    ("imei", re.compile(r"(?i)imei\W{0,6}\d{2}[- ]?\d{6}[- ]?\d{6}[- ]?\d\b|\b\d{2}-\d{6}-\d{6}-\d\b")),
]


def luhn_ok(digits):
    total = 0
    for i, ch in enumerate(reversed(digits)):
        d = int(ch)
        if i % 2:
            d *= 2
            if d > 9:
                d -= 9
        total += d
    return total % 10 == 0


# A bare 15-digit number is only IMEI-like when it passes the Luhn check
# (IMEIs carry a Luhn digit); timestamps, bounds and counts are left alone.
BARE15 = re.compile(r"(?<![\d.\[,])\d{15}(?![\d.\],])")


def scan(paths):
    hits = 0
    for top in paths:
        for root, _dirs, files in os.walk(top):
            for name in sorted(files):
                p = os.path.join(root, name)
                try:
                    text = open(p, encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                found = [(k, m) for k, rx in PATTERNS for m in rx.finditer(text)]
                found += [("imei-like (Luhn)", m) for m in BARE15.finditer(text) if luhn_ok(m.group(0))]
                for kind, m in found:
                    if True:
                        line = text.count("\n", 0, m.start()) + 1
                        print(f"{p}:{line}: {kind}: {m.group(0)[:60]}")
                        hits += 1
    return hits


if __name__ == "__main__":
    n = scan(sys.argv[1:] or ["tool/emulator/testdata"])
    print(f"fixture scan: {n} hit(s)")
    raise SystemExit(1 if n else 0)
