import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Client cache bounds for the directory (KAN-147).
///
/// List and mosaic covers decode at about 480px, the same edge as `_480`
/// thumbs. Detail does not set a decode size, so the full image stays sharp.
///
/// Firestore persistence stays on for Android and iOS and off for web. Web
/// launches stay cold: the web cache is memory-only, which the directory
/// reader already assumes. 100 MiB is the disk budget for the sharded index
/// plus temples opened on detail. The SDK default is also 100 MiB today;
/// setting it here keeps a later default from shrinking the cache under the
/// index, or from growing it without a decision.
///
/// [configureDirectoryFirestore] runs after `Firebase.initializeApp` and
/// before the first directory read.
class ClientCache {
  ClientCache._();

  /// Decoded list and mosaic bitmaps. Flutter's default count is 1000.
  static const int imageMemoryCount = 200;

  /// Decoded bitmap bytes. Flutter's default is 100 MiB; this pins it.
  static const int imageMemoryBytes = 100 * 1024 * 1024;

  /// Disk objects for network images. The default cache keeps 200 objects
  /// for 30 days, which churns once covers pass a few hundred temples.
  /// 1,000 objects of a 480px thumb (about 50–150 KB) stay near 150 MB.
  /// flutter_cache_manager caps by object count, not by bytes.
  static const int imageDiskObjects = 1000;

  static const Duration imageDiskStalePeriod = Duration(days: 90);

  /// Longest side of a list or mosaic decode, in pixels.
  static const int listDecodePx = 480;

  /// Firestore on-disk cache. The SDK requires at least 1 MiB.
  static const int firestoreCacheBytes = 100 * 1024 * 1024;

  static const String imageDiskKey = 'templeImageCache';

  static final CacheManager images = CacheManager(
    Config(
      imageDiskKey,
      stalePeriod: imageDiskStalePeriod,
      maxNrOfCacheObjects: imageDiskObjects,
    ),
  );

  /// Bounds the decoded-bitmap cache. Call after
  /// [WidgetsFlutterBinding.ensureInitialized] and before the first frame.
  static void installImageMemoryLimits([ImageCache? cache]) {
    final imageCache = cache ?? PaintingBinding.instance.imageCache;
    imageCache.maximumSize = imageMemoryCount;
    imageCache.maximumSizeBytes = imageMemoryBytes;
  }
}

/// Persistence for the cache-first index. Web stays memory-only.
bool directoryFirestorePersistence({required bool isWeb}) => !isWeb;

/// Explicit settings so an SDK default change cannot drop the index cache.
Settings directoryFirestoreSettings({required bool persistenceEnabled}) {
  return Settings(
    persistenceEnabled: persistenceEnabled,
    cacheSizeBytes: ClientCache.firestoreCacheBytes,
  );
}

/// Applies [directoryFirestoreSettings] on [firestore]. Web keeps
/// persistence off. Call once, after `Firebase.initializeApp`, before any
/// read or write.
void configureDirectoryFirestore(FirebaseFirestore firestore, {bool? isWeb}) {
  final web = isWeb ?? kIsWeb;
  firestore.settings = directoryFirestoreSettings(
    persistenceEnabled: directoryFirestorePersistence(isWeb: web),
  );
}

/// Pixel size for a list or mosaic image.
///
/// Scales the layout box so the longer side is at most
/// [ClientCache.listDecodePx], keeping the widget's aspect. A wide phone
/// card (360dp at 3x, 168dp tall) decodes at 480×224 instead of 1080×504.
({int width, int height}) listImageDecodeSize({
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
}) {
  final displayW = _displayPx(logicalWidth, devicePixelRatio);
  final displayH = _displayPx(logicalHeight, devicePixelRatio);
  final longer = displayW > displayH ? displayW : displayH;
  if (longer <= ClientCache.listDecodePx) {
    return (width: displayW, height: displayH);
  }
  final scale = ClientCache.listDecodePx / longer;
  return (
    width: (displayW * scale).round().clamp(1, ClientCache.listDecodePx),
    height: (displayH * scale).round().clamp(1, ClientCache.listDecodePx),
  );
}

int _displayPx(double logical, double devicePixelRatio) {
  final px = (logical * devicePixelRatio).round();
  return px < 1 ? 1 : px;
}

/// RGBA8 bytes of a decoded bitmap.
int decodedBitmapBytes(int width, int height) => width * height * 4;
