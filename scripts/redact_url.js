/**
 * Hide Firebase download tokens before a URL is printed.
 * Firestore writes and an operator-requested URL file keep the real token.
 * The parameter name is matched without case sensitivity. A token written
 * as token=, an HTML-escaped `&amp;token=`, or percent-encoded inside a
 * nested URL (including a double-encoded `%2526token%253D`) is replaced.
 * Other parameters stay.
 */
const RAW_TOKEN = /([?&]token=)[^&#\s'"]*/gi;
const HTML_AMP_TOKEN = /(&amp;token=)[^&#\s'"]*/gi;
const ENCODED_AMPERSAND = /((?:%3f|%26)token%3d)(?:%(?!(?:26|23))[0-9a-f]{2}|[^%&#\s'"])*/gi;
const RAW_AMPERSAND_ENCODED_EQUALS = /([?&]token%3d)(?:%(?!(?:26|23))[0-9a-f]{2}|[^%&#\s'"])*/gi;
const ENCODED_AMPERSAND_RAW_EQUALS = /((?:%3f|%26)token=)[^%&#\s'"]*/gi;
const DOUBLE_ENCODED =
  /((?:%253f|%2526)token%253d)(?:%(?!(?:2526|2523|26|23))[0-9a-f]{2}|[^%&#\s'"])*/gi;

function applyTokenPatterns(text) {
  return text
    .replace(RAW_TOKEN, "$1<redacted>")
    .replace(HTML_AMP_TOKEN, "$1<redacted>")
    .replace(ENCODED_AMPERSAND, "$1<redacted>")
    .replace(RAW_AMPERSAND_ENCODED_EQUALS, "$1<redacted>")
    .replace(ENCODED_AMPERSAND_RAW_EQUALS, "$1<redacted>")
    .replace(DOUBLE_ENCODED, "$1<redacted>");
}

export function redactDownloadToken(value) {
  let text = String(value ?? "");
  let previous;
  do {
    previous = text;
    text = applyTokenPatterns(text);
  } while (text !== previous);
  return text;
}

/**
 * Text of a thrown value for a log line. A non-empty message wins. An empty
 * message, or a throw that is not an Error, uses `stack` when it has one
 * and otherwise `String(err)`.
 */
export function thrownText(err) {
  const message = err && typeof err === "object" && typeof err.message === "string" ? err.message : "";
  if (message.trim() !== "") return message;
  const stack = err && typeof err === "object" && typeof err.stack === "string" ? err.stack : "";
  if (stack.trim() !== "") return stack;
  return String(err);
}

/** [thrownText] with download tokens removed. */
export function redactThrown(err) {
  return redactDownloadToken(thrownText(err));
}
