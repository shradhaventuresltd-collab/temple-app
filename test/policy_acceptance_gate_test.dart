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
      expect(
        find.textContaining(PolicyGateCopy.firstLaunchLead),
        findsOneWidget,
      );
      expect(find.text(PolicyGateCopy.termsLabel), findsOneWidget);
      expect(find.text(PolicyGateCopy.privacyLabel), findsOneWidget);
      expect(find.text(PolicyGateCopy.acceptButton), findsOneWidget);
      expect(find.text(PolicyGateCopy.appName), findsOneWidget);
      expect(find.text(PolicyGateCopy.updateTitle), findsNothing);
      expect(find.text('Terms and privacy'), findsNothing);
      expect(find.text('Policy update'), findsNothing);
      expect(find.textContaining('13 and older'), findsNothing);
      expect(find.byIcon(Icons.temple_hindu_rounded), findsNothing);

      final title = tester.widget<Text>(
        find.text(PolicyGateCopy.firstLaunchTitle),
      );
      expect(title.style?.color, PolicyGateColors.navy);
      final termsText = tester.widget<Text>(
        find.text(PolicyGateCopy.termsLabel),
      );
      expect(termsText.style?.decoration, TextDecoration.underline);
      expect(termsText.style?.color, PolicyGateColors.saffron);
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

    expect(ads.isCompleted, isFalse);
    expect(adsCalls, 1);
    expect(store.writes, 1);
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
    expect(find.textContaining(PolicyGateCopy.updateLead), findsOneWidget);
    expect(find.text(PolicyGateCopy.updateTermsLabel), findsOneWidget);
    expect(find.text(PolicyGateCopy.privacyLabel), findsOneWidget);
    expect(find.textContaining('to continue.'), findsOneWidget);
    expect(find.text(PolicyGateCopy.firstLaunchTitle), findsNothing);
    final title = tester.widget<Text>(find.text(PolicyGateCopy.updateTitle));
    expect(title.style?.color, PolicyGateColors.navy);
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

    final accept = tester.getRect(
      find.byKey(const Key('policy-accept-button')),
    );
    final view = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(accept.bottom, greaterThan(view.height - 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home is built while ads init is still pending', (tester) async {
    final store = _MemoryPolicyAcceptanceStore();
    final ads = Completer<void>();
    var adsCalls = 0;

    await tester.pumpWidget(
      _app(
        store: store,
        initializeAds: () {
          adsCalls++;
          return ads.future;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    expect(adsCalls, 0);

    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pumpAndSettle();

    expect(ads.isCompleted, isFalse);
    expect(adsCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Temple Directory'), findsOneWidget);

    final returningAds = Completer<void>();
    var returningCalls = 0;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(
        store: store,
        initializeAds: () {
          returningCalls++;
          return returningAds.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(returningAds.isCompleted, isFalse);
    expect(returningCalls, 1);
    expect(find.byType(PolicyAcceptanceGate), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Accept stays on screen at text scale 2.0', (tester) async {
    await _expectAcceptReachable(
      tester,
      size: const Size(360, 800),
      textScale: 2,
    );
  });

  testWidgets('Accept stays on screen in a 640x360 landscape layout', (
    tester,
  ) async {
    await _expectAcceptReachable(tester, size: const Size(640, 360));
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

Future<void> _expectAcceptReachable(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  await tester.pumpWidget(_app(store: _MemoryPolicyAcceptanceStore()));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final accept = find.byKey(const Key('policy-accept-button'));
  await tester.ensureVisible(accept);
  await tester.pumpAndSettle();

  expect(accept, findsOneWidget);
  final rect = tester.getRect(accept);
  final viewport = Offset.zero & size;
  expect(
    viewport.contains(rect.center),
    isTrue,
    reason: 'Accept center $rect is outside $viewport',
  );
  expect(rect.width, greaterThanOrEqualTo(48));
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(tester.takeException(), isNull);

  await tester.tap(accept);
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.text(PolicyGateCopy.acceptButton), findsNothing);
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
