#!/usr/bin/env python3
"""Host-side model of the filter sheet for self_test (no device).

Geometry is the 320x640 AVD from run 40916686359: the option scroller is
[0,251][320,569], chips are 32px tall with 8px gaps, one section after
another in the app's order (tapped section, then state, district, deity).
Labels come from run40992967143/catalog.json (real dump labels).

A fast drag (<=150ms) is a fling: it moves MOMENTUM times the finger's
travel, spread over the next dumps, so a dump taken right after a fling
sees a list that is still moving. A slow drag moves exactly the finger's
travel. Both stop at the ends of the list.

  sheet_sim.py init STATE --focus KIND [--seed N] [--momentum M] [--pad-deity N] [--drop NAME]
  sheet_sim.py dump STATE OUT        write a uiautomator-style dump (one tick)
  sheet_sim.py swipe STATE X1 Y1 X2 Y2 MS
  sheet_sim.py at STATE X Y          label of the chip under the point
"""
from __future__ import annotations

import json
import os
import random
import sys
from xml.sax.saxutils import quoteattr

HERE = os.path.dirname(os.path.abspath(__file__))
TOP, BOTTOM = 251, 569
ROW, GAP = 32, 8
ORDER = ["state", "district", "deity"]
ANY = {"state": "Any state  992", "district": "All districts  992", "deity": "Any deity  992"}


def build(focus: str, pad: int, drop: list[str]) -> list[dict]:
    # run40992967143/catalog.json adds the P-R deities and the Vishnu
    # (...) chips that run's dumps caught; SHEET_SIM_CATALOG picks another.
    path = os.environ.get("SHEET_SIM_CATALOG") or os.path.join(HERE, "run40992967143", "catalog.json")
    cat = json.load(open(path, encoding="utf-8"))
    rows = []
    y = 4
    for kind in [focus] + [k for k in ORDER if k != focus]:
        rows.append({"kind": kind, "name": "", "label": kind.upper(), "y": y, "h": 16})
        y += 16 + GAP
        names = dict(cat[kind])
        if kind == "deity" and pad:
            # Fill to a realistic size (~600 deities in the live directory)
            # with names that sort between the real ones.
            real = list(names)
            i = 0
            while len(names) < pad:
                base = real[i % len(real)]
                filler = f"{base} (form {i // len(real) + 1:03d})"
                names[filler] = f"{filler}  1"
                i += 1
        items = [("any", ANY[kind])] + sorted(
            ((n, l) for n, l in names.items() if n not in drop),
            key=lambda kv: kv[0].encode("utf-16-be"),
        )
        for name, label in items:
            rows.append({"kind": kind, "name": name, "label": label, "y": y, "h": ROW})
            y += ROW + GAP
        y += 18
    return rows


def load(path):
    return json.load(open(path, encoding="utf-8"))


def save(path, st):
    json.dump(st, open(path, "w", encoding="utf-8"))


def content_height(st):
    last = st["rows"][-1]
    return last["y"] + last["h"] + 8


def clamp(st):
    hi = max(0, content_height(st) - (BOTTOM - TOP))
    st["off"] = max(0, min(hi, st["off"]))
    if st["off"] in (0, hi):
        st["pending"] = [0 for _ in st["pending"]]


def main(argv):
    cmd, path = argv[1], argv[2]
    if cmd == "init":
        args = argv[3:]
        opt = {"--focus": "state", "--seed": "1", "--momentum": "", "--pad-deity": "0"}
        drop = []
        i = 0
        while i < len(args):
            if args[i] == "--drop":
                drop.append(args[i + 1])
            else:
                opt[args[i]] = args[i + 1]
            i += 2
        rng = random.Random(int(opt["--seed"]))
        st = {
            "rows": build(opt["--focus"], int(opt["--pad-deity"]), drop),
            "off": 0,
            "pending": [],
            "momentum": float(opt["--momentum"]) if opt["--momentum"] else None,
            "seed": int(opt["--seed"]),
            "flings": 0,
            "rng": rng.random(),
        }
        save(path, st)
        return 0
    st = load(path)
    if cmd == "dump":
        if st["pending"]:
            st["off"] += st["pending"].pop(0)
            clamp(st)
        out = ['<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>',
               '<hierarchy rotation="0">',
               '<node index="0" text="" resource-id="android:id/content" class="android.widget.FrameLayout" package="com.shradhaventures.temple" content-desc="" clickable="false" scrollable="false" bounds="[0,0][320,640]">',
               '<node index="0" text="" resource-id="" class="android.view.View" package="com.shradhaventures.temple" content-desc="Filters" clickable="false" scrollable="false" bounds="[48,167][264,198]" />',
               '<node index="1" text="" resource-id="" class="android.widget.Button" package="com.shradhaventures.temple" content-desc="Close filters" clickable="true" scrollable="false" bounds="[264,159][312,207]" />',
               '<node index="2" text="" resource-id="" class="android.widget.ScrollView" package="com.shradhaventures.temple" content-desc="" clickable="false" scrollable="true" bounds="[0,251][320,569]">']
        for r in st["rows"]:
            y1 = TOP + r["y"] - st["off"]
            y2 = y1 + r["h"]
            if y2 <= TOP or y1 >= BOTTOM:
                continue
            y1, y2 = max(y1, TOP), min(y2, BOTTOM)
            if r["name"]:
                rid = f"filter-option-{r['kind']}-{r['name']}"[:80]
                out.append(f'<node index="0" text="" resource-id={quoteattr(rid)} class="android.widget.Button" package="com.shradhaventures.temple" content-desc={quoteattr(r["label"])} clickable="true" scrollable="false" bounds="[16,{y1}][252,{y2}]" />')
            else:
                out.append(f'<node index="0" text="" resource-id="" class="android.view.View" package="com.shradhaventures.temple" content-desc={quoteattr(r["label"])} clickable="false" scrollable="false" bounds="[16,{y1}][304,{y2}]" />')
        out += ['</node>',
                '<node index="3" text="" resource-id="filter-sheet-clear" class="android.widget.Button" package="com.shradhaventures.temple" content-desc="" clickable="false" scrollable="false" bounds="[16,579][80,627]" />',
                '<node index="4" text="" resource-id="" class="android.widget.Button" package="com.shradhaventures.temple" content-desc="Show 992 temples" clickable="true" scrollable="false" bounds="[88,577][304,628]" />',
                '</node>', '</hierarchy>']
        open(argv[3], "w", encoding="utf-8").write("\n".join(out))
        save(path, st)
        return 0
    if cmd == "swipe":
        x1, y1, x2, y2, ms = (int(v) for v in argv[3:8])
        travel = y1 - y2  # finger up = content moves up = offset grows
        if ms <= 150:
            st["flings"] += 1
            rng = random.Random(st["seed"] * 1000 + st["flings"])
            m = st["momentum"] or rng.uniform(4, 14)
            total = int(travel * m)
            st["pending"] = [int(total * f) for f in (0.4, 0.3, 0.2, 0.1)]
            st["off"] += st["pending"].pop(0)
        else:
            st["pending"] = []
            st["off"] += travel
        clamp(st)
        save(path, st)
        return 0
    if cmd == "at":
        x, y = int(argv[3]), int(argv[4])
        for r in st["rows"]:
            y1 = TOP + r["y"] - st["off"]
            if r["name"] and TOP <= y < BOTTOM and y1 <= y < y1 + r["h"]:
                print(r["label"])
                return 0
        print("")
        return 1
    print(f"unknown command {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
