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
}
