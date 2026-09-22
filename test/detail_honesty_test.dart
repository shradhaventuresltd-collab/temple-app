import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:flutter/material.dart';

Temple _named(String name) {
  return sampleTemples.firstWhere((temple) => temple.name == name);
}

Temple _draft({
  String name = 'Draft Temple',
  String deity = 'Shiva',
  String imageUrl = '',
  List<String> images = const [],
  String description = 'A place listed in the directory.',
  String story = 'Notes are still being checked.',
  String timings = '6:00 AM–8:00 PM daily.',
  List<String> specialities = const ['Stone gateway'],
}) {
  return Temple(
    name: name,
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: deity,
    imageUrl: imageUrl,
    description: description,
    story: story,
    location: 'Temple Street',
    timings: timings,
    specialities: specialities,
    images: images,
    latitude: 9.9,
    longitude: 78.1,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('placeholder and empty image URLs are not treated as photographs', () {
    expect(isPlaceholderImageUrl(''), isTrue);
    expect(isPlaceholderImageUrl('   '), isTrue);
    expect(
      isPlaceholderImageUrl('https://picsum.photos/seed/meenakshi/800/600'),
      isTrue,
    );
    expect(
      isPlaceholderImageUrl('https://fastly.picsum.photos/id/1/800/600'),
      isTrue,
    );
    expect(isPlaceholderImageUrl('https://placehold.co/800x600'), isTrue);
    expect(
      isPlaceholderImageUrl('https://via.placeholder.com/800x600'),
      isTrue,
    );
    expect(isPlaceholderImageUrl('not-a-url'), isTrue);
    expect(
      isPlaceholderImageUrl(
        'https://firebasestorage.googleapis.com/v0/b/app/o/temple.jpg?alt=media',
      ),
      isFalse,
    );
  });

  test('picsum covers and empty galleries are photo pending', () {
    // KAN-77: Mahabodhi carries verified Commons thumbs (not picsum).
    const verifiedPhotoNames = {'Mahabodhi Temple'};
    for (final temple in sampleTemples) {
      if (verifiedPhotoNames.contains(temple.name)) continue;
      expect(
        DetailHonesty.of(temple).photoPending,
        isTrue,
        reason: temple.name,
      );
      expect(verifiedCoverUrl(temple), isNull, reason: temple.name);
    }

    final mixed = _draft(
      imageUrl: 'https://picsum.photos/seed/cover/800/600',
      images: const [
        'https://picsum.photos/seed/other/800/600',
        'https://example.com/temple.jpg',
      ],
    );
    expect(verifiedGalleryUrls(mixed), ['https://example.com/temple.jpg']);
    expect(verifiedCoverUrl(mixed), 'https://example.com/temple.jpg');

    final realCover = _draft(imageUrl: 'https://example.com/cover.jpg');
    expect(DetailHonesty.of(realCover).photoPending, isFalse);
    expect(verifiedGalleryUrls(realCover), ['https://example.com/cover.jpg']);
    expect(verifiedCoverUrl(realCover), 'https://example.com/cover.jpg');
  });

  test('mosaic URLs drop placeholder hosts across temples', () {
    final temples = [
      _draft(imageUrl: 'https://picsum.photos/seed/a/800/600'),
      _draft(
        name: 'With real photo',
        imageUrl: 'https://picsum.photos/seed/b/800/600',
        images: const [
          'https://picsum.photos/seed/c/800/600',
          'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
        ],
      ),
      _draft(name: 'Empty', imageUrl: ''),
    ];

    expect(verifiedMosaicUrls(temples), [
      'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
    ]);
  });

  test('Mahabodhi sample has verified Commons gallery (KAN-77)', () {
    final mahabodhi = _named('Mahabodhi Temple');
    final honesty = DetailHonesty.of(mahabodhi);
    expect(mahabodhi.imageUrl.contains('picsum'), isFalse);
    expect(mahabodhi.imageUrl, contains('upload.wikimedia.org'));
    expect(mahabodhi.images, isNotEmpty);
    expect(honesty.photoPending, isFalse);
    expect(honesty.verifiedImages, isNotEmpty);
    expect(verifiedGalleryUrls(mahabodhi), mahabodhi.images);
    expect(honesty.tradition, SiteTradition.buddhist);
    expect(honesty.traditionLabel, 'Buddhist');
  });

  test(
    'timings stay free text and flag thin, seasonal, or multi-window notes',
    () {
      final amarnath = DetailHonesty.of(_named('Amarnath Cave Temple'));
      expect(amarnath.timingsCaveat, TimingsCaveatKind.seasonal);
      expect(amarnath.timingsCaveatText, contains('Provisional / seasonal'));
      expect(amarnath.timingsCaveatText, contains('always-open'));

      final meenakshi = DetailHonesty.of(_named('Meenakshi Amman Temple'));
      expect(meenakshi.timingsCaveat, TimingsCaveatKind.multiWindow);
      expect(meenakshi.timingsCaveatText, contains('always-open'));

      final sabarimala = DetailHonesty.of(_named('Sabarimala Ayyappan Temple'));
      expect(sabarimala.timingsCaveat, TimingsCaveatKind.seasonal);

      final shore = DetailHonesty.of(_named('Shore Temple'));
      expect(shore.timingsCaveat, TimingsCaveatKind.none);
      expect(shore.timingsCaveatText, isNull);

      final missing = DetailHonesty.of(_draft(timings: '   '));
      expect(missing.timingsCaveat, TimingsCaveatKind.missing);
      expect(missing.timingsCaveatText, contains('No visiting hours'));

      final thin = DetailHonesty.of(
        _draft(timings: 'Thin official clock. Confirm locally.'),
      );
      expect(thin.timingsCaveat, TimingsCaveatKind.provisional);

      final single = DetailHonesty.of(
        _draft(timings: 'Open daily 6:00 AM–9:00 PM.'),
      );
      expect(single.timingsCaveat, TimingsCaveatKind.none);
    },
  );

  test('site framing uses existing copy and stays neutral when unsure', () {
    final martand = DetailHonesty.of(_named('Martand Sun Temple'));
    expect(martand.framing, SiteFraming.monumentVisit);
    expect(martand.framingLabel, 'Heritage visit');
    expect(martand.timingsHeading, 'Visiting hours');
    expect(martand.storyHeading, 'Site history');

    final kandariya = DetailHonesty.of(_named('Kandariya Mahadeva Temple'));
    expect(kandariya.framing, SiteFraming.monumentVisit);

    final rajarani = DetailHonesty.of(_named('Rajarani Temple'));
    expect(rajarani.framing, SiteFraming.monumentVisit);

    final shore = DetailHonesty.of(_named('Shore Temple'));
    expect(shore.framing, SiteFraming.monumentVisit);

    final brihad = DetailHonesty.of(_named('Brihadeeswarar Temple'));
    expect(brihad.framing, SiteFraming.livingTemple);
    expect(brihad.framingLabel, 'Living temple');

    final virupaksha = DetailHonesty.of(_named('Virupaksha Temple'));
    expect(virupaksha.framing, SiteFraming.livingTemple);

    final meenakshi = DetailHonesty.of(_named('Meenakshi Amman Temple'));
    expect(meenakshi.framing, SiteFraming.livingTemple);

    final unsure = DetailHonesty.of(_draft());
    expect(unsure.framing, SiteFraming.neutral);
    expect(unsure.framingLabel, isNull);
    expect(unsure.tradition, SiteTradition.unspecified);
    expect(unsure.storyHeading, 'Background');
    expect(unsure.framingNote, contains('do not say clearly'));
  });

  test('Jain and Buddhist sites are labeled without a Hindu-only chip', () {
    final dilwara = DetailHonesty.of(_named('Dilwara Temples'));
    expect(dilwara.tradition, SiteTradition.jain);
    expect(dilwara.traditionLabel, 'Jain');
    expect(dilwara.framingLabel, isNull);
    expect(dilwara.framing, SiteFraming.livingTemple);
    expect(dilwara.storyHeading, 'About this place');
    expect(dilwara.framingNote, contains('Jain pilgrimage site'));

    final mahabodhi = DetailHonesty.of(_named('Mahabodhi Temple'));
    expect(mahabodhi.tradition, SiteTradition.buddhist);
    expect(mahabodhi.traditionLabel, 'Buddhist');
    expect(mahabodhi.framingLabel, isNull);
    expect(mahabodhi.framingNote, contains('Buddhist pilgrimage site'));
    expect(mahabodhi.storyHeading, 'About this place');

    expect(
      DetailHonesty.of(_named('Sri Manjunatha Temple, Dharmasthala')).tradition,
      SiteTradition.unspecified,
    );
    expect(
      DetailHonesty.of(_named('Keesaragutta Temple')).tradition,
      SiteTradition.unspecified,
    );
    expect(
      DetailHonesty.of(_named('Manikaran Shiva Temple')).tradition,
      SiteTradition.unspecified,
    );
  });

  testWidgets('detail honesty UI shows photo pending, caveat, and directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Dilwara Temples')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.text('No verified photograph is on file.'), findsOneWidget);
    expect(find.byKey(const Key('detail-tradition-chip')), findsOneWidget);
    expect(find.text('Jain'), findsWidgets);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.text('About this place'), findsOneWidget);
    expect(find.text('Temple story'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.byKey(const Key('detail-timings-body')), findsOneWidget);
    expect(find.textContaining('06:00 AM'), findsWidgets);
    expect(find.text('Admin Panel'), findsNothing);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('monument visit and missing hours stay honest', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Martand Sun Temple')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.text('Visiting hours'), findsOneWidget);
    expect(find.text('Site history'), findsOneWidget);
    expect(find.text('Temple story'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(find.textContaining('picsum.photos'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: _draft(
              timings: '',
              description: 'Listed place with no further classification.',
              story: 'Background notes only.',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.byKey(const Key('timings-caveat')), findsOneWidget);
    expect(find.textContaining('No visiting hours'), findsOneWidget);
    expect(find.text('Not listed in this entry.'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
  });

  testWidgets('phone width lays out photo pending and timings caveat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Meenakshi Amman Temple')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.text('Living temple'), findsOneWidget);
    expect(find.byKey(const Key('timings-caveat')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single stated window does not add a timings caveat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _named('Shore Temple'))),
      ),
    );
    await tester.pump();

    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.byKey(const Key('timings-caveat')), findsNothing);
    expect(find.textContaining('6:00 AM–6:00 PM'), findsOneWidget);
    expect(find.text('Get Directions'), findsOneWidget);
  });
}
