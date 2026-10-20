import assert from "node:assert/strict";
import test from "node:test";
import { existsSync, mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  DELETE_ID,
  DESCRIPTION_PATH,
  TRIPURA_BEFORE,
  UPDATE_ID,
  applyMerge,
  assertAllowedDelete,
  assertAllowedUpdate,
  assertTripuraCount,
  formatReport,
  inspectMerge,
  loadDescription,
  main,
  parseArgs,
  photosLength,
  toPlain,
} from "./merge_devtamura_into_chabimura.js";

const here = fileURLToPath(new URL(".", import.meta.url));
const description = loadDescription(DESCRIPTION_PATH);
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST ?? "";
const onEmulator = /^(127\.0\.0\.1|localhost):\d+$/.test(emulatorHost);

function photo(url) {
  return { url, credit: "Tester", licence: "CC-BY", order: 0 };
}

function chabimura(overrides = {}) {
  return {
    name: "Chabimura",
    state: "Tripura",
    city: "Amarpur",
    description: "Chabimura (Chakrakma) is a set of large rock-carved panels.",
    imageUrl: "https://example.com/chabimura.jpg",
    photos: [photo("https://example.com/chabimura.jpg")],
    latitude: 23.542,
    longitude: 91.6057,
    ...overrides,
  };
}

function devtamura(overrides = {}) {
  return {
    name: "Devtamura",
    state: "Tripura",
    city: "South Tripura district",
    description: "Devtamura is a hill range with rock carvings.",
    imageUrl: "https://example.com/devtamura.jpg",
    photos: [
      photo("https://example.com/devtamura-1.jpg"),
      photo("https://example.com/devtamura-2.jpg"),
    ],
    latitude: 23.2319,
    longitude: 91.5596,
    ...overrides,
  };
}

function seedDocs() {
  const docs = {
    [UPDATE_ID]: chabimura(),
    [DELETE_ID]: devtamura(),
    "other-state": {
      name: "Other",
      state: "Kerala",
      description: "Leave this document alone.",
      latitude: 10,
      longitude: 76,
    },
  };
  for (let i = 0; i < TRIPURA_BEFORE - 2; i += 1) {
    docs[`tripura-extra-${i}`] = {
      name: `Extra ${i}`,
      state: "Tripura",
      description: "Another Tripura listing.",
    };
  }
  return docs;
}

function fakeDb(initial) {
  const store = new Map(Object.entries(initial));
  const ops = [];
  function docRef(id) {
    return {
      id,
      path: `temples/${id}`,
      async get() {
        if (!store.has(id)) return { exists: false, id, data: () => undefined };
        return { exists: true, id, data: () => store.get(id) };
      },
    };
  }
  function query(field, op, value) {
    return {
      async get() {
        const docs = [];
        for (const [id, data] of store) {
          if (op === "==" && data?.[field] === value) {
            docs.push({ id, data: () => data });
          }
        }
        return { size: docs.length, docs };
      },
    };
  }
  return {
    ops,
    store,
    collection(name) {
      if (name !== "temples") throw new Error(`Refusing collection ${name}`);
      return {
        doc: (id) => docRef(id),
        where: (field, op, value) => query(field, op, value),
      };
    },
    async runTransaction(fn) {
      const writes = [];
      await fn({
        get: (target) => target.get(),
        update(ref, fields) {
          writes.push({ op: "update", id: ref.id, fields: { ...fields } });
          store.set(ref.id, { ...store.get(ref.id), ...fields });
        },
        delete(ref) {
          writes.push({ op: "delete", id: ref.id });
          store.delete(ref.id);
        },
      });
      ops.push(...writes);
    },
  };
}

function emulatorEnv() {
  return { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };
}

test("allowlist refuses other documents and fields", () => {
  assert.doesNotThrow(() => assertAllowedDelete(DELETE_ID));
  assert.throws(() => assertAllowedDelete(UPDATE_ID), /Only temples\/devtamura/);
  assert.throws(() => assertAllowedDelete("tripura-sundari-temple"), /Refusing to delete/);
  assert.doesNotThrow(() =>
    assertAllowedUpdate(UPDATE_ID, { description: "A description that names Devtamura." }),
  );
  assert.throws(
    () => assertAllowedUpdate(DELETE_ID, { description: "nope" }),
    /Only temples\/chabimura/,
  );
  assert.throws(
    () => assertAllowedUpdate(UPDATE_ID, { description: "x", latitude: 23.542 }),
    /Only description/,
  );
  assert.throws(
    () => assertAllowedUpdate(UPDATE_ID, { story: "x" }),
    /Only description/,
  );
  assert.throws(
    () => assertAllowedUpdate(UPDATE_ID, { longitude: 91.6057 }),
    /Only description/,
  );
  assert.throws(() => assertAllowedUpdate(UPDATE_ID, {}), /Only description/);
  assert.throws(() => assertTripuraCount(10), /found 10/);
  assert.doesNotThrow(() => assertTripuraCount(11));
});

