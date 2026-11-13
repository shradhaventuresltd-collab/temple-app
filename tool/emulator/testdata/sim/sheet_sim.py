#!/usr/bin/env python3
"""Deterministic filter-sheet simulator for seek dry-runs (no device).

State lives in a JSON file. Commands:
  init STATE.json ORDER SCOPE   ORDER e.g. deity,state,district; SCOPE all|tn
  dump STATE.json               print a uiautomator-like XML of the sheet
  swipe STATE.json X Y1 X Y2 MS apply one `input swipe`
  tap STATE.json X Y            print the option label under (X, Y)

Geometry follows the 320x640 AVD: option scroller y 251-569, one option
row 40 px, section header 30 px. A swipe faster than 400 ms is a fling:
the list keeps moving by SIM_MOMENTUM (5) x the finger travel (calibrated: 45s of all-India Shiva flings ends at "R", as in run 41391038302 29c), released over the next
three dumps (55%, 85%, 100%), so a dump right after a fling can see a
moving list (what seek_settle waits out). Slower swipes move by the
finger travel only. The lists are synthetic but sized like the live
ones: 36 states, ~640 districts, ~600 deities all-India (Shiva near 85%
of the deity list, as in run 41391038302's 29c dumps at "Ra..Ri.."),
32 deities when scoped to Tamil Nadu (Shiva 12th).
"""
import json, os, string, sys

BAND_TOP, BAND_BOT, ROW, HDR = 251, 569, 40, 30
MOMENTUM = float(os.environ.get("SIM_MOMENTUM", "5"))


def names(kind, scope):
    if kind == "state":
        base = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Delhi", "Goa",
                "Gujarat", "Haryana", "Himachal Pradesh", "Jammu And Kashmir", "Jharkhand", "Karnataka",
                "Kerala", "Ladakh", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
                "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
                "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Andaman", "Chandigarh",
                "Dadra", "Lakshadweep"]
        return sorted(base) if scope == "all" else ["Tamil Nadu"]
    if kind == "district":
        if scope == "tn":
            return sorted(["Ariyalur", "Chennai", "Coimbatore", "Cuddalore", "Dindigul", "Erode", "Kanchipuram",
                           "Kanyakumari", "Karur", "Madurai", "Nagapattinam", "Namakkal", "Pudukkottai",
                           "Ramanathapuram", "Salem", "Sivaganga", "Thanjavur", "Theni", "Thoothukudi",
                           "Tiruchirappalli", "Tirunelveli", "Tiruvannamalai", "Vellore", "Viluppuram", "Virudhunagar"])
        out = []
        for c in string.ascii_uppercase:
            out += [f"{c}{'abcdefghijklmnopqrstuvwxy'[i % 25]}district{i:02d}" for i in range(25)]
        out += ["Madurai", "24 Paraganas North"]
        return sorted(out)
    # deity
    if scope == "tn":
        tn = ["Amman", "Ayyanar", "Brahma", "Durga", "Ganesha", "Kali", "Karuppasamy", "Lakshmi", "Mariamman",
              "Murugan", "Nataraja", "Shiva", "Shiva (Ekambareswarar)", "Shiva (Meenakshi Sundareswarar)",
              "Shiva (Nataraja)", "Shiva (Ramanathaswamy)", "Sri Ranganatha", "Subramanya", "Surya",
              "Thirumal", "Varadharaja", "Venkateswara", "Vinayaka", "Vishnu", "Vishnu (Parthasarathy)",
              "Yoga Narasimha", "Andal", "Anjaneya", "Bhairava", "Chandikeswarar", "Dakshinamurthy", "Kamakshi"]
        return sorted(tn)
    out = []
    weights = {c: 23 for c in string.ascii_uppercase}
    for c in string.ascii_uppercase:
        out += [f"{c}{'abcdefghijklmnopqrstuvwxy'[i % 25]}deity{i:02d}" for i in range(weights[c])]
    # SIM_NO_AHALYA=1: the live list of run 41461260068 (no "Ahalya").
    out += ([] if os.environ.get("SIM_NO_AHALYA") == "1" else ["Ahalya"]) + ["Shiva"] + [f"Shiva ({x})" for x in ("Baneswar", "Kedarnath", "Mahakal", "Somnath", "Tarakeswar")]
    return sorted(out, key=lambda s: s.encode("utf-16-be"))


