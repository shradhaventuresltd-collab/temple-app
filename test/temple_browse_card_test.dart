import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

  testWidgets('a real cover is requested and an empty deity hides the chip', (
    tester,
  ) async {
    await pumpCard(
      tester,
      temple(
        deity: '   ',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/app/o/temple.jpg?alt=media',
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
}
