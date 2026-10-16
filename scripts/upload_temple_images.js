/**
 * Google Places photo mirroring is removed (KAN-167).
 * Covers come from tools/photo-packs via upload_research_pack.js.
 * This command does not call Places and does not upload.
 */
console.error("Google Places photo mirroring is removed (KAN-167). No upload.");
process.exit(1);
