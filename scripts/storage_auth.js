/**
 * @google-cloud/storage asks google-auth-library for a token through gaxios,
 * and gaxios 6 uses node-fetch. node-fetch cannot read the gzip body Google
 * returns from the token endpoint ("Premature close"). Native fetch can.
 * The patch applies only to the two OAuth token URLs. Every other request,
 * including Storage downloads and userinfo, keeps the default adapter.
 *
 * The patch installs on the first call to `useNativeFetchForStorageAuth`.
 * Call `assertStorageAuth` once in --apply, before any Firestore write.
 * That check lists `temples/` so it does not depend on one object existing.
 */
import { createRequire } from "node:module";

import { redactThrown } from "./redact_url.js";

const require = createRequire(import.meta.url);

/** Bucket these scripts upload into. */
export const STORAGE_AUTH_BUCKET = "temple-directory-india.firebasestorage.app";

/** True only for the production bucket these resize scripts may touch. */
export function isLockedStorageBucket(bucket) {
  return String(bucket ?? "").trim() === STORAGE_AUTH_BUCKET;
}

/**
 * --apply may name only [STORAGE_AUTH_BUCKET]. An omitted --bucket is that
 * bucket. Any other name is refused before a read or a write.
 */
export function assertApplyBucket(bucket) {
  const name =
    typeof bucket === "string" && bucket.trim() !== "" ? bucket.trim() : STORAGE_AUTH_BUCKET;
  if (name !== STORAGE_AUTH_BUCKET) {
    throw new Error(
      `Refusing --bucket ${name}. --apply writes only ${STORAGE_AUTH_BUCKET}. No write.`,
    );
  }
  return name;
}

/** One-object list. An empty prefix is still a successful read. */
export const STORAGE_AUTH_LIST = { prefix: "temples/", maxResults: 1, autoPaginate: false };

export const STORAGE_AUTH_PREFLIGHT_ERROR = "Storage auth preflight failed. No Firestore write.";

/** gaxios uses these, in this order, to install its proxy agent. */
const PROXY_ENV_NAMES = ["HTTPS_PROXY", "https_proxy", "HTTP_PROXY", "http_proxy"];

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

function activeProxyEnv() {
  for (const name of PROXY_ENV_NAMES) {
    const value = process.env[name];
    if (typeof value === "string" && value.trim() !== "") return name;
  }
  return null;
}

/**
 * Installs the native-fetch patch on the first call when gaxios is present,
 * its adapter is still the one this patch knows, and no HTTP(S) proxy is set.
 * Returns false when gaxios is missing or the patch is intentionally skipped.
 */
export function useNativeFetchForStorageAuth() {
  if (decided) return patched;
  const Gaxios = loadGaxios();
  if (!Gaxios) return false;

  const proxyEnv = activeProxyEnv();
  if (proxyEnv) {
    console.log(
      `${proxyEnv} is set; skipping the native fetch override so the proxy agent is used.`,
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

function statusCode(error) {
  const code = error?.code ?? error?.status ?? error?.response?.statusCode ?? error?.response?.status;
  const numeric = Number(code);
  return Number.isInteger(numeric) ? numeric : null;
}

/**
 * Read-only. Lists `temples/` once. Any failure stops Apply before a
 * Firestore or Storage write. A 403 names storage.objects.list.
 */
export async function assertStorageAuth(bucket) {
  useNativeFetchForStorageAuth();
  try {
    await bucket.getFiles(STORAGE_AUTH_LIST);
  } catch (error) {
    const detail = redactThrown(error);
    console.error(detail);
    if (statusCode(error) === 403 || /\b403\b/.test(String(error?.message ?? ""))) {
      throw new Error(
        "Storage auth preflight failed: missing storage.objects.list (403). No Firestore write.",
      );
    }
    throw new Error(`Storage auth preflight failed: ${detail}. No Firestore write.`);
  }
}
