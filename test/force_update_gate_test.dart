import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/force_update_screen.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/update_nudge_store.dart';
import 'package:temple_app/widgets/soft_update_nudge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'a build below min_supported_build blocks after the policy gate',
    (tester) async {
      var loads = 0;
      var ads = 0;
      final store = _MemoryPolicyStore();
      final uris = <Uri>[];

      await tester.pumpWidget(
        _app(
          store: store,
          buildNumber: 2,
          config: const AppConfig(minSupportedBuild: 5, recommendedBuild: 5),
          loads: () => loads++,
          ads: () => ads++,
          launchStoreUrl: (uri) async {
            uris.add(uri);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PolicyAcceptanceGate), findsOneWidget);
      expect(find.byType(ForceUpdateScreen), findsNothing);
      expect(loads, 0);

      await tester.tap(find.text('Accept & continue'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('force-update-screen')), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(loads, 0);
      expect(ads, 0);

      await tester.tap(find.byKey(const Key('force-update-button')));
      await tester.pumpAndSettle();
      expect(
        uris.single,
        Uri.parse('market://details?id=com.shradhaventures.temple'),
      );

      final handled = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(handled, isTrue);
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('a build below recommended_build shows a dismissible nudge', (
    tester,
  ) async {
    final nudge = MemoryUpdateNudgeStore();
    final uris = <Uri>[];
    await tester.pumpWidget(
      _app(
        store: _AcceptedStore(),
        buildNumber: 3,
        config: const AppConfig(minSupportedBuild: 1, recommendedBuild: 6),
        nudgeStore: nudge,
        now: () => DateTime.utc(2026, 10, 16, 8),
        launchStoreUrl: (uri) async {
          uris.add(uri);
          return uri.scheme == 'https';
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('soft-update-nudge')), findsOneWidget);
    expect(find.text(SoftUpdateNudgeBanner.message), findsOneWidget);

    await tester.tap(find.byKey(const Key('soft-update-open')));
    await tester.pumpAndSettle();
    expect(uris.map((uri) => uri.scheme), ['market', 'https']);

    await tester.tap(find.byKey(const Key('soft-update-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('soft-update-nudge')), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(nudge.day, '2026-10-16');
  });

  testWidgets('the soft nudge is not shown again the same day', (tester) async {
    final nudge = MemoryUpdateNudgeStore()..day = '2026-10-16';
    await tester.pumpWidget(
      _app(
        store: _AcceptedStore(),
        buildNumber: 3,
        config: const AppConfig(minSupportedBuild: 1, recommendedBuild: 6),
        nudgeStore: nudge,
        now: () => DateTime.utc(2026, 10, 16, 18),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('soft-update-nudge')), findsNothing);
  });

  testWidgets('a current build opens Home with no nudge', (tester) async {
    await tester.pumpWidget(
      _app(
        store: _AcceptedStore(),
        buildNumber: 6,
        config: const AppConfig(minSupportedBuild: 1, recommendedBuild: 6),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ForceUpdateScreen), findsNothing);
    expect(find.byKey(const Key('soft-update-nudge')), findsNothing);
  });

  testWidgets('a missing build number fails open', (tester) async {
    await tester.pumpWidget(
      _app(
        store: _AcceptedStore(),
        buildNumber: null,
        config: const AppConfig(minSupportedBuild: 40, recommendedBuild: 41),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ForceUpdateScreen), findsNothing);
  });

  testWidgets('the demo application id is the Play listing that is opened', (
    tester,
  ) async {
    final uris = <Uri>[];
    await tester.pumpWidget(
      _app(
        store: _AcceptedStore(),
        buildNumber: 1,
        config: const AppConfig(minSupportedBuild: 4, recommendedBuild: 4),
        demoAppIdSuffix: true,
        launchStoreUrl: (uri) async {
          uris.add(uri);
          return false;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('force-update-button')));
    await tester.pumpAndSettle();
    expect(uris, [
      Uri.parse('market://details?id=com.shradhaventures.temple.demo'),
      Uri.parse(
        'https://play.google.com/store/apps/details?id=com.shradhaventures.temple.demo',
      ),
    ]);
  });
}

TempleDirectoryApp _app({
  required PolicyAcceptanceStore store,
  required Object? buildNumber,
  required AppConfig config,
  UpdateNudgeStore? nudgeStore,
  DateTime Function()? now,
  Future<bool> Function(Uri url)? launchStoreUrl,
  bool? demoAppIdSuffix,
  void Function()? loads,
  void Function()? ads,
}) {
  return TempleDirectoryApp(
    acceptanceStore: store,
    initializeFirebase: () async => false,
    initializeAds: () async {
      ads?.call();
    },
    templesLoader: () async {
      loads?.call();
      return [_temple];
    },
    appConfig: AppConfigController(initial: config),
    installedBuildNumber: buildNumber,
    nudgeStore: nudgeStore,
    now: now,
    launchStoreUrl: launchStoreUrl,
    demoAppIdSuffix: demoAppIdSuffix,
    onExitApp: () {},
    launchPolicyUrl: (_) async => true,
    adminToolsEnabled: false,
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

class _MemoryPolicyStore implements PolicyAcceptanceStore {
  PolicyAcceptance? value;

  @override
  Future<PolicyAcceptance?> read() async => value;

  @override
  Future<void> write(PolicyAcceptance acceptance) async {
    value = acceptance;
  }
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
);
