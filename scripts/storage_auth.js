/**
 * @google-cloud/storage asks google-auth-library for a token through gaxios,
 * and gaxios 6 uses node-fetch. node-fetch cannot read the gzip body Google
 * returns from the token endpoint ("Premature close"). Native fetch can.
 * The patch applies only to the two OAuth token URLs. Every other request,
 * including Storage downloads and userinfo, keeps the default adapter.
 *
 * The patch installs on the first call to `useNativeFetchForStorageAuth`.
 * Call `assertStorageAuth` once in --apply, before any Firestore write.
 */
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

/** Bucket these scripts upload into. */
export const STORAGE_AUTH_BUCKET = "temple-directory-india.firebasestorage.app";

/** exists() on this object only checks that the token request succeeded. */
export const STORAGE_AUTH_PROBE = "temples/.storage-auth-preflight";

export const STORAGE_AUTH_PREFLIGHT_ERROR = "Storage auth preflight failed. No Firestore write.";

/** Origin and path, with no query and no extra segment. */
const TOKEN_ENDPOINTS = new Set([
  "https://www.googleapis.com/oauth2/v4/token",
  "https://oauth2.googleapis.com/token",
]);

let decided = false;
let patched = false;
let savedPrototype = null;
let savedAdapter = null;

/**
 * True only for the two token endpoints. A different path on the same host,
 * such as /oauth2/v3/userinfo, is not a token request.
 */
export function isStorageTokenUrl(value) {
  try {
    const url = value instanceof URL ? new URL(value.href) : new URL(String(value ?? ""));
    return TOKEN_ENDPOINTS.has(`${url.origin}${url.pathname}`);
  } catch {
    return false;
  }
}

function loadGaxios() {
  try {
    return require("gaxios").Gaxios;
  } catch (error) {
    if (error?.code === "MODULE_NOT_FOUND") return null;
    throw error;
  }
}

/**
 * Installs the native-fetch patch on the first call when gaxios is present,
 * its adapter is still the one this patch knows, and no HTTPS proxy is set.
 * Returns false when gaxios is missing or the patch is intentionally skipped.
 */
export function useNativeFetchForStorageAuth() {
  if (decided) return patched;
  const Gaxios = loadGaxios();
  if (!Gaxios) return false;

  if (process.env.HTTPS_PROXY) {
    console.log(
      "HTTPS_PROXY is set; skipping the native fetch override so the proxy agent is used.",
    );
    decided = true;
    return false;
  }

  if (typeof globalThis.fetch !== "function") {
    throw new Error("This Node has no fetch. No Firestore write.");
  }

  const original = Gaxios.prototype._defaultAdapter;
  if (typeof original !== "function") {
    console.warn(
      "gaxios has no _defaultAdapter function; leaving Storage auth on its default client.",
    );
    decided = true;
    return false;
  }

  savedPrototype = Gaxios.prototype;
  savedAdapter = original;
  decided = true;
  patched = true;
  Gaxios.prototype._defaultAdapter = function nativeTokenFetch(opts) {
    if (!opts?.fetchImplementation && isStorageTokenUrl(opts?.url)) {
      return original.call(this, {
        ...opts,
        redirect: "error",
        fetchImplementation: (input, init) =>
          globalThis.fetch(input, { ...init, redirect: "error" }),
      });
    }
    return original.call(this, opts);
  };
  return true;
}

/** Restores gaxios after a test installs or skips the patch. */
export function resetStorageAuthFetchForTests() {
  if (savedPrototype && typeof savedAdapter === "function") {
    savedPrototype._defaultAdapter = savedAdapter;
  }
  savedPrototype = null;
  savedAdapter = null;
  decided = false;
  patched = false;
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