def layout(st):
    rows, y = [], 0
    for kind in st["order"]:
        rows.append((kind, "", y, HDR)); y += HDR
        if kind in ("state", "district", "deity"):
            rows.append((kind, "any", y, ROW)); y += ROW
        for n in st["lists"][kind]:
            rows.append((kind, n, y, ROW)); y += ROW
    return rows, y


def offset_now(st):
    p = st["pending"]
    frac = [0.55, 0.85, 1.0][min(st["since"], 2)] if p else 0
    return st["offset"] + p * frac


def clamp(st, v):
    _, total = layout(st)
    return max(0, min(v, total - (BAND_BOT - BAND_TOP)))


def load(p):
    return json.load(open(p))


def save(p, st):
    json.dump(st, open(p, "w"))


def main():
    cmd, path = sys.argv[1], sys.argv[2]
    if cmd == "init":
        order, scope = sys.argv[3].split(","), sys.argv[4]
        st = {"order": order, "offset": 0, "pending": 0, "since": 0,
              "lists": {k: names(k, scope) for k in ("state", "district", "deity")}}
        save(path, st); return
    st = load(path)
    if cmd == "dump":
        if st["pending"]:
            st["since"] += 1
            if st["since"] >= 3:
                st["offset"] = clamp(st, st["offset"] + st["pending"]); st["pending"] = 0; st["since"] = 0
        off = clamp(st, offset_now(st))
        rows, _ = layout(st)
        out = ['<?xml version="1.0" encoding="UTF-8"?><hierarchy rotation="0">',
               '<node text="" resource-id="" content-desc="Filters" bounds="[0,120][320,640]" scrollable="false">',
               '<node text="" resource-id="" content-desc="Filter temples" bounds="[16,150][304,200]" scrollable="false" />',
               f'<node text="" resource-id="" content-desc="" bounds="[0,{BAND_TOP}][320,{BAND_BOT}]" scrollable="true">']
        for kind, name, y, h in rows:
            top = BAND_TOP + int(y - off); bot = top + h
            top_c, bot_c = max(top, BAND_TOP), min(bot, BAND_BOT)
            if bot_c <= top_c:
                continue
            if not name:
                out.append(f'<node text="" resource-id="" content-desc="{kind.upper()}" bounds="[16,{top_c}][200,{bot_c}]" scrollable="false" />')
            else:
                label = ("Any " + kind) if name == "any" else name
                out.append(f'<node text="" resource-id="filter-option-{kind}-{name}" content-desc="{label}  3" bounds="[16,{top_c}][200,{bot_c}]" scrollable="false" />')
        out.append('</node><node text="" resource-id="" content-desc="Show 40 temples" bounds="[96,579][304,627]" scrollable="false" /></node></hierarchy>')
        save(path, st)
        print("\n".join(out)); return
    if cmd == "swipe":
        _x, y1, _x2, y2, ms = map(int, sys.argv[3:8])
        d = y1 - y2  # positive: finger up, list scrolls forward
        if not (BAND_TOP <= y1 <= BAND_BOT):
            save(path, st); return  # off the scroller: no scroll
        # A new touch stops any running momentum where it is.
        st["offset"] = clamp(st, offset_now(st)); st["pending"] = 0; st["since"] = 0
        if ms < 400:
            st["offset"] = clamp(st, st["offset"] + d)
            st["pending"] = clamp(st, st["offset"] + MOMENTUM * d) - st["offset"]
        else:
            st["offset"] = clamp(st, st["offset"] + d)
        save(path, st); return
    if cmd == "tap":
        x, y = int(sys.argv[3]), int(sys.argv[4])
        off = clamp(st, offset_now(st))
        for kind, name, ry, h in layout(st)[0]:
            top = BAND_TOP + int(ry - off)
            if name and top <= y < top + h:
                print(f"{kind}:{name}"); return
        print("none"); return


main()
