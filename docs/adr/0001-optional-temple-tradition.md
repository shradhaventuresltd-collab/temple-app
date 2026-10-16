# Optional `tradition` on a temple document

Status: accepted. Narrow exception to the Hybrid C schema freeze.

Temple documents stay on the frozen field set (`name`, `state`, `city`, `deity`, `description`, `story`, `address`, `timings`, `specialities`, `imageUrl`, `images`, `photos`, `latitude`, `longitude`, and `createdAt`). This decision adds one optional field and no others.

`temples/{id}.tradition`, when present, is exactly `jain`, `buddhist`, or `sikh`. Absent means a Hindu listing. Null and any other string are rejected by the rules. The app does not invent this value from the name, description, story, or specialities.

`traditionOf` reads that field first. If it is absent, it falls back to the structured `deity` string only. The index entry keeps the same `tradition` flag it has today (`jain`, `buddhist`, `sikh`, or `unspecified`), so browse does not gain a read. A correction is a field patch, not a code change.
