/**
 * Hide Firebase download tokens before a URL is printed.
 * Firestore writes and an operator-requested URL file keep the real token.
 * The parameter name is matched without case sensitivity. A token written
 * as token=, or percent-encoded inside a nested URL, is replaced. Other
 * parameters stay.
 */
const RAW_TOKEN = /([?&]token=)[^&#\s'"]*/gi;
const ENCODED_AMPERSAND = /((?:%3f|%26)token%3d)(?:%(?!(?:26|23))[0-9a-f]{2}|[^%&#\s'"])*/gi;
const RAW_AMPERSAND_ENCODED_EQUALS = /([?&]token%3d)(?:%(?!(?:26|23))[0-9a-f]{2}|[^%&#\s'"])*/gi;
const ENCODED_AMPERSAND_RAW_EQUALS = /((?:%3f|%26)token=)[^%&#\s'"]*/gi;

function applyTokenPatterns(text) {
  return text
    .replace(RAW_TOKEN, "$1<redacted>")
    .replace(ENCODED_AMPERSAND, "$1<redacted>")
    .replace(RAW_AMPERSAND_ENCODED_EQUALS, "$1<redacted>")
    .replace(ENCODED_AMPERSAND_RAW_EQUALS, "$1<redacted>");
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
