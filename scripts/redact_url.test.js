import assert from "node:assert/strict";
import { test } from "node:test";

import { redactDownloadToken } from "./redact_url.js";

const cover =
  "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fvirupaksha-temple%2F01.jpg?alt=media&token=secret-token";

test("a download token query value is replaced and the rest of the URL stays", () => {
  assert.equal(
    redactDownloadToken(cover),
    "https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fvirupaksha-temple%2F01.jpg?alt=media&token=<redacted>",
  );
});

test("a leading token parameter leaves the following parameters", () => {
  assert.equal(
    redactDownloadToken("https://firebasestorage.googleapis.com/v0/b/b/o/a?token=abc&alt=media"),
    "https://firebasestorage.googleapis.com/v0/b/b/o/a?token=<redacted>&alt=media",
  );
});

test("a URL with no token is unchanged", () => {
  const plain = "https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg";
  assert.equal(redactDownloadToken(plain), plain);
  assert.equal(redactDownloadToken(""), "");
  assert.equal(redactDownloadToken(undefined), "");
  assert.equal(redactDownloadToken(null), "");
});

test("a token inside a log line is redacted, including quotes and a hash", () => {
  const line = `imageUrl: '${cover}#cover',`;
  assert.equal(
    redactDownloadToken(line),
    "imageUrl: 'https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fvirupaksha-temple%2F01.jpg?alt=media&token=<redacted>#cover',",
  );
});

test("every token query in one line is redacted", () => {
  const line = `${cover} and https://example.com/t?alt=media&token=other`;
  const redacted = redactDownloadToken(line);
  assert.equal(redacted.includes("secret-token"), false);
  assert.equal(redacted.includes("token=other"), false);
  assert.equal(redacted.split("token=<redacted>").length, 3);
});

test("metadata token names that are not the query parameter stay", () => {
  assert.equal(
    redactDownloadToken("firebaseStorageDownloadTokens=secret-token"),
    "firebaseStorageDownloadTokens=secret-token",
  );
  assert.equal(
    redactDownloadToken("firebaseStorageDownloadTokens%3Dsecret-token"),
    "firebaseStorageDownloadTokens%3Dsecret-token",
  );
});

test("token matches any case, including a leading ampersand", () => {
  assert.equal(
    redactDownloadToken("https://example.com/a?alt=media&Token=AbC"),
    "https://example.com/a?alt=media&Token=<redacted>",
  );
  assert.equal(
    redactDownloadToken("https://example.com/a?TOKEN=AbC&alt=media"),
    "https://example.com/a?TOKEN=<redacted>&alt=media",
  );
});

test("a percent-encoded token nested in another URL is redacted", () => {
  const nested =
    "https://example.com/go?next=https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fb%2Fo%2Fa.jpg%3Falt%3Dmedia%26token%3Dsecret-token%26x%3D1";
  const redacted = redactDownloadToken(nested);
  assert.equal(redacted.includes("secret-token"), false);
  assert.equal(
    redacted,
    "https://example.com/go?next=https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Fb%2Fo%2Fa.jpg%3Falt%3Dmedia%26token%3D<redacted>%26x%3D1",
  );
  assert.equal(
    redactDownloadToken("wrapped %3FToken%3Dnested-secret#tail"),
    "wrapped %3FToken%3D<redacted>#tail",
  );
  assert.equal(
    redactDownloadToken("https://example.com/a?alt=media%26token%3Dabc%2Fdef"),
    "https://example.com/a?alt=media%26token%3D<redacted>",
  );
});
