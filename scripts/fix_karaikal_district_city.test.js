import assert from "node:assert/strict";
import test from "node:test";
import { existsSync, mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  CITY_FIELD,
  DISTRICT_FIELD,
  REQUIRED_STATE,
  TARGETS,
  applyFix,
  assertAllowedUpdate,
  correctionFields,
  formatReport,
  inspectFix,
  main,
  parseArgs,
  toPlain,
  writeBackupFiles,
} from "./fix_karaikal_district_city.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = fileURLToPath(new URL("..", import.meta.url));
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const onEmulator = /^(127\.0\.0\.1|localhost):\d+$/.test(emulatorHost);

const COORDS = {
  "rajacholeeswarar-temple-thirumalairayanpattinam": { latitude: 10.8708, longitude: 79.8273 },
  "thanthondreeswarar-temple-nedungadu": { latitude: 10.9675, longitude: 79.7714 },
  "yazhmoorinathar-temple-dharmapuram": { latitude: 10.916, longitude: 79.8 },
};

function temple(id, overrides = {}) {
  const point = COORDS[id];
  return {
    name: id,
    state: REQUIRED_STATE,
    district: "Nagapattinam",
    city: "Karaikal",
    deity: "Shiva",
    description: "Leave this text alone.",
    latitude: point.latitude,
    longitude: point.longitude,
    imageUrl: `https://example.com/${id}.jpg`,
    ...overrides,
  };
}

function seedDocs() {
  const docs = {};
  for (const target of TARGETS) docs[target.id] = temple(target.id);
  docs["other-temple"] = {
    name: "Other",
    state: "Tamil Nadu",
    district: "Thanjavur",
    city: "Thanjavur",
    description: "Leave this document alone.",
    latitude: 10.78,
    longitude: 79.13,
  };
  return docs;
}

function fakeDb(initial) {
  const store = new Map(Object.entries(initial));
  const ops = [];
  let transactions = 0;
  function docRef(id) {
    return {
      id,
      path: `temples/${id}`,
      async get() {
        if (!store.has(id)) return { exists: false, id, data: () => undefined };
        const current = store.get(id);
        return { exists: true, id, data: () => ({ ...current }) };
      },
    };
  }
  return {
    ops,
    store,
    get transactions() {
      return transactions;
    },
    collection(name) {
      if (name !== "temples") throw new Error(`Refusing collection ${name}`);
      return { doc: (id) => docRef(id) };
    },
    async runTransaction(fn) {
      transactions += 1;
      const writes = [];
      await fn({
        get: (target) => target.get(),
        update(ref, fields) {
          writes.push({ op: "update", id: ref.id, fields: { ...fields } });
        },
      });
      for (const write of writes) {
        store.set(write.id, { ...store.get(write.id), ...write.fields });
      }
      ops.push(...writes);
    },
  };
}

function emulatorEnv() {
  return { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };
}

test("allowlist refuses other documents and other fields", () => {
  assert.equal(TARGETS.length, 3);
  for (const target of TARGETS) {
    assert.doesNotThrow(() => assertAllowedUpdate(target.id, correctionFields(target)));
  }
  assert.throws(
    () => assertAllowedUpdate("other-temple", correctionFields(TARGETS[0])),
    /Refusing to update temples\/other-temple/,
  );
  assert.throws(
    () => assertAllowedUpdate("chabimura", { district: "Karaikal", city: "Nedungadu" }),
    /Only temples\/rajacholeeswarar-temple-thirumalairayanpattinam/,
  );
  const id = TARGETS[0].id;
  assert.doesNotThrow(() =>
    assertAllowedUpdate(id, {
      district: "Karaikal",
      city: "Thirumalairayanpattinam",
      state: "Puducherry",
    }),
  );
  assert.throws(
    () => assertAllowedUpdate(id, { district: "Karaikal", city: "Thirumalairayanpattinam", latitude: 1 }),
    /Only district and city/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { state: "Puducherry" }),
    /Only district and city/,
  );
  assert.throws(
    () =>
      assertAllowedUpdate(id, {
        district: "Karaikal",
        city: "Thirumalairayanpattinam",
        state: "Tamil Nadu",
      }),
    /Only Puducherry may be set/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { longitude: 79.8 }),
    /Only district and city/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { city: "Thirumalairayanpattinam" }),
    /Only district and city/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { district: "Karaikal", city: "Karaikal" }),
    /Only district "Karaikal" and city "Thirumalairayanpattinam"/,
  );
  assert.throws(() => assertAllowedUpdate(id, {}), /Only district and city/);
});

