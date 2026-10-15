import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/release_error_widget.dart';
import 'package:temple_app/screens/admin_screen.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(AdminAuth.resetInstance);
  tearDown(AdminAuth.resetInstance);

  testWidgets('cold launch to Home does not throw or construct AdminAuth', (
    tester,
  ) async {
    expect(AdminAuth.isInitialized, isFalse);

    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _AcceptedStore(),
        initializeFirebase: () async => false,
        initializeAds: () async {},
        templesLoader: () async => [_temple],
        adminToolsEnabled: true,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(BrandedReleaseErrorScreen), findsNothing);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Temple Directory'), findsOneWidget);
    expect(find.text('Admin sign-in'), findsNothing);
    expect(AdminAuth.isInitialized, isFalse);

    await tester.tap(find.byKey(const Key('home-admin-menu')));
    await tester.pumpAndSettle();
    expect(AdminAuth.isInitialized, isFalse);

    await tester.tap(find.byKey(const Key('home-admin-sign-in')));
    await tester.pumpAndSettle();

    expect(AdminAuth.isInitialized, isTrue);
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });
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
  latitude: 0,
  longitude: 0,
);
