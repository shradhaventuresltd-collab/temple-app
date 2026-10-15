/**
 * @google-cloud/storage asks google-auth-library for a token through gaxios,
 * and gaxios 6 uses node-fetch. node-fetch cannot read the gzip body Google
 * returns from the token endpoint ("Premature close"). Native fetch can.
 * The patch applies only to that token request, so Storage downloads keep
 * the client they already use.
 *
 * Importing this module installs the patch. Call `assertStorageAuth` once
 * in --apply, before any Firestore write.
 */
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

/** Bucket these scripts upload into. */
export const STORAGE_AUTH_BUCKET = "temple-directory-india.firebasestorage.app";

/** exists() on this object only checks that the token request succeeded. */
export const STORAGE_AUTH_PROBE = "temples/.storage-auth-preflight";

export const STORAGE_AUTH_PREFLIGHT_ERROR = "Storage auth preflight failed. No Firestore write.";

const TOKEN_URL = /^https:\/\/(?:oauth2\.googleapis\.com\/|www\.googleapis\.com\/oauth2\/)/;

let patched = false;

function loadGaxios() {
  try {
    return require("gaxios").Gaxios;
  } catch (error) {
    if (error?.code === "MODULE_NOT_FOUND") return null;
    throw error;
  }
}

/**
 * Installs the native-fetch patch when gaxios is installed. The script
 * test job does not install node_modules, so a missing package is not a
 * failure until a real Storage call needs it.
 */
export function useNativeFetchForStorageAuth() {
  if (patched) return true;
  const Gaxios = loadGaxios();
  if (!Gaxios) return false;
  if (typeof globalThis.fetch !== "function") {
    throw new Error("This Node has no fetch. No Firestore write.");
  }
  patched = true;
  const original = Gaxios.prototype._defaultAdapter;
  Gaxios.prototype._defaultAdapter = function nativeTokenFetch(opts) {
    const url = typeof opts?.url === "string" ? opts.url : String(opts?.url ?? "");
    if (!opts?.fetchImplementation && TOKEN_URL.test(url)) {
      return original.call(this, {
        ...opts,
        fetchImplementation: (input, init) => globalThis.fetch(input, init),
      });
    }
    return original.call(this, opts);
  };
  return true;
}

/**
 * Read-only. A thrown exists() is an auth failure, and apply must stop
 * before it writes Firestore. A missing probe object is still a success.
 */
export async function assertStorageAuth(bucket, objectPath = STORAGE_AUTH_PROBE) {
  useNativeFetchForStorageAuth();
  try {
    await bucket.file(objectPath).exists();
  } catch (error) {
    console.error(error?.message || error);
    throw new Error(STORAGE_AUTH_PREFLIGHT_ERROR);
  }
}
