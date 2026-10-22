import assert from "node:assert/strict";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import {
  GALLERY_CAP_PX,
  authorizeApply,
  backupPath,
  classifyWikimediaImage,
  formatCapReport,
  main,
  parseArgs,
  persistCappedImages,
  planTemple,
  requireBackupDir,
  writeBackup,
} from "./cap_wikimedia_images.js";

const here = dirname(fileURLToPath(import.meta.url));
const emulator = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080" };
const keesara =
  "https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg";
const keesara1280 =
  "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Keesara_gutta_main_temple_gate.jpg/1280px-Keesara_gutta_main_temple_gate.jpg";
const storage = "https://storage.googleapis.com/bucket/temples/shore/01.jpg";
const svg = "https://upload.wikimedia.org/wikipedia/commons/8/84/Example.svg";

function tempDir() {
  return mkdtempSync(join(tmpdir(), "kan175-"));
}

function fastNet(extra = {}) {
  return { attempts: 1, backoffMs: 0, timeoutMs: 60, ...extra };
}

test("commons images[] map to a 1280px thumb", () => {
  assert.equal(GALLERY_CAP_PX, 1280);
  const cases = JSON.parse(
    readFileSync(resolve(here, "fixtures/wikimedia_gallery_cap_cases.json"), "utf8"),
  );
  assert.ok(cases.length > 0);
  for (const row of cases) {
    const capped = classifyWikimediaImage(row.url);
    assert.equal(capped.url, row.expect, row.name);
    assert.equal(capped.reason, row.reason, row.name);
  }
});

test("a paired photos[] url is not rewritten and a sibling original is", () => {
  const wide =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Keesara_gutta_main_temple_gate.jpg/1920px-Keesara_gutta_main_temple_gate.jpg";
  const temple = {
    id: "keesaragutta-temple",
    imageUrl: keesara,
    images: [keesara, wide, svg, storage, 12],
    photos: [{ url: keesara, licence: "CC0", credit: "Ada", order: 0 }],
  };
  const planned = planTemple(temple);
  assert.equal(planned.changed, true);
  assert.equal(planned.images[0], keesara);
  assert.equal(planned.images[1], keesara1280);
  assert.equal(planned.images[2], svg);
  assert.equal(planned.images[3], storage);
  assert.equal(planned.images[4], 12);
  assert.equal(planned.rows[0].reason, "has-photo");
  assert.equal(planned.rows[1].action, "rewrite");
  assert.equal(planned.rows[2].reason, "svg");
  assert.equal(planned.rows[3].reason, "not-wikimedia");
  assert.equal(planned.rows[4].reason, "not-url");
  assert.equal(temple.imageUrl, keesara);
  assert.equal(temple.photos[0].url, keesara);
});

test("dry-run lists rewrites and does not write or back up", async () => {
  const lines = [];
  const dir = tempDir();
  let writes = 0;
  let backups = 0;
  const rows = await main(["--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet(),
    log: (line) => lines.push(line),
    load: async () => [
      {
        id: "keesaragutta-temple",
        imageUrl: keesara,
        images: [keesara, storage],
        photos: [],
      },
    ],
    writeImages: async () => {
      writes += 1;
      return { ok: true };
    },
    backup: async () => {
      backups += 1;
    },
  });
  assert.equal(writes, 0);
  assert.equal(backups, 0);
  assert.equal(rows.filter((row) => row.result === "would-upload").length, 1);
  assert.equal(rows.find((row) => row.result === "skipped").reason, "not-wikimedia");
  const text = lines.join("\n");
  assert.match(text, /would-upload keesaragutta-temple 0/);
  assert.match(text, /Dry-run only/);
  assert.match(text, /summary written=0 failed=0 skipped=1 \(not-wikimedia=1\) pending=1 elapsed=/);
  assert.match(text, /APPLY-FINISHED/);
  assert.equal(text.includes(dir), false);
});

