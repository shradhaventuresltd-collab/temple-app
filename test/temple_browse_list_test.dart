import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/temple_search.dart';
import 'package:temple_app/widgets/app_drawer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Temple temple({
    required String name,
    required String state,
    required String city,
    required String deity,
  }) {
    return Temple(
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: '',
      description: '',
      story: '',
      location: '$city, $state',
      timings: '',
      specialities: const [],
      latitude: 0,
      longitude: 0,
    );
  }

  final temples = [
    temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
    ),
    temple(
      name: 'Vaikom Mahadeva Temple',
      state: 'Kerala',
      city: 'Kottayam',
      deity: 'Shiva',
    ),
  ];

  Future<void> pumpList(WidgetTester tester, {String initialQuery = ''}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(temples: temples, initialQuery: initialQuery),
        ),
      ),
    );
  }

  testWidgets('debounced query filters the list and clear restores it', (
    tester,
  ) async {
    await pumpList(tester);

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('temple-list-search-field')),
      'vaikom',
    );
    await tester.pump();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);

    await tester.pump(templeSearchDebounce);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('1 temple'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
  });

  testWidgets('whitespace query restores the list without waiting', (
    tester,
  ) async {
    await pumpList(tester, initialQuery: 'vaikom');
    expect(find.text('Meenakshi Amman Temple'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('temple-list-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
  });

  testWidgets('empty results name the query and clear brings the list back', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.enterText(
      find.byKey(const Key('temple-list-search-field')),
      'zzzz-not-a-temple',
    );
    await tester.pump(templeSearchDebounce);

    expect(find.text('No temples match "zzzz-not-a-temple".'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    expect(find.text('No temples match "zzzz-not-a-temple".'), findsNothing);
  });

  testWidgets('initial query is applied before the first frame settles', (
    tester,
  ) async {
    await pumpList(tester, initialQuery: 'kottayam');
    expect(find.text('Vaikom Mahadeva Temple'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsNothing);
  });

  testWidgets('loading and empty directory states stay non-admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TempleBrowseList(temples: [], isLoading: true)),
      ),
    );

    expect(find.text('Loading temples'), findsOneWidget);
    expect(find.text('Fetching the directory.'), findsOneWidget);
    expect(find.textContaining('Seed'), findsNothing);
    expect(find.textContaining('Admin'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TempleBrowseList(temples: [])),
      ),
    );

    expect(find.text('No temples to browse'), findsOneWidget);
    expect(find.text('Nothing is listed in this view yet.'), findsOneWidget);
    expect(find.textContaining('Seed'), findsNothing);
  });

  testWidgets('banner slot stays below the card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleBrowseList(
            temples: temples,
            footer: const SizedBox(
              key: Key('browse-banner'),
              width: 320,
              height: 50,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
    final card = tester.getRect(find.text('Meenakshi Amman Temple'));
    final banner = tester.getRect(find.byKey(const Key('browse-banner')));
    expect(card.bottom, lessThanOrEqualTo(banner.top));
    expect(find.text('Devi'), findsOneWidget);
    expect(find.text('Madurai, Tamil Nadu'), findsOneWidget);
    expect(find.text('Photo pending'), findsWidgets);
  });
}
