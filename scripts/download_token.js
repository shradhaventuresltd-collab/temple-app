/**
 * Firebase download URLs for Storage objects. Uniform bucket-level access
 * has no object ACL, so a cover is served with metadata.firebaseStorageDownloadTokens.
 * An object that already has a token keeps the first one. A missing token
 * is a new UUID, stored when the object already exists.
 */
import { randomUUID } from "node:crypto";

import { firebaseDownloadUrl } from "./resize_cover_thumbs.js";

export function downloadTokenUrl(bucketName, objectPath, token) {
  return firebaseDownloadUrl(bucketName, objectPath, token);
}

export function firstDownloadToken(metadata) {
  const raw = metadata?.metadata?.firebaseStorageDownloadTokens ?? metadata?.firebaseStorageDownloadTokens;
  const token = String(raw ?? "").split(",")[0].trim();
  return token || null;
}

/** Object metadata for an upload. Custom metadata keeps the download token. */
export function withDownloadToken(metadata, token) {
  return {
    ...metadata,
    metadata: { ...(metadata?.metadata ?? {}), firebaseStorageDownloadTokens: token },
  };
}

function statusCode(error) {
  const code = error?.code ?? error?.status ?? error?.response?.statusCode ?? error?.response?.status;
  const numeric = Number(code);
  return Number.isInteger(numeric) ? numeric : null;
}

function isMissingObject(error) {
  if (statusCode(error) === 404) return true;
  const message = String(error?.message ?? "");
  return /\b404\b/.test(message) || /No such object/i.test(message);
}

/**
 * Reuse the object's first download token, or mint one. A missing object is
 * not created; the caller writes `token` with the upload. An existing object
 * with no token gets the new UUID via setMetadata.
 */
export async function ensureDownloadToken(file, bucketName, objectPath = file?.name, deps = {}) {
  let metadata = null;
  let exists = true;
  try {
    [metadata] = await file.getMetadata();
  } catch (error) {
    if (!isMissingObject(error)) throw error;
    exists = false;
  }
  let token = firstDownloadToken(metadata);
  if (!token) {
    token = deps.newToken ?? randomUUID();
    if (exists) {
      const custom = { ...(metadata?.metadata ?? {}), firebaseStorageDownloadTokens: token };
      await file.setMetadata({ metadata: custom });
    }
  }
  return {
    token,
    exists,
    url: downloadTokenUrl(bucketName, objectPath, token),
  };
}
