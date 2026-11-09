/**
 * Photo cases shared by the callable tests (functions/test) and the rules
 * parity test (scripts/temple_index_rules.test.js). Each `bad` case must be
 * refused by both firestore.rules (create path) and photoError().
 */
const TOKEN = "00000000-0000-4000-8000-000000000000";
export const dl = (id, i, size) =>
  `https://firebasestorage.googleapis.com/v0/b/app/o/temples%2F${id}%2Fphoto_${i}_${size}.jpg?alt=media&token=${TOKEN}`;

export function prodPhoto(id, i, extra = {}) {
  return {
    url: dl(id, i, "full"),
    credit: `Contributor ${i} · CC BY-SA 4.0`,
    licence: "CC-BY-SA",
    order: i,
    thumbUrl: dl(id, i, "480"),
    galleryUrl: dl(id, i, "1080"),
    ...extra,
  };
}

const base = prodPhoto("case", 0);
const without = (key) => Object.fromEntries(Object.entries(base).filter(([k]) => k !== key));

export const GOOD_PHOTOS = {
  "prod-shaped CC-BY-SA": base,
  "CC0 without credit": { url: base.url, licence: "CC0", order: 0 },
  "Own with empty credit": { url: base.url, licence: "Own", order: 0, credit: "" },
  "Permission with credit": { url: base.url, licence: "Permission", order: 0, credit: "Temple trust" },
  "CC-BY with credit": { ...base, licence: "CC-BY" },
  "order 11": { ...base, order: 11 },
  "credit of 200": { ...base, credit: "c".repeat(200) },
  "url of 2000": { ...base, url: `https://example.com/${"a".repeat(2000 - 20)}` },
  // Emoji at the limit: rules size() is UTF-8 bytes; the validator counts
  // code points. Size so UTF-8 bytes hit 200 / 2000 (code points stay under).
  "credit of 200 with emoji": { ...base, credit: `${"c".repeat(196)}😀` },
  "url of 2000 with emoji": {
    ...base,
    url: `https://example.com/${"a".repeat(2000 - 20 - 4)}😀`,
  },
  "thumb only": without("galleryUrl"),
  "gallery only": without("thumbUrl"),
};

export const BAD_PHOTOS = {
  "http url": { ...base, url: "http://example.com/a.jpg" },
  "whitespace in url": { ...base, url: "https://example.com/a b.jpg" },
  "tab in url": { ...base, url: "https://example.com/a\tb.jpg" },
  "newline in url": { ...base, url: "https://example.com/a\nb.jpg" },
  "cr in url": { ...base, url: "https://example.com/a\rb.jpg" },
  "form feed in url": { ...base, url: "https://example.com/a\fb.jpg" },
  "url of 2001": { ...base, url: `https://example.com/${"a".repeat(2001 - 20)}` },
  "url not a string": { ...base, url: ["https://example.com/a.jpg"] },
  "missing url": without("url"),
  "unknown licence": { ...base, licence: "All rights reserved" },
  "lowercase licence": { ...base, licence: "cc0" },
  "missing licence": without("licence"),
  "extra key": { ...base, uploader: "someone" },
  "missing order": without("order"),
  "order 12": { ...base, order: 12 },
  "order -1": { ...base, order: -1 },
  "order float": { ...base, order: 0.5 },
  "order string": { ...base, order: "0" },
  "CC-BY without credit": { ...without("credit"), licence: "CC-BY" },
  "CC-BY-SA empty credit": { ...base, credit: "" },
  "credit of 201": { ...base, credit: "c".repeat(201) },
  "credit not a string": { ...base, credit: 7 },
  "credit null": { ...base, credit: null },
  "http thumbUrl": { ...base, thumbUrl: "http://example.com/t.jpg" },
  "thumbUrl null": { ...base, thumbUrl: null },
  "galleryUrl not a string": { ...base, galleryUrl: 42 },
  "photo is a string": base.url,
  "photo is a list": [base],
};
