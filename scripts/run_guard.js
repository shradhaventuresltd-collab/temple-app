/**
 * Timeouts, retries, and the apply summary shared by the resize scripts.
 * A hung fetch or Storage call must reject. A late rejection after that
 * timeout is caught here so it cannot become an unhandledRejection.
 */
import { redactThrown } from "./redact_url.js";

export const DEFAULT_TIMEOUT_MS = 60_000;
export const DEFAULT_ATTEMPTS = 3;
export const DEFAULT_BACKOFF_MS = 250;
export const DEFAULT_BATCH_SIZE = 10;

const REASON_LABELS = {
  "has-gallery": "already-has-galleryUrl",
  "not-smaller": "too-small",
  "no-generation": "no-source-generation",
};

export function parseTimeoutMs(raw) {
  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error("--timeout-ms needs a positive integer.");
  }
  return parsed;
}

function delay(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

/**
 * One attempt. [fn] receives the AbortSignal for this attempt. The timer
 * aborts that signal and rejects. [fn]'s promise is caught up front so a
 * rejection that arrives after the timeout is not unhandled.
 */
export function attemptWithTimeout(fn, timeoutMs, label) {
  const controller = new AbortController();
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      const error = new Error(`${label} timed out after ${timeoutMs}ms`);
      error.code = "TIMEOUT";
      error.name = "TimeoutError";
      controller.abort(error);
      reject(error);
    }, timeoutMs);
  });
  const task = Promise.resolve().then(() => fn(controller.signal));
  task.catch(() => {});
  return Promise.race([task, timeout]).finally(() => {
    clearTimeout(timer);
  });
}

/**
 * [fn] is tried up to [attempts] times. Each try has its own AbortController
 * and lasts at most [timeoutMs]. Backoff doubles each time and stops at 2s.
 */
export async function callBounded(
  fn,
  {
    timeoutMs = DEFAULT_TIMEOUT_MS,
    attempts = DEFAULT_ATTEMPTS,
    backoffMs = DEFAULT_BACKOFF_MS,
    label = "network",
    sleep = delay,
  } = {},
) {
  const tries = Math.max(1, Number(attempts) || 1);
  let last;
  for (let attempt = 1; attempt <= tries; attempt += 1) {
    try {
      return await attemptWithTimeout(fn, timeoutMs, label);
    } catch (error) {
      last = error;
      if (attempt >= tries) break;
      const wait = Math.min(backoffMs * 2 ** (attempt - 1), 2_000);
      if (wait > 0) await sleep(wait);
    }
  }
  throw last;
}

export function networkLimits(deps = {}) {
  return {
    timeoutMs: deps.timeoutMs ?? DEFAULT_TIMEOUT_MS,
    attempts: deps.attempts ?? DEFAULT_ATTEMPTS,
    backoffMs: deps.backoffMs ?? DEFAULT_BACKOFF_MS,
    sleep: deps.sleep,
  };
}

/**
 * Wrap the network methods on [deps]. Path calls keep (path, opts). The
 * AbortSignal and timeout are added to opts. URL checks are called as
 * (url, { signal }). Document writes keep their first argument.
 */
