#!/usr/bin/env node
/**
 * Grant (or revoke) the Firebase Auth custom claim `admin: true`.
 *
 * Requires a service-account JSON for project temple-directory-india
 * (gitignored — never commit it):
 *   Firebase Console → Project settings → Service accounts → Generate new private key
 *   Save as service-account.json at the repo root or in scripts/
 *
 * Usage:
 *   node scripts/grant_admin.js --email you@example.com
 *   node scripts/grant_admin.js --uid <firebaseUid>
 *   node scripts/grant_admin.js --email you@example.com --revoke
 */
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import admin from "firebase-admin";

const __dirname = dirname(fileURLToPath(import.meta.url));

const saPath = [
  resolve(__dirname, "service-account.json"),
  resolve(__dirname, "..", "service-account.json"),
].find((p) => {
  try {
    readFileSync(p);
    return true;
  } catch {
    return false;
  }
});

if (!saPath) {
  console.error(
    "\n✖  service-account.json not found.\n" +
      "   Download it from Firebase Console → Project Settings → Service Accounts → Generate New Private Key\n" +
      "   Place it in the project root or the scripts/ folder. Do not commit it.\n"
  );
  process.exit(1);
}

function argValue(flag) {
  const index = process.argv.indexOf(flag);
  if (index === -1 || index + 1 >= process.argv.length) return null;
  return process.argv[index + 1];
}

const email = argValue("--email");
const uidArg = argValue("--uid");
const revoke = process.argv.includes("--revoke");

if (!email && !uidArg) {
  console.error(
    "Usage: node scripts/grant_admin.js --email you@example.com [--revoke]\n" +
      "   or: node scripts/grant_admin.js --uid <firebaseUid> [--revoke]"
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(readFileSync(saPath, "utf8"))),
});

const auth = admin.auth();
const user = email ? await auth.getUserByEmail(email) : await auth.getUser(uidArg);
const claims = { ...(user.customClaims ?? {}) };

if (revoke) {
  delete claims.admin;
} else {
  claims.admin = true;
}

await auth.setCustomUserClaims(user.uid, claims);

console.log(
  revoke
    ? `✔  Removed admin claim from ${user.email ?? user.uid} (${user.uid})`
    : `✔  Granted admin: true to ${user.email ?? user.uid} (${user.uid})`
);
console.log(
  "   The user must refresh their ID token (tap “Refresh admin status” or sign out and back in)."
);
