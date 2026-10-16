/**
 * Hide Firebase download tokens before a URL is printed.
 * Firestore writes and an operator-requested URL file keep the real token.
 * Only the `token` query parameter is replaced. Other parameters stay.
 */
const TOKEN_QUERY = /([?&]token=)[^&#\s'"]*/g;

export function redactDownloadToken(value) {
  return String(value ?? "").replace(TOKEN_QUERY, "$1<redacted>");
}
