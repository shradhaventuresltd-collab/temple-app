import 'package:flutter/foundation.dart';

/// Debug count of Firestore document reads for one directory load.
///
/// Release builds keep the counters and do not print. A server `get` of one
/// document counts as one read. A cache `get` counts as a cache hit, not a
/// server read. Detail opens log their own line and are not part of the
/// launch total.
class FirestoreReadLog {
  FirestoreReadLog();

  static final FirestoreReadLog instance = FirestoreReadLog();

  int serverReads = 0;
  int cacheHits = 0;
  String source = '';

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

  void detailRead(String id) {
    if (!kDebugMode) return;
    debugPrint('Firestore detail read: temples/$id');
  }
}
