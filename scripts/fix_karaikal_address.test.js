import assert from "node:assert/strict";
import test from "node:test";
import { existsSync, mkdtempSync, readFileSync, readdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  ADDRESS_FIELD,
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
} from "./fix_karaikal_address.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const repoRoot = fileURLToPath(new URL("..", import.meta.url));
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const onEmulator = /^(127\.0\.0\.1|localhost):\d+$/.test(emulatorHost);

const COORDS = {
  "rajacholeeswarar-temple-thirumalairayanpattinam": { latitude: 10.8708, longitude: 79.8273 },
  "thanthondreeswarar-temple-nedungadu": { latitude: 10.9675, longitude: 79.7714 },
  "yazhmoorinathar-temple-dharmapuram": { latitude: 10.916, longitude: 79.8 },
};

const CITIES = {
  "rajacholeeswarar-temple-thirumalairayanpattinam": "Thirumalairayanpattinam",
  "thanthondreeswarar-temple-nedungadu": "Nedungadu",
  "yazhmoorinathar-temple-dharmapuram": "Dharmapuram",
};

function temple(id, overrides = {}) {
  const point = COORDS[id];
  const target = TARGETS.find((item) => item.id === id);
  return {
    name: id,
    state: "Puducherry",
    city: CITIES[id],
    address: target.before,
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
    city: "Thanjavur",
    address: "Thanjavur, Tamil Nadu",
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
    assert.equal(target.after, target.before.replace(", Puducherry", ", Karaikal, Puducherry"));
  }
  assert.throws(
    () => assertAllowedUpdate("other-temple", correctionFields(TARGETS[0])),
    /Refusing to update temples\/other-temple/,
  );
  assert.throws(
    () => assertAllowedUpdate("chabimura", { address: TARGETS[0].after }),
    /Only temples\/rajacholeeswarar-temple-thirumalairayanpattinam/,
  );
  const id = TARGETS[0].id;
  assert.throws(
    () => assertAllowedUpdate(id, { address: TARGETS[0].after, district: "Karaikal" }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { address: TARGETS[0].after, city: "Thirumalairayanpattinam" }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { address: TARGETS[0].after, state: "Puducherry" }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { latitude: 1 }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { longitude: 79.8 }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { city: "Thirumalairayanpattinam" }),
    /Only address/,
  );
  assert.throws(
    () => assertAllowedUpdate(id, { address: TARGETS[0].before }),
    /Only "Thirumalairayanpattinam, Karaikal, Puducherry"/,
  );
  assert.throws(() => assertAllowedUpdate(id, {}), /Only address/);
});

