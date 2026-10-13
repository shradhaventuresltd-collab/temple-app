import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first launch shows the gate and does not start ads or Home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final store = _MemoryPolicyAcceptanceStore();
      var adsCalls = 0;

      await tester.pumpWidget(
        _app(
          store: store,
          initializeAds: () async {
            adsCalls++;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PolicyAcceptanceGate), findsOneWidget);
      expect(find.text(PolicyGateCopy.firstLaunchTitle), findsOneWidget);
      expect(find.text(PolicyGateCopy.firstLaunchBody), findsOneWidget);
      expect(find.text(PolicyGateCopy.acceptButton), findsOneWidget);
      expect(find.text(PolicyGateCopy.updateTitle), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Decline'), findsNothing);
      expect(adsCalls, 0);
      expect(store.value, isNull);

      final accept = tester.getSemantics(
        find.byKey(const Key('policy-accept-button')),
      );
      expect(accept.label, PolicyGateCopy.acceptButton);
      expect(accept.hint, PolicyGateCopy.acceptHint);
      expect(accept.identifier, 'policy-accept-button');
      expect(accept.flagsCollection.isButton, isTrue);

      final terms = tester.getSemantics(
        find.byKey(const Key('policy-terms-link')),
      );
      expect(terms.label, PolicyGateCopy.termsLabel);
      expect(terms.hint, PolicyGateCopy.linkHint);
      expect(terms.identifier, 'policy-terms-link');
      expect(terms.flagsCollection.isButton, isTrue);
      expect(terms.flagsCollection.isLink, isTrue);

      final privacy = tester.getSemantics(
        find.byKey(const Key('policy-privacy-link')),
      );
      expect(privacy.label, PolicyGateCopy.privacyLabel);
      expect(privacy.identifier, 'policy-privacy-link');
      expect(privacy.flagsCollection.isLink, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('accept persists the version and timestamp, then opens Home', (
    tester,
  ) async {
    final store = _MemoryPolicyAcceptanceStore();
    final acceptedAt = DateTime.utc(2026, 10, 13, 12);
    final ads = Completer<void>();
    var adsCalls = 0;

    await tester.pumpWidget(
      _app(
        store: store,
        now: () => acceptedAt,
        initializeAds: () {
          adsCalls++;
          expect(store.value, isNotNull);
          expect(store.value!.version, PolicyConfig.currentVersion);
          expect(store.value!.acceptedAt, acceptedAt);
          return ads.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pumpAndSettle();

    expect(adsCalls, 1);
    expect(store.writes, 1);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text(PolicyGateCopy.consentWait), findsOneWidget);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);

    ads.complete();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Temple Directory'), findsOneWidget);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);

    var secondAds = 0;
    // A new process, not a rebuild of the widget already showing Home.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(
        store: store,
        initializeAds: () async {
          secondAds++;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(secondAds, 1);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(store.value!.version, PolicyConfig.currentVersion);
    expect(store.value!.acceptedAt, acceptedAt);
  });

  testWidgets('a higher policy version shows the update gate again', (
    tester,
  ) async {
    final store = _MemoryPolicyAcceptanceStore()
      ..value = PolicyAcceptance(
        version: PolicyConfig.currentVersion,
        acceptedAt: DateTime.utc(2026, 1, 1),
      );
    final bumped = PolicyConfig.currentVersion + 1;
    var adsCalls = 0;

    await tester.pumpWidget(
      _app(
        store: store,
        currentPolicyVersion: bumped,
        initializeAds: () async {
          adsCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(PolicyGateCopy.updateTitle), findsOneWidget);
    expect(find.text(PolicyGateCopy.updateBody), findsOneWidget);
    expect(find.text(PolicyGateCopy.firstLaunchTitle), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(adsCalls, 0);

    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pumpAndSettle();

    expect(adsCalls, 1);
    expect(store.value!.version, bumped);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('back on the gate exits and does not skip to Home', (
    tester,
  ) async {
    final store = _MemoryPolicyAcceptanceStore();
    var exited = 0;
    var adsCalls = 0;

    await tester.pumpWidget(
      _app(
        store: store,
        onExitApp: () => exited++,
        initializeAds: () async {
          adsCalls++;
        },
      ),
    );
    await tester.pumpAndSettle();

    final handled = await tester.binding.handlePopRoute();
    await tester.pump();

    expect(handled, isTrue);
    expect(exited, 1);
    expect(adsCalls, 0);
    expect(store.value, isNull);
    expect(find.byType(PolicyAcceptanceGate), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('policy links open the configured https pages', (tester) async {
    final launched = <Uri>[];

    await tester.pumpWidget(
      _app(
        store: _MemoryPolicyAcceptanceStore(),
        launchPolicyUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('policy-terms-link')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('policy-privacy-link')));
    await tester.pump();

    expect(launched, [
      PolicyConfig.termsOfServiceUri,
      PolicyConfig.privacyPolicyUri,
    ]);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('accept and policy links are at least 48dp at 360dp width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(store: _MemoryPolicyAcceptanceStore()));
    await tester.pumpAndSettle();

    void expectTarget(Key key) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$key height');
    }

    expectTarget(const Key('policy-accept-button'));
    expectTarget(const Key('policy-terms-link'));
    expectTarget(const Key('policy-privacy-link'));
    expect(tester.takeException(), isNull);
  });
}

class _MemoryPolicyAcceptanceStore implements PolicyAcceptanceStore {
  PolicyAcceptance? value;
  int writes = 0;

  @override
  Future<PolicyAcceptance?> read() async => value;

  @override
  Future<void> write(PolicyAcceptance acceptance) async {
    writes++;
    value = acceptance;
  }
}

Widget _app({
  required _MemoryPolicyAcceptanceStore store,
  int? currentPolicyVersion,
  Future<void> Function()? initializeAds,
  DateTime Function()? now,
  VoidCallback? onExitApp,
  Future<bool> Function(Uri url)? launchPolicyUrl,
}) {
  return TempleDirectoryApp(
    acceptanceStore: store,
    currentPolicyVersion: currentPolicyVersion ?? PolicyConfig.currentVersion,
    initializeFirebase: () async => true,
    initializeAds: initializeAds ?? () async {},
    templesLoader: () async => const <Temple>[],
    adminAuth: FakeAdminAuth(),
    adminToolsEnabled: false,
    now: now ?? () => DateTime.utc(2026, 10, 13, 12),
    onExitApp: onExitApp,
    launchPolicyUrl: launchPolicyUrl ?? (_) async => true,
  );
}
