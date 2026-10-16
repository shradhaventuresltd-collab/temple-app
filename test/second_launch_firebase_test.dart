import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/firebase_ready.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    debugFirebaseAccessProbe = null;
  });

  testWidgets(
    'terms already accepted does not touch Firebase before init finishes',
    (tester) async {
      final early = <String>[];
      var initFinished = false;
      debugFirebaseAccessProbe = (site) {
        if (!initFinished) early.add(site);
      };
      final release = Completer<void>();
      final store = _AcceptedStore();

      await tester.pumpWidget(
        TempleDirectoryApp(
          acceptanceStore: store,
          initializeFirebase: () async {
            await release.future;
            initFinished = true;
            return true;
          },
          initializeAds: () async {},
          templesLoader: () async => [_temple],
          adminToolsEnabled: false,
          onExitApp: () {},
          launchPolicyUrl: (_) async => true,
        ),
      );
      await tester.pump();

      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(PolicyAcceptanceGate), findsNothing);
      expect(
        early,
        isEmpty,
        reason: 'Firebase was used before initializeApp finished: $early',
      );

      release.complete();
      await tester.pumpAndSettle();

      expect(early, isEmpty);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PolicyAcceptanceGate), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _AcceptedStore implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async {
    return PolicyAcceptance(
      version: PolicyConfig.currentVersion,
      acceptedAt: DateTime.utc(2026, 10, 14),
    );
  }

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

final _temple = Temple(
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
  latitude: 9.9,
  longitude: 78.1,
);