test("the general field-patch allowlist is not widened", () => {
  const source = readFileSync(join(repoRoot, "scripts", "apply_field_patches.js"), "utf8");
  assert.match(
    source,
    /const ALLOWED_FIELDS = new Set\(\[\s*"imageUrl",\s*"images",\s*"photos",\s*"timings",\s*"deity",\s*"tradition",\s*\]\)/,
  );
  assert.doesNotMatch(source, /"address"/);
  assert.doesNotMatch(source, /"district"/);
  const driver = readFileSync(join(here, "fix_karaikal_address.js"), "utf8");
  assert.match(driver, /ONE-USE/);
  assert.match(driver, /address drift for these 3 ids only/);
  assert.match(driver, /delete scripts\/fix_karaikal_address\.js/);
  assert.match(driver, /APPLY-FINISHED/);
  assert.doesNotMatch(driver, /from "\.\/rebuild_index\.js"/);
  assert.doesNotMatch(driver, /from "\.\/apply_field_patches\.js"/);
  assert.equal(existsSync(join(here, "fix_karaikal_district_city.js")), false);
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

test("dry-run prints the address diff and does not write", async () => {
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
  assert.equal(result.backupDir, null);
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  for (const target of TARGETS) {
    const stored = db.store.get(target.id);
    assert.equal(stored.address, target.before);
    assert.equal(stored.city, CITIES[target.id]);
    assert.equal(stored.state, "Puducherry");
    assert.equal(stored.latitude, COORDS[target.id].latitude);
    assert.equal(stored.longitude, COORDS[target.id].longitude);
    assert.equal(Object.prototype.hasOwnProperty.call(stored, "district"), false);
  }
  const text = lines.join("\n");
  assert.match(text, /Mode: dry-run/);
  assert.match(
    text,
    /address: "Thirumalairayanpattinam, Puducherry" -> "Thirumalairayanpattinam, Karaikal, Puducherry"/,
  );
  assert.match(text, /address: "Nedungadu, Puducherry" -> "Nedungadu, Karaikal, Puducherry"/);
  assert.match(text, /address: "Dharmapuram, Puducherry" -> "Dharmapuram, Karaikal, Puducherry"/);
  assert.doesNotMatch(text, /district:/);
  assert.doesNotMatch(text, /city:/);
  assert.doesNotMatch(text, /state:/);
  assert.match(text, /district, city, state, latitude, and longitude are not written/);
  assert.match(text, /No Firestore writes/);
  assert.match(text, /address drift for these 3 ids only/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
  assert.equal(db.store.get("other-temple").address, "Thanjavur, Tamil Nadu");
});

test("dry-run with --backup-dir exports the current documents and does not write Firestore", async () => {
  const db = fakeDb(seedDocs());
  const dir = mkdtempSync(join(tmpdir(), "karaikal-dry-backup-"));
  const lines = [];
  const result = await main(
    ["--backup-dir", dir, "--project=demo-temple-index"],
    {
      env: emulatorEnv(),
      db,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("dry-run must not confirm");
      },
    },
  );
  assert.equal(result.wrote, false);
  assert.equal(result.backupDir, dir);
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  const text = lines.join("\n");
  assert.match(text, /Mode: dry-run/);
  assert.match(text, new RegExp(`Backup: ${dir}`));
  assert.match(text, /Backup export is read-only/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
  for (const target of TARGETS) {
    assert.equal(db.store.get(target.id).address, target.before);
    const saved = JSON.parse(readFileSync(join(dir, `${target.id}.json`), "utf8"));
    assert.equal(saved.path, `temples/${target.id}`);
    assert.equal(saved.data.address, target.before);
    assert.equal(saved.data.city, CITIES[target.id]);
    assert.equal(saved.data.state, "Puducherry");
    assert.equal(saved.data.latitude, COORDS[target.id].latitude);
  }
});

test("a failed dry-run backup aborts with no Firestore write and no APPLY-FINISHED", async () => {
  const db = fakeDb(seedDocs());
  const lines = [];
  await assert.rejects(
    () =>
      main(["--backup-dir", join(tmpdir(), "unused"), "--project", "demo-temple-index"], {
        env: emulatorEnv(),
        db,
        log: (line) => lines.push(line),
        writeBackup() {
          throw new Error("disk full");
        },
      }),
    /Backup failed: disk full No write\./,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.transactions, 0);
  assert.equal(db.store.get(TARGETS[0].id).address, TARGETS[0].before);
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
});

test("apply writes the backup and only address", async () => {
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
    assert.equal(kept.address, target.after);
    assert.equal(kept.city, prior.city);
    assert.equal(kept.state, prior.state);
    assert.equal(kept.latitude, prior.latitude);
    assert.equal(kept.longitude, prior.longitude);
    assert.equal(kept.description, prior.description);
    assert.equal(kept.deity, prior.deity);
    assert.equal(kept.imageUrl, prior.imageUrl);
    assert.equal(kept.name, prior.name);
    assert.equal(Object.prototype.hasOwnProperty.call(kept, "district"), false);
    const op = db.ops.find((item) => item.id === target.id);
    assert.deepEqual(op, {
      op: "update",
      id: target.id,
      fields: { address: target.after },
    });
    const saved = JSON.parse(readFileSync(join(dir, `${target.id}.json`), "utf8"));
    assert.equal(saved.path, `temples/${target.id}`);
    assert.equal(saved.data.address, target.before);
    assert.equal(saved.data.city, prior.city);
    assert.equal(saved.data.latitude, prior.latitude);
    assert.equal(saved.data.longitude, prior.longitude);
    assert.equal(saved.data.state, "Puducherry");
  }
  assert.equal(db.store.get("other-temple").description, "Leave this document alone.");
  assert.equal(db.store.get("other-temple").address, "Thanjavur, Tamil Nadu");
  const text = lines.join("\n");
  assert.match(text, new RegExp(`Backup: ${dir}`));
  assert.match(text, /APPLY-FINISHED/);
  assert.equal(text.indexOf("APPLY-FINISHED"), text.lastIndexOf("APPLY-FINISHED"));
  assert.match(formatReport(result.report, { apply: true, backupDir: dir }), /Updated temples\//);
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
  assert.equal(db.store.get(TARGETS[0].id).address, TARGETS[0].before);
});

test("one wrong address refuses the whole run before backup", async () => {
  const cases = [
    {
      name: "missing doc",
      edit: (docs) => {
        delete docs[TARGETS[1].id];
      },
      pattern: /thanthondreeswarar-temple-nedungadu does not exist/,
    },
    {
      name: "wrong address",
      edit: (docs) => {
        docs[TARGETS[0].id] = temple(TARGETS[0].id, {
          address: "Thirumalairayanpattinam, Karaikal, Puducherry",
        });
        docs[TARGETS[2].id] = temple(TARGETS[2].id, {
          address: "Dharmapuram, Pondicherry",
        });
      },
      pattern:
        /rajacholeeswarar-temple-thirumalairayanpattinam address is "Thirumalairayanpattinam, Karaikal, Puducherry"[\s\S]*yazhmoorinathar-temple-dharmapuram address is "Dharmapuram, Pondicherry"[\s\S]*No write\./,
    },
    {
      name: "missing address",
      edit: (docs) => {
        const row = temple(TARGETS[0].id);
        delete row.address;
        docs[TARGETS[0].id] = row;
      },
      pattern: /address is null, expected "Thirumalairayanpattinam, Puducherry"/,
    },
    {
      name: "spacing mismatch",
      edit: (docs) => {
        docs[TARGETS[1].id] = temple(TARGETS[1].id, { address: "Nedungadu,  Puducherry" });
      },
      pattern: /address is "Nedungadu,  Puducherry", expected "Nedungadu, Puducherry"/,
    },
  ];
  for (const item of cases) {
    const docs = seedDocs();
    item.edit(docs);
    const db = fakeDb(docs);
    await assert.rejects(() => inspectFix(db), item.pattern);
    assert.deepEqual(db.ops, [], item.name);
    const dir = mkdtempSync(join(tmpdir(), "no-backup-"));
    const lines = [];
    await assert.rejects(
      () =>
        main(["--apply", "--backup-dir", dir, "--project", "demo-temple-index"], {
          env: emulatorEnv(),
          db,
          log: (line) => lines.push(line),
        }),
      item.pattern,
    );
    assert.deepEqual(db.ops, [], item.name);
    assert.equal(db.transactions, 0, item.name);
    assert.equal(readdirSync(dir).length, 0, item.name);
    assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
    await assert.rejects(
      () =>
        main(["--backup-dir", dir, "--project", "demo-temple-index"], {
          env: emulatorEnv(),
          db,
          log: () => {},
        }),
      item.pattern,
    );
    assert.equal(readdirSync(dir).length, 0, item.name);
    for (const target of TARGETS) {
      if (!db.store.has(target.id)) continue;
      const stored = db.store.get(target.id);
      assert.equal(stored.city, CITIES[target.id], item.name);
      assert.equal(stored.latitude, COORDS[target.id].latitude, item.name);
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
  assert.equal(db.store.get(TARGETS[0].id).address, TARGETS[0].before);
  assert.equal(db.store.get(TARGETS[0].id).latitude, 1);
  assert.equal(db.store.get(TARGETS[1].id).address, TARGETS[1].before);
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
  assert.equal(db.store.get(TARGETS[0].id).address, TARGETS[0].before);
  assert.equal(existsSync(join(dir, `${TARGETS[0].id}.json`)), false);
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
});

test("parse rejects unknown arguments and defaults to dry-run", () => {
  assert.equal(parseArgs(["--project", "demo"]).apply, false);
  assert.equal(parseArgs(["--project", "demo"]).project, "demo");
  assert.equal(parseArgs(["--apply", "--project", "demo"]).dryRun, false);
  assert.equal(parseArgs(["--project=demo-temple-index"]).project, "demo-temple-index");
  assert.equal(parseArgs(["--project=demo-temple-index"]).apply, false);
  assert.equal(parseArgs(["--apply", "--project=demo-temple-index"]).dryRun, false);
  assert.equal(parseArgs(["--apply", "--project=demo-temple-index"]).project, "demo-temple-index");
  assert.equal(parseArgs(["--backup-dir=/tmp/karaikal"]).backupDir, "/tmp/karaikal");
  assert.equal(parseArgs(["--dry-run", "--backup-dir", "backups"]).apply, false);
  assert.throws(() => parseArgs(["--project="]), /--project needs/);
  assert.throws(() => parseArgs(["--project=--apply"]), /--project needs/);
  assert.throws(() => parseArgs(["--backup-dir="]), /--backup-dir needs/);
  assert.throws(() => parseArgs(["--id", TARGETS[0].id]), /Unknown argument/);
  assert.throws(() => parseArgs(["--field", "latitude"]), /Unknown argument/);
  assert.equal(ADDRESS_FIELD, "address");
});

test("--project=value dry-run reads and does not write", async () => {
  const db = fakeDb(seedDocs());
  const lines = [];
  const result = await main(["--project=demo-temple-index"], {
    env: emulatorEnv(),
    db,
    log: (line) => lines.push(line),
  });
  assert.equal(result.wrote, false);
  assert.deepEqual(db.ops, []);
  assert.match(lines.join("\n"), /Mode: dry-run/);
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
});

test("a second apply refuses because the address no longer matches before", async () => {
  const db = fakeDb(seedDocs());
  const dir = mkdtempSync(join(tmpdir(), "second-"));
  await main(["--apply", "--backup-dir", dir, "--project", "demo-temple-index"], {
    env: emulatorEnv(),
    db,
    log: () => {},
  });
  assert.equal(db.ops.length, 3);
  const again = mkdtempSync(join(tmpdir(), "second-again-"));
  const lines = [];
  await assert.rejects(
    () =>
      main(["--apply", "--backup-dir", again, "--project", "demo-temple-index"], {
        env: emulatorEnv(),
        db,
        log: (line) => lines.push(line),
      }),
    /No write\./,
  );
  assert.equal(db.ops.length, 3);
  assert.equal(db.transactions, 1);
  assert.equal(readdirSync(again).length, 0);
  assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
  for (const target of TARGETS) {
    assert.equal(db.store.get(target.id).address, target.after);
  }
});

test("timestamp values in a backup stay readable", async () => {
  const admin = (await import("firebase-admin")).default;
  const stamp = new admin.firestore.Timestamp(1_700_000_000, 0);
  const plain = toPlain({ createdAt: stamp, latitude: 10.87, address: "Nedungadu, Puducherry" });
  assert.equal(plain.createdAt, "2023-11-14T22:13:20.000Z");
  assert.equal(plain.latitude, 10.87);
  assert.equal(plain.address, "Nedungadu, Puducherry");
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
  "emulator dry-run writes nothing and apply updates only address",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const project = "demo-karaikal-address";
    const db = await emulatorDb(project);
    const docs = seedDocs();
    await resetTemples(db, docs);
    const env = { FIRESTORE_EMULATOR_HOST: emulatorHost };
    const lines = [];
    const dryDir = mkdtempSync(join(tmpdir(), "emulator-karaikal-dry-"));
    await main(["--backup-dir", dryDir, "--project", project], {
      env,
      db,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("dry-run must not confirm");
      },
    });
    assert.match(lines.join("\n"), /No Firestore writes/);
    assert.match(lines.join("\n"), /Backup export is read-only/);
    assert.doesNotMatch(lines.join("\n"), /APPLY-FINISHED/);
    const afterDry = await db.collection("temples").doc(TARGETS[0].id).get();
    assert.equal(afterDry.data().address, TARGETS[0].before);
    assert.equal(afterDry.data().latitude, COORDS[TARGETS[0].id].latitude);
    assert.equal(afterDry.data().city, CITIES[TARGETS[0].id]);
    const dryBackup = JSON.parse(readFileSync(join(dryDir, `${TARGETS[0].id}.json`), "utf8"));
    assert.equal(dryBackup.data.address, TARGETS[0].before);

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
      assert.equal(snap.data().address, target.after);
      assert.equal(snap.data().city, CITIES[target.id]);
      assert.equal(snap.data().state, "Puducherry");
      assert.equal(snap.data().latitude, COORDS[target.id].latitude);
      assert.equal(snap.data().longitude, COORDS[target.id].longitude);
      assert.equal(snap.data().description, "Leave this text alone.");
      assert.equal(Object.prototype.hasOwnProperty.call(snap.data(), "district"), false);
      const backup = JSON.parse(readFileSync(join(dir, `${target.id}.json`), "utf8"));
      assert.equal(backup.data.address, target.before);
      assert.equal(backup.data.city, CITIES[target.id]);
      assert.equal(backup.data.state, "Puducherry");
    }
    const other = await db.collection("temples").doc("other-temple").get();
    assert.equal(other.data().state, "Tamil Nadu");
    assert.equal(other.data().address, "Thanjavur, Tamil Nadu");
    assert.match(lines.join("\n"), /APPLY-FINISHED/);
    assert.match(lines.join("\n"), /Backup: /);

    const again = mkdtempSync(join(tmpdir(), "emulator-karaikal-again-"));
    await assert.rejects(
      () =>
        main(["--apply", "--backup-dir", again, "--project", project], {
          env,
          db,
          log: () => {},
          confirm: async () => {
            throw new Error("emulator apply must not confirm");
          },
        }),
      /No write\./,
    );
    assert.equal(readdirSync(again).length, 0);
    const still = await db.collection("temples").doc(TARGETS[1].id).get();
    assert.equal(still.data().address, TARGETS[1].after);
    assert.equal(still.data().city, CITIES[TARGETS[1].id]);
  },
);