test("apply writes only images[] after a backup and prints APPLY-FINISHED", async () => {
  const lines = [];
  let code = null;
  const dir = tempDir();
  const patches = [];
  const temple = {
    id: "keesaragutta-temple",
    imageUrl: keesara,
    images: [keesara, storage, svg],
    photos: [{ url: "https://example.com/other.jpg", licence: "CC0", credit: "", order: 0, galleryUrl: "https://example.com/g.jpg" }],
    description: "leave me",
  };
  await main(
    ["--apply", "--backup-dir", dir, "--project", "demo-temple-index"],
    {
      env: emulator,
      ...fastNet(),
      log: (line) => lines.push(line),
      exit: (status) => {
        code = status;
      },
      confirm: async () => {
        throw new Error("emulator apply must not prompt");
      },
      load: async () => [temple],
      writeImages: async (assigned) => {
        writeBackup(dir, assigned.id, assigned.images);
        patches.push(assigned);
        return { ok: true };
      },
    },
  );
  assert.equal(code, 0);
  assert.equal(patches.length, 1);
  assert.deepEqual(Object.keys(patches[0]).sort(), ["id", "images", "next"]);
  assert.deepEqual(patches[0].next, [keesara1280, storage, svg]);
  assert.equal(patches[0].next.includes(temple.description), false);
  const saved = JSON.parse(readFileSync(join(dir, "keesaragutta-temple.json"), "utf8"));
  assert.deepEqual(Object.keys(saved).sort(), ["id", "images"]);
  assert.deepEqual(saved.images, [keesara, storage, svg]);
  assert.equal(JSON.stringify(saved).includes("galleryUrl"), false);
  const text = lines.join("\n");
  assert.match(text, /summary written=1 failed=0 skipped=2 \(not-wikimedia=1 svg=1\) elapsed=/);
  assert.match(text, /APPLY-FINISHED/);
  assert.match(text, /Wrote images\[\] only/);
  assert.doesNotMatch(text, /APPLY-INCOMPLETE/);
});

test("the firestore patch is images[] and a backup failure does not update", async () => {
  const temple = {
    id: "keesaragutta-temple",
    imageUrl: keesara,
    images: [keesara],
    photos: [],
    description: "keep",
  };
  const planned = planTemple(temple);
  const updates = [];
  const db = {
    collection() {
      return { doc: () => ({ id: temple.id }) };
    },
    async runTransaction(fn) {
      return fn({
        get: async () => ({
          exists: true,
          id: temple.id,
          data: () => structuredClone(temple),
        }),
        update: (_ref, patch) => {
          updates.push(patch);
          temple.images = patch.images;
        },
      });
    },
  };
  let backed = null;
  const result = await persistCappedImages(db, {
    id: temple.id,
    images: [keesara],
    next: planned.images,
  }, async (id, images) => {
    backed = { id, images };
  });
  assert.equal(result.ok, true);
  assert.deepEqual(backed.images, [keesara]);
  assert.equal(updates.length, 1);
  assert.deepEqual(Object.keys(updates[0]), ["images"]);
  assert.deepEqual(updates[0].images, [keesara1280]);
  assert.equal(temple.description, "keep");
  assert.equal(temple.imageUrl, keesara);

  updates.length = 0;
  const again = structuredClone({ ...temple, images: [keesara] });
  const refusing = {
    collection() {
      return { doc: () => ({ id: again.id }) };
    },
    async runTransaction(fn) {
      return fn({
        get: async () => ({ exists: true, id: again.id, data: () => structuredClone(again) }),
        update: () => {
          updates.push("nope");
        },
      });
    },
  };
  await assert.rejects(
    () =>
      persistCappedImages(
        refusing,
        { id: again.id, images: again.images, next: [keesara1280] },
        async () => {
          throw new Error("disk full");
        },
      ),
    /disk full/,
  );
  assert.deepEqual(updates, []);
});

