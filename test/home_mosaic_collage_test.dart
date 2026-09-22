import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/widgets/home_mosaic_collage.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

Temple _temple({
  String name = 'Test Temple',
  String imageUrl = '',
  List<String> images = const [],
}) {
  return Temple(
    name: name,
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Shiva',
    imageUrl: imageUrl,
    description: '',
    story: '',
    location: 'Madurai, Tamil Nadu',
    timings: '',
    specialities: const [],
    images: images,
    latitude: 9.9,
    longitude: 78.1,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('homeDirectoryCountLabel stays dynamic and honest when empty', () {
    expect(homeDirectoryCountLabel(0), 'No temples loaded yet');
    expect(homeDirectoryCountLabel(150), '150 temples across India');
    expect(homeDirectoryCountLabel(180), '180 temples across India');
    expect(homeDirectoryCountLabel(181), '181 temples across India');
  });

  test('drawerAboutDirectoryBlurb never hardcodes 150 or 180', () {
    final for180 = drawerAboutDirectoryBlurb(180);
    expect(for180, startsWith('Explore 180 famous temples across '));
    expect(for180, isNot(contains('Explore 150 ')));

    final for200 = drawerAboutDirectoryBlurb(200);
    expect(for200, startsWith('Explore 200 famous temples across '));
    expect(for200, isNot(contains('Explore 180 ')));
    expect(for200, isNot(contains('Explore 150 ')));

    final empty = drawerAboutDirectoryBlurb(0);
    expect(empty, startsWith('Explore famous temples across '));
    expect(empty, isNot(contains(RegExp(r'Explore \d+ famous'))));
  });

  testWidgets(
    'KAN-73: sample mosaic uses verified photos and drops picsum',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeMosaicCollage(temples: sampleTemples),
          ),
        ),
      );

      // KAN-77 packs supply verified Commons covers, so the hero is a mosaic
      // rather than a single Photo pending tile.
      expect(find.byType(TempleImagePlaceholder), findsNothing);
      expect(find.text('Photo pending'), findsNothing);
      expect(find.byType(CachedNetworkImage), findsWidgets);
      expect(
        find.text('${sampleTemples.length} temples across India'),
        findsOneWidget,
      );
      expect(find.textContaining('150 temples'), findsNothing);

      final urls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((image) => image.imageUrl)
          .toList();
      expect(urls, isNotEmpty);
      expect(urls.any((url) => url.contains('picsum')), isFalse);
      expect(urls.any((url) => url.contains('upload.wikimedia.org')), isTrue);
    },
  );

  testWidgets('KAN-73: a picsum-only list still shows Photo pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeMosaicCollage(
            temples: [
              _temple(
                imageUrl: 'https://picsum.photos/seed/only/800/600',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TempleImagePlaceholder), findsOneWidget);
    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('KAN-73: verified URLs still tile the mosaic', (tester) async {
    final temples = [
      _temple(
        name: 'One',
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
      ),
      _temple(
        name: 'Two',
        images: const [
          'https://picsum.photos/seed/skip/800/600',
          'https://firebasestorage.googleapis.com/v0/b/app/o/b.jpg?alt=media',
        ],
      ),
      _temple(name: 'Picsum only', imageUrl: 'https://picsum.photos/seed/x/1'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeMosaicCollage(temples: temples)),
      ),
    );

    expect(find.byType(TempleImagePlaceholder), findsNothing);
    expect(find.byType(CachedNetworkImage), findsWidgets);
    expect(find.text('3 temples across India'), findsOneWidget);

    final urls = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl)
        .toSet();
    expect(urls.any((u) => u.contains('picsum')), isFalse);
    expect(
      urls,
      containsAll([
        'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
        'https://firebasestorage.googleapis.com/v0/b/app/o/b.jpg?alt=media',
      ]),
    );
  });

  testWidgets('KAN-79: empty directory does not invent a temple count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeMosaicCollage(temples: [])),
      ),
    );

    expect(find.text('No temples loaded yet'), findsOneWidget);
    expect(find.textContaining('temples across India'), findsNothing);
    expect(find.byType(TempleImagePlaceholder), findsOneWidget);
  });
}
