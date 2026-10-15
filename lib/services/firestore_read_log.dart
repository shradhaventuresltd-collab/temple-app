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

  /// State names whose shard could not be read and has no bundled sample.
  final List<String> unavailableShards = [];

  /// State names filled from the bundled sample after the state query failed.
  final List<String> sampleStates = [];

  /// True when this load is showing any bundled sample, including the
  /// whole directory after a meta timeout.
  bool offlineSample = false;

  /// Banner text when a state is missing or a sample is on screen.
  String? get unavailableShardsMessage {
    final parts = <String>[];
    if (offlineSample) {
      final where = sampleStates.isEmpty
          ? 'temples'
          : 'temples in ${sampleStates.join(', ')}';
      parts.add('Could not load $where. Showing the offline sample.');
    }
    if (unavailableShards.isNotEmpty) {
      parts.add('Could not load temples in ${unavailableShards.join(', ')}.');
    }
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  void startLoad() {
    serverReads = 0;
    cacheHits = 0;
    source = '';
    unavailableShards.clear();
    sampleStates.clear();
    offlineSample = false;
  }

  void noteUnavailableShard(String label) {
    if (label.isEmpty || unavailableShards.contains(label)) return;
    unavailableShards.add(label);
  }

  /// [state] is omitted when the whole bundled directory is on screen.
  void noteOfflineSample([String? state]) {
    offlineSample = true;
    if (state == null || state.isEmpty || sampleStates.contains(state)) return;
    sampleStates.add(state);
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
