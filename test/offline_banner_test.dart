import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/offline_link.dart';
import 'package:temple_app/widgets/offline_banner.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(DirectoryLink.resetForTest);

  test('a lost connection shows the banner and a return clears it', () async {
    final events = StreamController<bool>();
    addTearDown(events.close);
    final before = DirectoryReconnect.tick.value;
    DirectoryLink.listen(events.stream);

    events.add(true);
    await _flush();
    expect(DirectoryLink.offline.value, isFalse);
    expect(DirectoryReconnect.tick.value, before);

    events.add(false);
    await _flush();
    expect(DirectoryLink.offline.value, isTrue);
    expect(DirectoryReconnect.tick.value, before);

    events.add(true);
    await _flush();
    expect(DirectoryLink.offline.value, isFalse);
    expect(DirectoryReconnect.tick.value, before + 1);
  });

  test('none is offline and any other transport is online', () {
    expect(connectivityIsOnline(const []), isFalse);
    expect(connectivityIsOnline(const [ConnectivityResult.none]), isFalse);
    expect(
      connectivityIsOnline(const [
        ConnectivityResult.none,
        ConnectivityResult.wifi,
      ]),
      isTrue,
    );
    expect(connectivityIsOnline(const [ConnectivityResult.mobile]), isTrue);
  });

  testWidgets('the banner appears offline and clears on reconnect', (
    tester,
  ) async {
    DirectoryLink.offline.value = false;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OfflineBanner())),
    );
    expect(find.byKey(const Key('offline-banner')), findsNothing);

    DirectoryLink.offline.value = true;
    await tester.pump();
    expect(find.text(OfflineBanner.message), findsOneWidget);

    DirectoryLink.offline.value = false;
    await tester.pump();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });

  testWidgets('reconnect keeps the home list and loads again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          adminAuth: FakeAdminAuth(),
          templesLoader: () async {
            calls += 1;
            return [_temple()];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('1 temples across India'), findsOneWidget);
    expect(find.byKey(const Key('offline-banner')), findsNothing);

    DirectoryLink.offline.value = true;
    await tester.pump();
    expect(find.text(OfflineBanner.message), findsOneWidget);
    expect(find.text('1 temples across India'), findsOneWidget);

    DirectoryReconnect.notify();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('1 temples across India'), findsOneWidget);
  });
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Temple _temple() {
  return const Temple(
    name: 'Meenakshi Amman Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: 'A historic temple.',
    story: 'Story',
    location: 'Madurai, Tamil Nadu',
    timings: '6am–9pm',
    specialities: [],
    latitude: 9.9,
    longitude: 78.1,
  );
}