export function boundIo(deps, keys) {
  const limits = networkLimits(deps);
  const next = { ...deps };
  for (const [key, label, kind] of keys) {
    const fn = deps[key];
    if (typeof fn !== "function") continue;
    if (kind === "path") {
      next[key] = (path, opts = {}) =>
        callBounded((signal) => fn(path, { ...opts, signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "file") {
      next[key] = (file) =>
        callBounded((signal) => fn({ ...file, signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "url") {
      next[key] = (url) =>
        callBounded((signal) => fn(url, { signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "doc") {
      next[key] = (doc) =>
        callBounded((signal) => fn(doc, { signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "id") {
      next[key] = (id) =>
        callBounded((signal) => fn(id, { signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "bytes") {
      next[key] = (bytes, ext) =>
        callBounded((signal) => fn(bytes, ext, { signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    } else if (kind === "pair") {
      next[key] = (left, right) =>
        callBounded((signal) => fn(left, right, { signal, timeoutMs: limits.timeoutMs }), {
          ...limits,
          label,
        });
    }
  }
  return next;
}

export function isTimeoutError(error) {
  if (!error || typeof error !== "object") return false;
  if (error.code === "TIMEOUT" || error.name === "TimeoutError") return true;
  const message = typeof error.message === "string" ? error.message : "";
  return /timed out/i.test(message);
}

/**
 * After an upload times out, the create-only object may already be in
 * Storage. A stat of that same path links it. Any other error, or a miss,
 * leaves the timeout to be counted as failed.
 */
export async function objectAfterUploadTimeout(error, stat, path, bucket) {
  if (!isTimeoutError(error) || typeof stat !== "function" || !path) return null;
  try {
    return await stat(path, { bucket });
  } catch {
    return null;
  }
}

export function beginRun(tracker) {
  if (!tracker) return;
  tracker.active = true;
  tracker.summarized = false;
  tracker.rows = [];
  tracker.started = Date.now();
}

/**
 * beforeExit fires when a hung promise left no handles and the loop is
 * empty. If the summary was not printed, say so and exit 1. Returns false
 * when the run already finished, so a normal exit stays quiet.
 */
export function incompleteOnBeforeExit(tracker, log) {
  if (!tracker?.active || tracker.summarized) return false;
  const elapsedMs = Date.now() - (tracker.started || Date.now());
  const summary = formatSummary({ ...tallyRows(tracker.rows), elapsedMs });
  log(summary);
  log("APPLY-INCOMPLETE");
  tracker.summarized = true;
  return summary;
}

export function chunk(items, size) {
  const list = Array.isArray(items) ? items : [];
  if (list.length === 0) return [];
  const n = Math.max(1, size || DEFAULT_BATCH_SIZE);
  const out = [];
  for (let i = 0; i < list.length; i += n) out.push(list.slice(i, i + n));
  return out;
}

export function skipReasonLabel(reason) {
  const key = typeof reason === "string" && reason !== "" ? reason : "unspecified";
  return REASON_LABELS[key] ?? key;
}

export function tallyRows(rows) {
  let written = 0;
  let failed = 0;
  let skipped = 0;
  let pending = 0;
  const reasons = new Map();
  for (const row of rows ?? []) {
    if (row?.result === "uploaded" || (row?.result === "exists" && row.stored === true)) {
      written += 1;
    } else if (row?.result === "failed" || row?.result === "not-public") {
      failed += 1;
    } else if (row?.result === "skipped") {
      skipped += 1;
      const label = skipReasonLabel(row.reason);
      reasons.set(label, (reasons.get(label) ?? 0) + 1);
    } else if (row?.result === "would-upload" || row?.result === "exists") {
      pending += 1;
    }
  }
  return { written, failed, skipped, pending, reasons };
}

export function formatElapsed(ms) {
  const seconds = Math.max(0, Number(ms) || 0) / 1000;
  return `${seconds.toFixed(1)}s`;
}

export function formatProgress({
  batch,
  batches,
  temples,
  written,
  failed,
  skipped,
  noun = "photos",
}) {
  return `batch ${batch}/${batches} temples ${temples} ${noun} written ${written} failed ${failed} skipped ${skipped} so far`;
}

export function formatSummary({ written, failed, skipped, pending = 0, reasons, elapsedMs }) {
  const parts = [...(reasons ?? [])].sort((a, b) => String(a[0]).localeCompare(String(b[0])));
  const reasonText = parts.map(([key, count]) => `${key}=${count}`).join(" ");
  const skippedText = reasonText ? `skipped=${skipped} (${reasonText})` : `skipped=${skipped}`;
  const pendingText = pending > 0 ? ` pending=${pending}` : "";
  return `summary written=${written} failed=${failed} ${skippedText}${pendingText} elapsed=${formatElapsed(elapsedMs)}`;
}

/**
 * Read a Storage object until it ends. Aborting [signal] destroys the
 * stream so a hung download does not keep the process alive.
 */
export function readWithSignal(file, signal) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const stream = file.createReadStream();
    let settled = false;
    const finish = (settle, value) => {
      if (settled) return;
      settled = true;
      if (signal) signal.removeEventListener("abort", onAbort);
      settle(value);
    };
    const onAbort = () => {
      if (typeof stream.destroy === "function") stream.destroy();
      const reason = signal.reason instanceof Error ? signal.reason : new Error("storage download aborted");
      finish(reject, reason);
    };
    if (signal?.aborted) {
      onAbort();
      return;
    }
    if (signal) signal.addEventListener("abort", onAbort);
    stream.on("data", (chunk) => {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    });
    stream.on("error", (error) => finish(reject, error));
    stream.on("end", () => finish(resolve, Buffer.concat(chunks)));
  });
}

/**
 * Write [bytes] with the Storage save options. Aborting [signal] destroys
 * the upload stream. [options.timeout] is the SDK request timeout.
 */
export function writeWithSignal(file, bytes, options, signal) {
  return new Promise((resolve, reject) => {
    const stream = file.createWriteStream(options);
    let settled = false;
    const finish = (settle, value) => {
      if (settled) return;
      settled = true;
      if (signal) signal.removeEventListener("abort", onAbort);
      settle(value);
    };
    const onAbort = () => {
      if (typeof stream.destroy === "function") stream.destroy();
      const reason = signal.reason instanceof Error ? signal.reason : new Error("storage upload aborted");
      finish(reject, reason);
    };
    if (signal?.aborted) {
      onAbort();
      return;
    }
    if (signal) signal.addEventListener("abort", onAbort);
    stream.on("error", (error) => finish(reject, error));
    stream.on("finish", () => finish(resolve, undefined));
    stream.end(bytes);
  });
}

/** Log [kind] and exit 1. Used by the direct-run process guards. */
export function reportProcessFault(kind, error, proc = process, write = console.error) {
  write(`${kind} ${redactThrown(error)}`);
  proc.exit(1);
}

export function failureText(error) {
  return redactThrown(error).split("\n")[0].slice(0, 300);
}

export class IncompleteRun extends Error {
  constructor(summary) {
    super(`APPLY-INCOMPLETE ${summary}`);
    this.name = "IncompleteRun";
    this.exitCode = 1;
    this.alreadyReported = true;
  }
}

/**
 * Log the summary and APPLY-FINISHED, or APPLY-INCOMPLETE when a photo
 * failed. [exit] is invoked with 0 or 1 when the caller supplied one.
 * Incomplete runs throw so a direct invocation exits non-zero.
 */
export function finishRun({ log, rows, elapsedMs, exit, tracker }) {
  if (tracker) {
    tracker.rows = rows ?? [];
    tracker.summarized = true;
  }
  const tally = tallyRows(rows);
  const summary = formatSummary({ ...tally, elapsedMs });
  log(summary);
  const ok = tally.failed === 0;
  log(ok ? "APPLY-FINISHED" : "APPLY-INCOMPLETE");
  if (typeof exit === "function") exit(ok ? 0 : 1);
  if (!ok) throw new IncompleteRun(summary);
  return rows;
}

export function logBatch(log, { batch, batches, temples, rows, noun }) {
  if (typeof log !== "function") return;
  const tally = tallyRows(rows);
  log(
    formatProgress({
      batch,
      batches,
      temples,
      written: tally.written,
      failed: tally.failed,
      skipped: tally.skipped,
      noun,
    }),
  );
}
