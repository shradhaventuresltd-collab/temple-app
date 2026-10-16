import assert from "node:assert/strict";
import { test } from "node:test";

import { downloadTokenUrl, ensureDownloadToken, withDownloadToken } from "./download_token.js";

test("an existing download token is reused and a missing one is stored", async () => {
  const reused = await ensureDownloadToken(
    {
      name: "temples/shore/01.jpg",
      async getMetadata() {
        return [{ metadata: { firebaseStorageDownloadTokens: "kept,other" } }];
      },
      async setMetadata() {
        throw new Error("set");
      },
    },
    "temple-directory-india.firebasestorage.app",
  );
  assert.equal(reused.exists, true);
  assert.equal(reused.token, "kept");
  assert.equal(
    reused.url,
    downloadTokenUrl("temple-directory-india.firebasestorage.app", "temples/shore/01.jpg", "kept"),
  );
  assert.equal(new URL(reused.url).hostname, "firebasestorage.googleapis.com");

  let stored = null;
  const minted = await ensureDownloadToken(
    {
      name: "temples/shore/02.jpg",
      async getMetadata() {
        return [{ metadata: { note: "keep" } }];
      },
      async setMetadata(metadata) {
        stored = metadata;
      },
    },
    "bucket",
    "temples/shore/02.jpg",
    { newToken: "minted" },
  );
  assert.equal(minted.token, "minted");
  assert.equal(stored.metadata.firebaseStorageDownloadTokens, "minted");
  assert.equal(stored.metadata.note, "keep");

  let wrote = false;
  const missing = await ensureDownloadToken(
    {
      name: "temples/shore/03.jpg",
      async getMetadata() {
        const error = new Error("No such object: 404");
        error.code = 404;
        throw error;
      },
      async setMetadata() {
        wrote = true;
      },
    },
    "bucket",
    undefined,
    { newToken: "new-object" },
  );
  assert.equal(missing.exists, false);
  assert.equal(missing.token, "new-object");
  assert.equal(wrote, false);
  const metadata = withDownloadToken({ contentType: "image/jpeg", cacheControl: "public, max-age=3600" }, missing.token);
  assert.equal(metadata.contentType, "image/jpeg");
  assert.equal(metadata.metadata.firebaseStorageDownloadTokens, "new-object");
  assert.equal(metadata.predefinedAcl, undefined);
});