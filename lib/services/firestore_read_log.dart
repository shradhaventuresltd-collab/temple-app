import 'package:flutter/foundation.dart';

/// Count of Firestore document reads for one directory load.
///
/// The launch summary prints in debug builds only. A server `get` of one
/// document counts as one read. A cache `get` counts as a cache hit, not a
/// server read. Detail opens log their own line and are not part of the
/// launch total.
///
/// Error fallbacks print `index_fallback:` plus a fixed marker in every
/// build, including release. The marker is `index-cache` or `sample`.
class FirestoreReadLog {
  FirestoreReadLog();

  static final FirestoreReadLog instance = FirestoreReadLog();

  int serverReads = 0;
  int cacheHits = 0;
  String source = '';

  /// Error fallbacks recorded for this process. Not cleared by [startLoad].
  int fallbackCount = 0;

  /// Markers passed to [recordFallback], in order. Not cleared by [startLoad].
  final List<String> fallbacks = [];

  void startLoad() {
    serverReads = 0;
    cacheHits = 0;
    source = '';
  }

  void serverRead([int count = 1]) {
    serverReads += count;
  }

  void cacheHit([int count = 1]) {
    cacheHits += count;
  }

  void finishLaunch(String loadedFrom) {
    source = loadedFrom;
    if (!kDebugMode) return;
    debugPrint(
      'Firestore reads this launch: $serverReads server, '
      '$cacheHits cache ($loadedFrom).',
    );
  }

  /// Release-visible marker for an error fallback. [marker] is not a temple
  /// id, a query, or any other visitor data.
  void recordFallback(String marker) {
    fallbackCount += 1;
    fallbacks.add(marker);
    // TODO(KAN-156): report this fallback as a Crashlytics non-fatal.
    debugPrint('index_fallback:$marker');
  }

  void detailRead(String id) {
    if (!kDebugMode) return;
    debugPrint('Firestore detail read: temples/$id');
  }
}