test("the committed description names Devtamura and is the live text plus one sentence", () => {
  assert.match(description, /Chabimura \(Chakrakma\)/);
  assert.match(description, /protected heritage monument\./);
  assert.match(
    description,
    /The site is also known as Devtamura, after the surrounding Devtamura hills\.$/,
  );
  assert.equal(description.includes("23.542"), false);
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
  assert.equal(db.store.get(DELETE_ID).latitude, 23.2319);
  assert.equal(db.store.get(UPDATE_ID).description.includes("Devtamura"), false);
  const text = lines.join("\n");
  assert.match(text, /Mode: dry-run/);
  assert.match(text, /chabimura description before:/);
  assert.match(text, /rock-carved panels\./);
  assert.match(text, /chabimura description after:/);
  assert.match(text, /also known as Devtamura/);
  assert.match(text, /delete temples\/devtamura fields: /);
  assert.match(text, /city/);
  assert.match(text, /photos/);
  assert.match(text, /delete temples\/devtamura photos\[\]: 2/);
  assert.match(text, /Tripura count: 11 to 10/);
  assert.match(text, /No Firestore writes/);
  assert.match(text, /1 stale entry \(devtamura\)/);
  assert.match(text, /does not call rebuild_index/);
  assert.equal(photosLength(db.store.get(DELETE_ID)), 2);
});

test("apply writes the backup, updates description, and deletes only devtamura", async () => {
  const db = fakeDb(seedDocs());
  const before = structuredClone(db.store.get(UPDATE_ID));
  const dir = mkdtempSync(join(tmpdir(), "chabimura-backup-"));
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
  assert.equal(db.store.has(DELETE_ID), false);
  const kept = db.store.get(UPDATE_ID);
  assert.equal(kept.description, description);
  assert.equal(kept.latitude, before.latitude);
  assert.equal(kept.longitude, before.longitude);
  assert.equal(kept.imageUrl, before.imageUrl);
  assert.deepEqual(kept.photos, before.photos);
  assert.equal(db.store.get("other-state").description, "Leave this document alone.");
  assert.equal(db.store.get("tripura-extra-0").state, "Tripura");
  assert.deepEqual(
    db.ops.map((op) => op.op),
    ["update", "delete"],
  );
  assert.deepEqual(db.ops[0], {
    op: "update",
    id: UPDATE_ID,
    fields: { description },
  });
  assert.deepEqual(db.ops[1], { op: "delete", id: DELETE_ID });
  const text = lines.join("\n");
  assert.match(text, new RegExp(`Backup: ${dir}`));
  const savedDev = JSON.parse(readFileSync(join(dir, "devtamura.json"), "utf8"));
  const savedChabi = JSON.parse(readFileSync(join(dir, "chabimura.json"), "utf8"));
  assert.equal(savedDev.path, "temples/devtamura");
  assert.equal(savedDev.data.latitude, 23.2319);
  assert.equal(savedDev.data.photos.length, 2);
  assert.equal(savedChabi.data.latitude, 23.542);
  assert.equal(savedChabi.data.longitude, 91.6057);
  assert.match(savedChabi.data.description, /rock-carved panels/);
  assert.equal(savedChabi.data.description.includes("Devtamura"), false);
});

test("a failed backup aborts before any Firestore write", async () => {
  const db = fakeDb(seedDocs());
  await assert.rejects(
    () =>
      applyMerge(db, {
        backupDir: join(tmpdir(), "unused"),
        description,
        log: () => {},
        writeBackup: () => {
          throw new Error("disk full");
        },
      }),
    /Backup failed: disk full/,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.store.has(DELETE_ID), true);
  assert.equal(db.store.get(UPDATE_ID).description.includes("Devtamura"), false);
});

test("preconditions abort with no writes", async () => {
  const cases = [
    {
      name: "missing devtamura",
      edit: (docs) => {
        delete docs[DELETE_ID];
      },
      pattern: /devtamura does not exist/,
    },
    {
      name: "wrong state",
      edit: (docs) => {
        docs[DELETE_ID] = devtamura({ state: "Assam" });
      },
      pattern: /not Tripura/,
    },
    {
      name: "no cover",
      edit: (docs) => {
        docs[UPDATE_ID] = chabimura({ imageUrl: "  " });
      },
      pattern: /no cover/,
    },
    {
      name: "no photos",
      edit: (docs) => {
        docs[UPDATE_ID] = chabimura({ photos: [] });
      },
      pattern: /no photos/,
    },
    {
      name: "tripura count",
      edit: (docs) => {
        delete docs["tripura-extra-0"];
      },
      pattern: /found 10/,
    },
  ];
  for (const item of cases) {
    const docs = seedDocs();
    item.edit(docs);
    const db = fakeDb(docs);
    await assert.rejects(() => inspectMerge(db, description), item.pattern);
    assert.deepEqual(db.ops, [], item.name);
    const dir = mkdtempSync(join(tmpdir(), "no-backup-"));
    await assert.rejects(
      () =>
        applyMerge(db, {
          backupDir: dir,
          description,
          log: () => {},
        }),
      item.pattern,
    );
    assert.deepEqual(db.ops, [], item.name);
    assert.equal(existsSync(join(dir, "devtamura.json")), false, item.name);
    assert.equal(existsSync(join(dir, "chabimura.json")), false, item.name);
  }
});

