// KAN-203 tradition icons: gurdwara / derasar / Buddhist / Hindu chrome.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/widgets/mosaic_tile_placeholder.dart';
import 'package:temple_app/widgets/place_type_icon.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

import 'filter_sheet_support.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mosaic placeholder swaps to gurdwara / derasar / Buddhist', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: MosaicTilePlaceholder(kind: PlaceTypeKind.hindu),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: MosaicTilePlaceholder(kind: PlaceTypeKind.sikhGurdwara),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: MosaicTilePlaceholder(kind: PlaceTypeKind.jainDerasar),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: MosaicTilePlaceholder(kind: PlaceTypeKind.buddhist),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.temple_hindu_outlined), findsOneWidget);
    expect(find.byIcon(Icons.temple_buddhist_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Gurdwara'), findsOneWidget);
    expect(find.bySemanticsLabel('Derasar'), findsOneWidget);
  });

  testWidgets('browse card shows the 24dp icon beside the tradition chip', (
    t,
  ) async {
    final sikh = filterTemple(
      name: 'Harmandir Sahib',
      state: 'Punjab',
      city: 'Amritsar',
      deity: 'Guru Granth Sahib',
      tradition: 'sikh',
    );
    final hindu = filterTemple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TempleBrowseCard(temple: sikh),
              TempleBrowseCard(temple: hindu),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.byKey(const Key('browse-place-type-icon')), findsOneWidget);
    expect(find.bySemanticsLabel('Gurdwara'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('browse-temple-name')),
        matching: find.byKey(const Key('browse-place-type-icon')),
      ),
      findsNothing,
    );
  });

  testWidgets('Hindu mosaic icon is unchanged; no Khanda label', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 80, height: 80, child: MosaicTilePlaceholder()),
        ),
      ),
    );
    expect(find.byIcon(Icons.temple_hindu_outlined), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Khanda|khanda')), findsNothing);
  });

  test('app chrome keeps temple_hindu; Browse CTA does not', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    expect(home.contains('Icons.account_balance_rounded'), isTrue);
    // The Browse N places CTA must not use a Hindu-only temple icon.
    expect(home.contains('home-browse-temples'), isTrue);
    final start = home.indexOf("key: const Key('home-browse-temples')");
    final end = home.indexOf("key: const Key('home-near-me')");
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final cta = home.substring(start, end);
    expect(cta.contains('account_balance_rounded'), isTrue);
    expect(cta.contains('temple_hindu'), isFalse);
    final drawer = File('lib/widgets/app_drawer.dart').readAsStringSync();
    expect(drawer.contains('Icons.temple_hindu_rounded'), isTrue);
  });
}
