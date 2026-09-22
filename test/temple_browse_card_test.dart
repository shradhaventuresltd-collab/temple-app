import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Temple temple({
    String name = 'Meenakshi Amman Temple',
    String state = 'Tamil Nadu',
    String city = 'Madurai',
    String deity = 'Devi',
    String imageUrl = '',
    List<String> images = const [],
  }) {
    return Temple(
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: imageUrl,
      description: '',
      story: '',
      location: '$city, $state',
      timings: '',
      specialities: const [],
      images: images,
      latitude: 9.9,
      longitude: 78.1,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    Temple value, {
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseCard(temple: value, onTap: onTap),
        ),
      ),
    );
  }

  test('place label skips a missing city or state', () {
    expect(templeBrowsePlaceLabel(temple()), 'Madurai, Tamil Nadu');
    expect(
      templeBrowsePlaceLabel(temple(city: '  ', state: 'Kerala')),
      'Kerala',
    );
    expect(
      templeBrowsePlaceLabel(temple(city: 'Madurai', state: '')),
      'Madurai',
    );
  });

  testWidgets(
    'picsum and empty covers say photo pending and show a deity chip',
    (tester) async {
      await pumpCard(
        tester,
        temple(imageUrl: 'https://picsum.photos/seed/meenakshi/800/600'),
      );

      expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
      expect(find.text('Madurai, Tamil Nadu'), findsOneWidget);
      expect(find.text('Devi'), findsOneWidget);
      expect(find.text('Photo pending'), findsOneWidget);
      expect(find.byType(TempleImagePlaceholder), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);

      await pumpCard(tester, temple(imageUrl: 'https://placehold.co/800x600'));
      expect(find.text('Photo pending'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    },
  );

  testWidgets(
    'KAN-78: Tamil Nadu picsum sample temples never bind stock as cover',
    (tester) async {
      const names = [
        'Arunachaleswarar Temple',
        'Brihadeeswarar Temple',
        'Ekambaranathar Temple',
        'Kapaleeshwarar Temple',
      ];

      for (final name in names) {
        final sample = _named(name);
        expect(
          sample.imageUrl,
          contains('picsum.photos'),
          reason: '$name fixture still uses picsum in sample_data',
        );
        await pumpCard(tester, sample);
        expect(
          find.byType(TempleImagePlaceholder),
          findsOneWidget,
          reason: '$name must show Photo pending',
        );
        expect(
          find.text('Photo pending'),
          findsOneWidget,
          reason: '$name must show Photo pending',
        );
        expect(
          find.byType(CachedNetworkImage),
          findsNothing,
          reason: '$name must not load picsum/stock',
        );
      }
    },
  );

  testWidgets(
    'KAN-78: images[] picsum with empty cover still shows Photo pending',
    (tester) async {
      await pumpCard(
        tester,
        temple(
          imageUrl: '',
          images: const [
            'https://picsum.photos/seed/desk/800/600',
            'https://fastly.picsum.photos/id/1015/800/600',
          ],
        ),
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('Photo pending'), findsOneWidget);
    },
  );

  testWidgets('a real cover is requested and an empty deity hides the chip', (
    tester,
  ) async {
    await pumpCard(
      tester,
      temple(
        deity: '   ',
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/app/o/temple.jpg?alt=media',
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.text('Photo pending'), findsNothing);
    expect(find.text('Devi'), findsNothing);
  });

  testWidgets('a card is tappable and an injected handler wins', (
    tester,
  ) async {
    await pumpCard(tester, temple());
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.onTap, isNotNull);

    var taps = 0;
    await pumpCard(tester, temple(), onTap: () => taps++);
    await tester.tap(find.byType(TempleBrowseCard));
    expect(taps, 1);
    expect(find.byType(TempleBrowseCard), findsOneWidget);
  });

  test('honesty labels flag outliers and skip living-temple copy', () {
    expect(
      templeBrowseHonestyLabels(_named('Meenakshi Amman Temple')),
      isEmpty,
    );
    expect(templeBrowseHonestyLabels(_named('Dilwara Temples')), ['Jain']);
    expect(templeBrowseHonestyLabels(_named('Mahabodhi Temple')), ['Buddhist']);
    expect(templeBrowseHonestyLabels(_named('Shore Temple')), [
      'Heritage visit',
    ]);
    expect(templeBrowseHonestyLabels(_named('Konark Sun Temple')), [
      'Heritage visit',
    ]);
    expect(templeBrowseHonestyLabels(_named('Martand Sun Temple')), [
      'Heritage visit',
    ]);
  });

  testWidgets('outlier cards show honesty chips and not story or timings', (
    tester,
  ) async {
    final shore = _named('Shore Temple');
    await pumpCard(tester, shore);

    expect(find.text('Shiva'), findsOneWidget);
    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text(shore.story), findsNothing);
    expect(find.text(shore.timings), findsNothing);
    // KAN-77: Commons cover — no Photo pending on Shore.
    expect(find.text('Photo pending'), findsNothing);
    expect(find.byType(CachedNetworkImage), findsOneWidget);

    final dilwara = _named('Dilwara Temples');
    await pumpCard(tester, dilwara);
    expect(find.text('Jain Tirthankaras'), findsOneWidget);
    expect(find.text('Jain'), findsOneWidget);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.text(dilwara.story), findsNothing);
    expect(find.text('Photo pending'), findsNothing);

    final meenakshi = _named('Meenakshi Amman Temple');
    await pumpCard(tester, meenakshi);
    expect(find.text('Devi'), findsOneWidget);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.text(meenakshi.story), findsNothing);
    expect(find.text('Photo pending'), findsNothing);

    // Still-picsum heritage outlier keeps Photo pending.
    final konark = _named('Konark Sun Temple');
    await pumpCard(tester, konark);
    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.text('Photo pending'), findsOneWidget);
  });

  testWidgets('verified covers decode at the card size', (tester) async {
    await pumpCard(
      tester,
      temple(
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/app/o/temple.jpg?alt=media',
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final context = tester.element(find.byType(CachedNetworkImage));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = tester.getSize(find.byType(TempleBrowseCard)).width;

    expect(image.memCacheWidth, (width * dpr).round().clamp(1, 1600));
    expect(
      image.memCacheHeight,
      (TempleBrowseCard.coverHeight * dpr).round().clamp(1, 1200),
    );
  });
}

Temple _named(String name) {
  return sampleTemples.firstWhere((temple) => temple.name == name);
}
