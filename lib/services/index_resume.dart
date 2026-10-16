/// How long a foreground return waits before reading `meta/temple_index` again.
const Duration kIndexResumeCheckInterval = Duration(minutes: 15);

/// True when a resume may issue another meta read.
///
/// The window starts when the previous check was issued, including a check
/// that timed out, so a flapping resume cannot read more than once per
/// [interval]. A null [lastIndexCheck] has never checked and is due.
bool indexResumeCheckDue({
  required DateTime? lastIndexCheck,
  required DateTime now,
  Duration interval = kIndexResumeCheckInterval,
}) {
  final last = lastIndexCheck;
  if (last == null) return true;
  return !now.isBefore(last.add(interval));
}

/// True when Remote Config `content_version` is unchanged since it was applied.
///
/// Null on either side does not skip. The resume check then uses the
/// 15-minute window. This does not add a Firestore field.
bool indexResumeReadSkipped({
  required int? appliedContentVersion,
  required int? remoteContentVersion,
}) {
  if (appliedContentVersion == null || remoteContentVersion == null) {
    return false;
  }
  return appliedContentVersion == remoteContentVersion;
}
