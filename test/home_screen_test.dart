import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/widgets/app_drawer.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Temple sampleTemple() {
    return Temple(
      name: 'Meenakshi Amman Temple',
      state: 'Tamil Nadu',
      city: 'Madurai',
      deity: 'Devi',
      imageUrl: '',
      description: 'A historic temple.',
      story: 'Story',
      location: 'Madurai, Tamil Nadu',
      timings: '6am–9pm',
      specialities: const [],
      latitude: 0,
      longitude: 0,
    );
  }

  testWidgets('Home shows browse CTA and opens temple list without Firebase', (
    tester,
  ) async {
    final temples = [sampleTemple()];
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: auth,
          templesLoader: () async => temples,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Temple Directory'), findsOneWidget);
    expect(find.text('Temple Collage'), findsOneWidget);
    expect(find.byKey(const Key('home-browse-temples')), findsOneWidget);
    expect(find.text('Browse 1 Temple'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('home-browse-temples')));
    await tester.tap(find.byKey(const Key('home-browse-temples')));
    await tester.pumpAndSettle();

    expect(find.byType(TempleListScreen), findsOneWidget);
    expect(find.text('All Temples'), findsOneWidget);
    expect(find.text('Meenakshi Amman Temple'), findsOneWidget);
  });

  testWidgets('Home still renders honest empty state when load is empty', (
    tester,
  ) async {
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: auth,
          templesLoader: () async => const <Temple>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Temple Directory'), findsOneWidget);
    expect(find.text('No temples available yet.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Home shows cream loading shell while temples load', (
    tester,
  ) async {
    final auth = FakeAdminAuth();
    final completer = Completer<List<Temple>>();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: auth,
          templesLoader: () => completer.future,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Temple Directory'), findsOneWidget);
    expect(find.text('Loading temples…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([sampleTemple()]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-browse-temples')), findsOneWidget);
  });

  testWidgets('Home shows error UI with Retry when load fails', (tester) async {
    final auth = FakeAdminAuth();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: auth,
          templesLoader: () async => throw Exception('network'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load temples.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
