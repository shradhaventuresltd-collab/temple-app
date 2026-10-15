import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('image memory cache is capped at 200 images and 100 MiB', () {
    final cache = ImageCache();
    ClientCache.installImageMemoryLimits(cache);
    expect(cache.maximumSize, 200);
    expect(cache.maximumSizeBytes, 100 * 1024 * 1024);
  });

  test('Firestore persistence stays on except for web, at 100 MiB', () {
    expect(directoryFirestorePersistence(isWeb: false), isTrue);
    expect(directoryFirestorePersistence(isWeb: true), isFalse);

    final android = directoryFirestoreSettings(persistenceEnabled: true);
    expect(android.persistenceEnabled, isTrue);
    expect(android.cacheSizeBytes, 100 * 1024 * 1024);

    final web = directoryFirestoreSettings(
      persistenceEnabled: directoryFirestorePersistence(isWeb: true),
    );
    expect(web.persistenceEnabled, isFalse);
    expect(web.cacheSizeBytes, 100 * 1024 * 1024);
  });

  test('thumb cache keeps 2000 objects and detail keeps its own 150', () {
    expect(ClientCache.imageDiskObjects, 2000);
    expect(ClientCache.imageDiskStalePeriod, const Duration(days: 90));
    expect(ClientCache.imageDiskKey, 'templeImageCache');
    expect(ClientCache.detailDiskObjects, 150);
    expect(ClientCache.detailDiskStalePeriod, const Duration(days: 30));
    expect(ClientCache.detailDiskKey, 'templeDetailCache');
  });

  test('a phone list card decodes about five times smaller', () {
    // 360dp-wide card at 3.0 device pixels, cover height 168.
    // The previous cap decoded the layout box: min(1080, 1600) by min(504, 1200).
    const logicalWidth = 360.0;
    const logicalHeight = TempleBrowseCard.coverHeight;
    const dpr = 3.0;
    final beforeWidth = (logicalWidth * dpr).round().clamp(1, 1600);
    final beforeHeight = (logicalHeight * dpr).round().clamp(1, 1200);
    final after = listImageDecodeSize(
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
      devicePixelRatio: dpr,
    );

    expect(beforeWidth, 1080);
    expect(beforeHeight, 504);
    expect(decodedBitmapBytes(beforeWidth, beforeHeight), 2177280);

    expect(after.width, 480);
    expect(after.height, 224);
    expect(decodedBitmapBytes(after.width, after.height), 430080);
    expect(
      decodedBitmapBytes(beforeWidth, beforeHeight) /
          decodedBitmapBytes(after.width, after.height),
      closeTo(5.06, 0.01),
    );
  });

  test('startup installs the memory cap and watches connectivity', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('ClientCache.installImageMemoryLimits()'));
    expect(main, contains('DirectoryLink.listen(directoryConnectivity())'));
    final bootstrap = File(
      'lib/services/app_bootstrap.dart',
    ).readAsStringSync();
    expect(bootstrap, contains('configureDirectoryFirestore'));
  });

  testWidgets('detail keeps the full image in its own disk cache', (
    tester,
  ) async {
    const cover =
        'https://firebasestorage.googleapis.com/v0/b/app/o/shore.jpg?alt=media';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: Temple(
              name: 'Shore Temple',
              state: 'Tamil Nadu',
              city: 'Mahabalipuram',
              deity: 'Shiva',
              imageUrl: cover,
              description: 'A shore temple.',
              story: 'Notes.',
              location: 'Mahabalipuram',
              timings: '6am–8pm',
              specialities: [],
              latitude: 12.6,
              longitude: 80.2,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, cover);
    expect(image.memCacheWidth, isNull);
    expect(image.memCacheHeight, isNull);
    expect(image.cacheManager, same(ClientCache.detailImages));
  });
}