test("a document that changed is skipped and a failed write is incomplete", async () => {
  const lines = [];
  let code = null;
  const dir = tempDir();
  await main(["--apply", "--backup-dir", dir, "--project", "demo-temple-index"], {
    env: emulator,
    ...fastNet(),
    log: (line) => lines.push(line),
    exit: (status) => {
      code = status;
    },
    load: async () => [{ id: "moved-temple", images: [keesara], photos: [] }],
    writeImages: async () => ({ ok: false, reason: "changed" }),
  });
  assert.equal(code, 0);
  assert.match(lines.join("\n"), /summary written=0 failed=0 skipped=1 \(changed=1\) elapsed=/);
  assert.match(lines.join("\n"), /APPLY-FINISHED/);

  const failedLines = [];
  let failedCode = null;
  await assert.rejects(
    () =>
      main(["--apply", "--backup-dir", dir, "--project", "demo-temple-index"], {
        env: emulator,
        ...fastNet(),
        log: (line) => failedLines.push(line),
        exit: (status) => {
          failedCode = status;
        },
        load: async () => [{ id: "broken-temple", images: [keesara], photos: [] }],
        writeImages: async () => {
          throw new Error("write rejected");
        },
      }),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(failedCode, 1);
  const text = failedLines.join("\n");
  assert.match(text, /summary written=0 failed=1 skipped=0 elapsed=/);
  assert.match(text, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
  assert.match(text, /write rejected/);
});

test("--apply refuses CI and a missing backup dir before any read", async () => {
  let loads = 0;
  let confirmed = 0;
  await assert.rejects(
    () =>
      authorizeApply("temple-directory-india", { CI: "true" }, {
        confirm: async () => {
          confirmed += 1;
          return "temple-directory-india";
        },
      }),
    /CI/,
  );
  await assert.rejects(
    () =>
      main(["--apply", "--backup-dir", tempDir(), "--project", "temple-directory-india"], {
        env: { CI: "true" },
        confirm: async () => {
          confirmed += 1;
          return "temple-directory-india";
        },
        load: async () => {
          loads += 1;
          return [];
        },
      }),
    /CI/,
  );
  assert.throws(() => requireBackupDir(""), /backup-dir/);
  await assert.rejects(
    () =>
      main(["--apply", "--project", "demo-temple-index"], {
        env: emulator,
        confirm: async () => {
          confirmed += 1;
          return "demo-temple-index";
        },
        load: async () => {
          loads += 1;
          return [];
        },
        writeImages: async () => {
          throw new Error("missing backup must not write");
        },
      }),
    /backup-dir/,
  );
  assert.equal(confirmed, 0);
  assert.equal(loads, 0);
  assert.equal(parseArgs(["--project", "demo-temple-index"]).dryRun, true);
  assert.equal(parseArgs(["--project", "demo-temple-index"]).apply, false);
  assert.throws(() => backupPath(tempDir(), "../escape"), /backup file name/);
  const source = readFileSync(resolve(here, "cap_wikimedia_images.js"), "utf8");
  assert.match(source, /assertNotCi/);
  assert.match(source, /--apply needs --backup-dir/);
  assert.match(source, /APPLY-FINISHED/);
  assert.match(source, /APPLY-INCOMPLETE/);
  assert.match(
    source,
    /prod --apply is run only by the Deployer agent or Sanu, dry run first, never from CI/,
  );
  assert.match(source, /28 older temples/);
  assert.doesNotMatch(source, /private_key/);
  assert.doesNotMatch(source, /collection\("temple_index"\)/);
  const report = formatCapReport(
    [{ id: "shore", index: 0, result: "uploaded", url: `${storage}?token=super-secret` }],
    { apply: true },
  );
  assert.equal(report.includes("super-secret"), false);
});

test("a hanging write times out and prints APPLY-INCOMPLETE", { timeout: 5_000 }, async () => {
  const lines = [];
  let code = null;
  await assert.rejects(
    () =>
      main(
        ["--apply", "--timeout-ms", "40", "--backup-dir", tempDir(), "--project", "demo-temple-index"],
        {
          env: emulator,
          ...fastNet({ attempts: 1 }),
          log: (line) => lines.push(line),
          exit: (status) => {
            code = status;
          },
          load: async () => [{ id: "hang-temple", images: [keesara], photos: [] }],
          writeImages: () => new Promise(() => {}),
        },
      ),
    /APPLY-INCOMPLETE/,
  );
  assert.equal(code, 1);
  const text = lines.join("\n");
  assert.match(text, /firestore write timed out/);
  assert.match(text, /summary written=0 failed=1 skipped=0 elapsed=/);
  assert.match(text, /APPLY-INCOMPLETE/);
  assert.doesNotMatch(text, /APPLY-FINISHED/);
});