test("a description that already names Devtamura is left unchanged", async () => {
  const docs = seedDocs();
  docs[UPDATE_ID] = chabimura({
    description: "Chabimura is also known as Devtamura.",
  });
  const db = fakeDb(docs);
  const lines = [];
  const preview = await inspectMerge(db, description);
  assert.equal(preview.descriptionChanged, false);
  assert.match(formatReport(preview), /Left unchanged/);
  const dir = mkdtempSync(join(tmpdir(), "leave-description-"));
  await applyMerge(db, {
    backupDir: dir,
    description,
    log: (line) => lines.push(line),
  });
  assert.equal(db.store.get(UPDATE_ID).description, "Chabimura is also known as Devtamura.");
  assert.equal(db.store.has(DELETE_ID), false);
  assert.deepEqual(db.ops, [{ op: "delete", id: DELETE_ID }]);
});

test("apply refuses CI and does not write", async () => {
  const db = fakeDb(seedDocs());
  const dir = mkdtempSync(join(tmpdir(), "ci-backup-"));
  await assert.rejects(
    () =>
      main(["--apply", "--backup-dir", dir, "--project", "demo"], {
        env: { CI: "true", FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" },
        db,
      }),
    /CI/,
  );
  assert.deepEqual(db.ops, []);
  assert.equal(db.store.has(DELETE_ID), true);
});

test("parse rejects unknown arguments and defaults to dry-run", () => {
  assert.equal(parseArgs(["--project", "demo"]).apply, false);
  assert.equal(parseArgs(["--apply", "--project", "demo"]).dryRun, false);
  assert.throws(() => parseArgs(["--id", DELETE_ID]), /Unknown argument/);
  assert.throws(() => parseArgs(["--field", "latitude"]), /Unknown argument/);
  const source = readFileSync(join(here, "merge_devtamura_into_chabimura.js"), "utf8");
  assert.match(source, /ONE-USE/);
  assert.doesNotMatch(source, /from "\.\/rebuild_index\.js"/);
});

test("timestamp values in a backup stay readable", async () => {
  const admin = (await import("firebase-admin")).default;
  const stamp = new admin.firestore.Timestamp(1_700_000_000, 0);
  const plain = toPlain({ createdAt: stamp, latitude: 23.542 });
  assert.equal(plain.createdAt, "2023-11-14T22:13:20.000Z");
  assert.equal(plain.latitude, 23.542);
});

async function emulatorDb(project) {
  process.env.FIRESTORE_EMULATOR_HOST = emulatorHost;
  const admin = (await import("firebase-admin")).default;
  if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: project });
  }
  return admin.firestore();
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
  "emulator dry-run writes nothing and apply deletes and updates",
  { skip: onEmulator ? false : "Firestore emulator is not running" },
  async () => {
    const project = "demo-chabimura-merge";
    const db = await emulatorDb(project);
    const docs = seedDocs();
    await resetTemples(db, docs);
    const env = { FIRESTORE_EMULATOR_HOST: emulatorHost };
    const lines = [];
    await main(["--project", project], {
      env,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("dry-run must not confirm");
      },
    });
    assert.match(lines.join("\n"), /Tripura count: 11 to 10/);
    const afterDry = await db.collection("temples").doc(DELETE_ID).get();
    assert.equal(afterDry.exists, true);
    const dir = mkdtempSync(join(tmpdir(), "emulator-backup-"));
    await main(["--apply", "--backup-dir", dir, "--project", project], {
      env,
      log: (line) => lines.push(line),
      confirm: async () => {
        throw new Error("emulator apply must not confirm");
      },
    });
    const dev = await db.collection("temples").doc(DELETE_ID).get();
    const chabi = await db.collection("temples").doc(UPDATE_ID).get();
    const other = await db.collection("temples").doc("other-state").get();
    assert.equal(dev.exists, false);
    assert.equal(chabi.data().description, description);
    assert.equal(chabi.data().latitude, 23.542);
    assert.equal(chabi.data().longitude, 91.6057);
    assert.equal(other.data().state, "Kerala");
    const backup = JSON.parse(readFileSync(join(dir, "devtamura.json"), "utf8"));
    assert.equal(backup.data.photos.length, 2);
    assert.match(lines.join("\n"), /Backup: /);
    await assert.rejects(
      () =>
        main(["--apply", "--backup-dir", dir, "--project", project], {
          env,
          log: () => {},
        }),
      /devtamura does not exist/,
    );
    const still = await db.collection("temples").doc(UPDATE_ID).get();
    assert.equal(still.data().description, description);
  },
);