test("the general field-patch allowlist is not widened", () => {
  const source = readFileSync(join(repoRoot, "scripts", "apply_field_patches.js"), "utf8");
  assert.match(
    source,
    /const ALLOWED_FIELDS = new Set\(\[\s*"imageUrl",\s*"images",\s*"photos",\s*"timings",\s*"deity",\s*"tradition",\s*\]\)/,
  );
  assert.doesNotMatch(source, /"district"/);
  const driver = readFileSync(join(here, "fix_karaikal_district_city.js"), "utf8");
  assert.match(driver, /ONE-USE/);
  assert.match(driver, /Puducherry\/Karaikal shard/);
  assert.match(driver, /APPLY-FINISHED/);
  assert.doesNotMatch(driver, /from "\.\/rebuild_index\.js"/);
  assert.doesNotMatch(driver, /from "\.\/apply_field_patches\.js"/);
});

test("a missing backup dir aborts before Firestore is opened", async () => {
  let opened = 0;
  await assert.rejects(
    () =>
      main(["--apply", "--project", "temple-directory-india"], {
        env: {},
        db: {
          collection() {
            opened += 1;
            throw new Error("should not open");
          },
        },
      }),
    /--backup-dir is required with --apply/,
  );
  assert.equal(opened, 0);
});

test("dry-run prints the diff and does not write", async () => {
  const db = fakeDb(seedDocs());
  const lines = [];
  const result = await main(["--project", "demo-temple-index"], {
    env: emulatorEnv(),
    db,
    log: (line) => lines.push(line),
    confirm: async () => {
      throw new Error("dry-run must not confirm");
    },
  });
  assert.equal(result.wrote, false);
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  for (const target of TARGETS) {
    const stored = db.store.get(target.id);
    assert.equal(stored.district, "Nagapattinam");
    assert.equal(stored.city, "Karaikal");
    assert.equal(stored.state, REQUIRED_STATE);
    assert.equal(stored.latitude, COORDS[target.id].latitude);
    assert.equal(stored.longitude, COORDS[target.id].longitude);
  }
  const text = lines.join("\n");
  assert.match(text, /Mode: dry-run/);
  assert.match(text, /district: "Nagapattinam" -> "Karaikal"/);
  assert.match(text, /city: "Karaikal" -> "Thirumalairayanpattinam"/);
  assert.match(text, /city: "Karaikal" -> "Nedungadu"/);
  assert.match(text, /city: "Karaikal" -> "Dharmapuram"/);
  assert.doesNotMatch(text, /state: /);
  assert.match(text, /latitude and longitude are not written/);
  assert.match(text, /No Firestore writes/);
  assert.match(text, /Puducherry\/Karaikal shard/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
  assert.equal(db.store.get("other-temple").city, "Thanjavur");
});

test("apply writes the backup and only district and city", async () => {
  const db = fakeDb(seedDocs());
  const before = Object.fromEntries(
    TARGETS.map((target) => [target.id, structuredClone(db.store.get(target.id))]),
  );
  const dir = mkdtempSync(join(tmpdir(), "karaikal-backup-"));
  const lines = [];
  const result = await main(
    ["--apply", "--backup-dir", dir, "--project", "demo-temple-index"],
    {
      env: emulatorEnv(),
      db,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("emulator apply must not confirm");
      },
    },
  );
  assert.equal(result.wrote, true);
  assert.equal(db.transactions, 1);
  assert.equal(db.ops.length, 3);
  for (const target of TARGETS) {
    const kept = db.store.get(target.id);
    const prior = before[target.id];
    assert.equal(kept.district, "Karaikal");
    assert.equal(kept.city, target.city);
    assert.equal(kept.state, prior.state);
    assert.equal(kept.latitude, prior.latitude);
    assert.equal(kept.longitude, prior.longitude);
    assert.equal(kept.description, prior.description);
    assert.equal(kept.deity, prior.deity);
    assert.equal(kept.imageUrl, prior.imageUrl);
    assert.equal(kept.name, prior.name);
    const op = db.ops.find((item) => item.id === target.id);
    assert.deepEqual(op, {
      op: "update",
      id: target.id,
      fields: { district: "Karaikal", city: target.city },
    });
    assert.equal(Object.prototype.hasOwnProperty.call(op.fields, "state"), false);
    const saved = JSON.parse(readFileSync(join(dir, `${target.id}.json`), "utf8"));
    assert.equal(saved.path, `temples/${target.id}`);
    assert.equal(saved.data.district, "Nagapattinam");
    assert.equal(saved.data.city, "Karaikal");
    assert.equal(saved.data.latitude, prior.latitude);
    assert.equal(saved.data.longitude, prior.longitude);
    assert.equal(saved.data.state, REQUIRED_STATE);
  }
  assert.equal(db.store.get("other-temple").description, "Leave this document alone.");
  assert.equal(db.store.get("other-temple").district, "Thanjavur");
  const text = lines.join("\n");
  assert.match(text, new RegExp(`Backup: ${dir}`));
  assert.match(text, /APPLY-FINISHED/);
  assert.equal(text.indexOf("APPLY-FINISHED"), text.lastIndexOf("APPLY-FINISHED"));
});

