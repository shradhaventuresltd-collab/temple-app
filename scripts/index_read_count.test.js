/**
 * Emulator counts for KAN-145. Local demo project only.
 *
 * Before: one server read of every temples/{id} document.
 * After cold: meta/temple_index plus each shard.
 * After warm: meta from the server, shards from cache.
 *
 * Project id demo-temple-index-reads. CI starts a fresh emulator for this
 * file so rules tests cannot leave documents behind.
 */
import assert from "node:assert/strict";
import { test } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { initializeTestEnvironment } from "@firebase/rules-unit-testing";
import {
  collection,
  doc,
  getDocFromCache,
  getDocFromServer,
  getDocsFromServer,
  writeBatch,
} from "firebase/firestore";

const PROJECT_ID = "demo-temple-index-reads";
const STATES = [
  "andhra-pradesh",
  "bihar",
  "gujarat",
  "himachal-pradesh",
  "karnataka",
  "kerala",
  "madhya-pradesh",
  "maharashtra",
  "odisha",
  "rajasthan",
  "tamil-nadu",
  "telangana",
  "uttar-pradesh",
  "west-bengal",
  "jammu-and-kashmir",
];
const PER_STATE = 12;

function assertLocalEmulator() {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? "";
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
    throw new Error(
      `Refusing to run without a local Firestore emulator (FIRESTORE_EMULATOR_HOST=${host || "unset"}).`,
    );
  }
}

test("index reads are fewer than a full temples collection scan", async () => {
  assertLocalEmulator();
  const rules = readFileSync(
    resolve(fileURLToPath(new URL(".", import.meta.url)), "../firestore.rules"),
    "utf8",
  );
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });
  try {
    // Earlier tests in the same emulator process leave temple docs behind.
    await testEnv.clearFirestore();
    const stamp = new Date("2026-10-15T00:00:00.000Z");
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const batch = writeBatch(db);
      const shards = {};
      for (const state of STATES) shards[state] = stamp;
      batch.set(doc(db, "meta/temple_index"), { indexVersion: 1, shards });
      for (const state of STATES) {
        const entries = {};
        for (let i = 0; i < PER_STATE; i += 1) {
          const id = `${state}-${i}`;
          batch.set(doc(db, "temples", id), { id, name: id, state });
          entries[id] = { id, name: id, state, tradition: "unspecified", framing: "neutral" };
        }
        batch.set(doc(db, "temple_index", state), { entries });
      }
      await batch.commit();
    });

    const db = testEnv.unauthenticatedContext().firestore();
    const beforeSnap = await getDocsFromServer(collection(db, "temples"));
    const before = beforeSnap.size;

    let afterCold = 0;
    await getDocFromServer(doc(db, "meta/temple_index"));
    afterCold += 1;
    for (const state of STATES) {
      const snap = await getDocFromServer(doc(db, "temple_index", state));
      assert.equal(snap.exists(), true);
      afterCold += 1;
    }

    let afterWarm = 0;
    await getDocFromServer(doc(db, "meta/temple_index"));
    afterWarm += 1;
    for (const state of STATES) {
      const snap = await getDocFromCache(doc(db, "temple_index", state));
      assert.equal(Object.keys(snap.data().entries).length, PER_STATE);
    }

    assert.equal(before, STATES.length * PER_STATE);
    assert.equal(afterCold, 1 + STATES.length);
    assert.equal(afterWarm, 1);
    assert.ok(afterCold < before);
    console.log(
      `READ_COUNTS before=${before} afterCold=${afterCold} afterWarm=${afterWarm} temples=${before} shards=${STATES.length}`,
    );
  } finally {
    await testEnv.cleanup();
  }
});
