import assert from "node:assert/strict";
import { test } from "node:test";
import { BAD_PHOTOS, GOOD_PHOTOS, prodPhoto } from "./photo_cases.js";
import { isPlaceholderHost, photoError, photoMirror, photosError } from "../src/photo_validator.js";

test("rules-accepted photos pass", () => {
  for (const [name, photo] of Object.entries(GOOD_PHOTOS)) {
    assert.equal(photoError(photo), null, name);
  }
});

test("rules-refused photos fail", () => {
  for (const [name, photo] of Object.entries(BAD_PHOTOS)) {
    assert.notEqual(photoError(photo), null, name);
  }
});

test("lists of 0, 1, 2, 9 and 12 prod-shaped photos pass; 13 fails", () => {
  for (const n of [0, 1, 2, 9, 12]) {
    const photos = Array.from({ length: n }, (_, i) => prodPhoto("t", i));
    assert.equal(photosError(photos), null, `${n} photos`);
  }
  const thirteen = Array.from({ length: 13 }, (_, i) => prodPhoto("t", Math.min(i, 11)));
  assert.match(photosError(thirteen), /at most 12/);
});

test("a bad photo anywhere in the list fails", () => {
  for (const at of [0, 4, 11]) {
    const photos = Array.from({ length: 12 }, (_, i) => prodPhoto("t", i));
    photos[at] = BAD_PHOTOS["http url"];
    assert.match(photosError(photos), new RegExp(`photos\\[${at}\\]`));
  }
});

test("photos must be a list", () => {
  for (const value of [undefined, null, "x", 3, { 0: prodPhoto("t", 0) }]) {
    assert.equal(photosError(value), "photos must be a list");
  }
});

test("placeholder cover is refused, like the rules on imageUrl", () => {
  assert.ok(isPlaceholderHost("https://picsum.photos/200"));
  assert.ok(isPlaceholderHost("https://a.b.placehold.co/x"));
  assert.ok(isPlaceholderHost("https://user@source.unsplash.com:443/x"));
  assert.ok(!isPlaceholderHost("https://x.source.unsplash.com/x"));
  assert.ok(!isPlaceholderHost("https://upload.wikimedia.org/picsum.photos.jpg"));
  const cover = { ...prodPhoto("t", 0), url: "https://picsum.photos/600" };
  assert.match(photosError([cover]), /placeholder/);
  // Only the cover is checked, as in the rules (imageUrl and images[0]).
  assert.equal(photosError([prodPhoto("t", 0), { ...prodPhoto("t", 1), url: "https://picsum.photos/1" }]), null);
});

test("mirror is the cover url and the urls in list order", () => {
  const photos = [prodPhoto("t", 0), prodPhoto("t", 1)];
  assert.deepEqual(photoMirror(photos), { imageUrl: photos[0].url, images: [photos[0].url, photos[1].url] });
  assert.deepEqual(photoMirror([]), { imageUrl: "", images: [] });
});

test("strings longer than 4000 UTF-16 units are refused without spreading", () => {
  const huge = `https://example.com/${"a".repeat(5000)}`;
  assert.match(photoError({ url: huge, licence: "CC0", order: 0 }), /over 2000/);
  assert.match(photoError({ ...prodPhoto("t", 0), credit: "c".repeat(5000) }), /over 200/);
});