test("a failed backup aborts before any Firestore write", async () => {
  const db = fakeDb(seedDocs());
  await assert.rejects(
    () =>
      applyFix(db, {
        backupDir: join(tmpdir(), "unused"),
        log: () => {},
        writeBackup: () => {
          throw new Error("disk full");
        },
      }),
    /Backup failed: disk full/,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  assert.equal(db.store.get(TARGETS[0].id).city, "Karaikal");
});

test("preconditions abort with no writes", async () => {
  const cases = [
    {
      name: "missing doc",
      edit: (docs) => {
        delete docs[TARGETS[1].id];
      },
      pattern: /thanthondreeswarar-temple-nedungadu does not exist/,
    },
    {
      name: "missing district",
      edit: (docs) => {
        const row = temple(TARGETS[0].id);
        delete row.district;
        docs[TARGETS[0].id] = row;
      },
      pattern: /no existing district field/,
    },
    {
      name: "missing city",
      edit: (docs) => {
        const row = temple(TARGETS[0].id);
        delete row.city;
        docs[TARGETS[0].id] = row;
      },
      pattern: /no existing city field/,
    },
  ];
  for (const item of cases) {
    const docs = seedDocs();
    item.edit(docs);
    const db = fakeDb(docs);
    await assert.rejects(() => inspectFix(db), item.pattern);
    assert.deepEqual(db.ops, [], item.name);
    const dir = mkdtempSync(join(tmpdir(), "no-backup-"));
    await assert.rejects(
      () =>
        applyFix(db, {
          backupDir: dir,
          log: () => {},
        }),
      item.pattern,
    );
    assert.deepEqual(db.ops, [], item.name);
    assert.equal(db.transactions, 0, item.name);
    for (const target of TARGETS) {
      assert.equal(existsSync(join(dir, `${target.id}.json`)), false, item.name);
    }
  }
});

test("the transaction re-read aborts when a document changes after the backup", async () => {
  const db = fakeDb(seedDocs());
  const dir = mkdtempSync(join(tmpdir(), "reread-"));
  await assert.rejects(
    () =>
      applyFix(db, {
        backupDir: dir,
        log: () => {},
        writeBackup(folder, docs) {
          const written = writeBackupFiles(folder, docs);
          db.store.get(TARGETS[0].id).latitude = 1;
          return written;
        },
      }),
    /changed after the backup/,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.store.get(TARGETS[0].id).city, "Karaikal");
  assert.equal(db.store.get(TARGETS[0].id).district, "Nagapattinam");
  assert.equal(db.store.get(TARGETS[0].id).latitude, 1);
  assert.equal(db.store.get(TARGETS[1].id).city, "Karaikal");
});

test("a non-Puducherry state is written on that document only", async () => {
  const docs = seedDocs();
  const changedId = TARGETS[2].id;
  docs[changedId] = temple(changedId, { state: "Tamil Nadu" });
  const db = fakeDb(docs);
  const lines = [];
  const preview = await main(["--project", "demo-temple-index"], {
    env: emulatorEnv(),
    db,
    log: (line) => lines.push(line),
  });
  assert.equal(preview.wrote, false);
  assert.deepEqual(db.ops, []);
  const text = lines.join("\n");
  assert.match(
    text,
    new RegExp(
      `temples/${changedId}\\n  district: "Nagapattinam" -> "Karaikal"\\n  city: "Karaikal" -> "Dharmapuram"\\n  state: "Tamil Nadu" -> "Puducherry"`,
    ),
  );
  for (const target of TARGETS) {
    if (target.id === changedId) continue;
    const block = text.split(`temples/${target.id}\n`)[1].split("\ntemples/")[0];
    assert.doesNotMatch(block, /state: /);
  }
  assert.equal(preview.report.filter((row) => row.stateChanged).map((row) => row.id).join(), changedId);
  const dir = mkdtempSync(join(tmpdir(), "state-fix-"));
  await main(["--apply", "--backup-dir", dir, "--project", "demo-temple-index"], {
    env: emulatorEnv(),
    db,
    log: () => {},
  });
  assert.equal(db.transactions, 1);
  assert.equal(db.ops.length, 3);
  for (const target of TARGETS) {
    const kept = db.store.get(target.id);
    assert.equal(kept.district, "Karaikal");
    assert.equal(kept.city, target.city);
    assert.equal(kept.state, REQUIRED_STATE);
    assert.equal(kept.latitude, COORDS[target.id].latitude);
    assert.equal(kept.longitude, COORDS[target.id].longitude);
    const op = db.ops.find((item) => item.id === target.id);
    if (target.id === changedId) {
      assert.deepEqual(op.fields, {
        district: "Karaikal",
        city: target.city,
        state: "Puducherry",
      });
    } else {
      assert.deepEqual(op.fields, { district: "Karaikal", city: target.city });
    }
  }
  assert.equal(db.store.get("other-temple").state, "Tamil Nadu");
  assert.equal(db.store.get("other-temple").city, "Thanjavur");
  const saved = JSON.parse(readFileSync(join(dir, `${changedId}.json`), "utf8"));
  assert.equal(saved.data.state, "Tamil Nadu");
});

test("fields that already match are left unchanged inside the same transaction", async () => {
  const docs = seedDocs();
  docs[TARGETS[1].id] = temple(TARGETS[1].id, {
    district: "Karaikal",
    city: "Nedungadu",
  });
  const db = fakeDb(docs);
  const preview = await inspectFix(db);
  const unchanged = preview.find((row) => row.id === TARGETS[1].id);
  assert.equal(unchanged.districtChanged, false);
  assert.equal(unchanged.cityChanged, false);
  assert.equal(unchanged.stateChanged, false);
  assert.match(formatReport(preview), /Left unchanged|city: "Karaikal" -> "Thirumalairayanpattinam"/);
  const dir = mkdtempSync(join(tmpdir(), "leave-match-"));
  const lines = [];
  await applyFix(db, {
    backupDir: dir,
    log: (line) => lines.push(line),
  });
  assert.equal(db.transactions, 1);
  assert.equal(db.ops.some((op) => op.id === TARGETS[1].id), false);
  assert.equal(db.ops.length, 2);
  assert.equal(db.store.get(TARGETS[1].id).latitude, COORDS[TARGETS[1].id].latitude);
  assert.equal(db.store.get(TARGETS[0].id).city, "Thirumalairayanpattinam");
  assert.equal(db.store.get(TARGETS[2].id).city, "Dharmapuram");
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
});

test("apply refuses CI and does not write", async () => {
  const db = fakeDb(seedDocs());
  const dir = mkdtempSync(join(tmpdir(), "ci-backup-"));
  const lines = [];
  await assert.rejects(
    () =>
      main(["--apply", "--backup-dir", dir, "--project", "demo"], {
        env: { CI: "true", FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
        db,
        log: (line) => lines.push(line),
      }),
    /CI/,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  assert.equal(db.store.get(TARGETS[0].id).district, "Nagapattinam");
  assert.equal(existsSync(join(dir, `${TARGETS[0].id}.json`)), false);
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
});

test("parse rejects unknown arguments and defaults to dry-run", () => {
  assert.equal(parseArgs(["--project", "demo"]).apply, false);
  assert.equal(parseArgs(["--apply", "--project", "demo"]).dryRun, false);
  assert.throws(() => parseArgs(["--id", TARGETS[0].id]), /Unknown argument/);
  assert.throws(() => parseArgs(["--field", "latitude"]), /Unknown argument/);
  assert.equal(DISTRICT_FIELD, "district");
  assert.equal(CITY_FIELD, "city");
});

test("timestamp values in a backup stay readable", async () => {
  const admin = (await import("firebase-admin")).default;
  const stamp = new admin.firestore.Timestamp(1_700_000_000, 0);
  const plain = toPlain({ createdAt: stamp, latitude: 10.87, city: "Nedungadu" });
  assert.equal(plain.createdAt, "2023-11-14T22:13:20.000Z");
  assert.equal(plain.latitude, 10.87);
  assert.equal(plain.city, "Nedungadu");
});

async function emulatorDb(project) {
  process.env.FIRESTORE_EMULATOR_HOST = emulatorHost;
  const admin = (await import("firebase-admin")).default;
  const named = admin.apps.find((app) => app?.name === project);
  const app = named ?? admin.initializeApp({ projectId: project }, project);
  return app.firestore();
}

async function resetTemples(db, docs) {
  const existing = await db.collection("temples").get();
  const batch = db.batch();
  for (const doc of existing.docs) batch.delete(doc.ref);
  for (const [id, data] of Object.entries(docs)) {
    batch.set(db.collection("temples").doc(id), data);
  }
  await batch.commit();
}

test(
  "emulator dry-run writes nothing and apply updates only district and city",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const project = "demo-karaikal-district-city";
    const db = await emulatorDb(project);
    const docs = seedDocs();
    const changedId = TARGETS[2].id;
    docs[changedId] = temple(changedId, { state: "Tamil Nadu" });
    await resetTemples(db, docs);
    const env = { FIRESTORE_EMULATOR_HOST: emulatorHost };
    const lines = [];
    await main(["--project", project], {
      env,
      db,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("dry-run must not confirm");
      },
    });
    assert.match(lines.join("\n"), /No Firestore writes/);
    assert.match(lines.join("\n"), /state: "Tamil Nadu" -> "Puducherry"/);
    assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
    const afterDry = await db.collection("temples").doc(TARGETS[0].id).get();
    assert.equal(afterDry.data().city, "Karaikal");
    assert.equal(afterDry.data().latitude, COORDS[TARGETS[0].id].latitude);
    const dir = mkdtempSync(join(tmpdir(), "emulator-karaikal-"));
    await main(["--apply", "--backup-dir", dir, "--project", project], {
      env,
      db,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("emulator apply must not confirm");
      },
    });
    for (const target of TARGETS) {
      const snap = await db.collection("temples").doc(target.id).get();
      assert.equal(snap.data().district, "Karaikal");
      assert.equal(snap.data().city, target.city);
      assert.equal(snap.data().state, REQUIRED_STATE);
      assert.equal(snap.data().latitude, COORDS[target.id].latitude);
      assert.equal(snap.data().longitude, COORDS[target.id].longitude);
      assert.equal(snap.data().description, "Leave this text alone.");
      const backup = JSON.parse(readFileSync(join(dir, `${target.id}.json`), "utf8"));
      assert.equal(backup.data.city, "Karaikal");
      assert.equal(backup.data.district, "Nagapattinam");
      assert.equal(backup.data.state, target.id === changedId ? "Tamil Nadu" : REQUIRED_STATE);
    }
    const other = await db.collection("temples").doc("other-temple").get();
    assert.equal(other.data().state, "Tamil Nadu");
    assert.equal(other.data().city, "Thanjavur");
    assert.match(lines.join("\n"), /APPLY-FINISHED/);
    assert.match(lines.join("\n"), /Backup: /);
  },
);
