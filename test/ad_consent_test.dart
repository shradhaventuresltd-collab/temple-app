import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:temple_app/services/ad_consent.dart';
import 'package:temple_app/services/ad_helper.dart';
import 'package:temple_app/widgets/app_drawer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('decideAdConsent', () {
    test('info-update failure is non-personalized', () {
      final decision = decideAdConsent(
        consentInfoUpdated: false,
        status: null,
        canRequestAds: null,
      );
      expect(decision.mode, AdConsentMode.nonPersonalized);
      expect(adRequestForMode(decision.mode).nonPersonalizedAds, isTrue);
      expect(consentAllowsAdRequest(decision.mode), isTrue);
    });

    test('not required allows personalized requests', () {
      final decision = decideAdConsent(
        consentInfoUpdated: true,
        status: ConsentStatus.notRequired,
        canRequestAds: true,
      );
      expect(decision.mode, AdConsentMode.personalized);
      expect(adRequestForMode(decision.mode).nonPersonalizedAds, isNot(true));
    });

    test('obtained lets UMP/TCF decide and does not force npa', () {
      final decision = decideAdConsent(
        consentInfoUpdated: true,
        status: ConsentStatus.obtained,
        canRequestAds: true,
        privacyOptionsRequired: true,
      );
      expect(decision.mode, AdConsentMode.umpHonored);
      expect(decision.privacyOptionsRequired, isTrue);
      expect(adRequestForMode(decision.mode).nonPersonalizedAds, isNot(true));
    });

    test('required form dismissed without consent requests no ads', () {
      final decision = decideAdConsent(
        consentInfoUpdated: true,
        status: ConsentStatus.required,
        canRequestAds: false,
        privacyOptionsRequired: true,
      );
      expect(decision.mode, AdConsentMode.adsDisabled);
      expect(consentAllowsAdRequest(decision.mode), isFalse);
    });

    test('unknown status that can still request ads is non-personalized', () {
      final decision = decideAdConsent(
        consentInfoUpdated: true,
        status: ConsentStatus.unknown,
        canRequestAds: true,
      );
      expect(decision.mode, AdConsentMode.nonPersonalized);
    });
  });

  group('buildConsentRequestParameters', () {
    test('release ignores debug geography and test device', () {
      final params = buildConsentRequestParameters(
        releaseMode: true,
        debugGeography: 'EEA',
        testDeviceId: 'hashed-device',
      );
      expect(params.consentDebugSettings, isNull);
    });

    test('debug EEA geography is passed with the test device id', () {
      final params = buildConsentRequestParameters(
        releaseMode: false,
        debugGeography: 'eea',
        testDeviceId: 'hashed-device',
      );
      expect(
        params.consentDebugSettings?.debugGeography,
        DebugGeography.debugGeographyEea,
      );
      expect(
        params.consentDebugSettings?.testIdentifiers,
        ['hashed-device'],
      );
    });

    test('blank debug settings stay off the request', () {
      final params = buildConsentRequestParameters(
        releaseMode: false,
      );
      expect(params.consentDebugSettings, isNull);
    });
  });

  group('AdHelper.initializeAds', () {
    test('runs UMP before MobileAds.initialize', () async {
      final order = <String>[];
      final consent = AdConsentController();
      await AdHelper.initializeAds(
        client: _FakeUmpClient(onCall: order.add),
        consent: consent,
        initializeMobileAds: () async {
          order.add('init');
        },
        consentParameters: ConsentRequestParameters(),
      );
      expect(order, ['info', 'form', 'init']);
      expect(consent.mode, AdConsentMode.personalized);
      expect(consent.isReady, isTrue);
    });

    test('info-update failure still initializes with non-personalized ads',
        () async {
      final order = <String>[];
      final consent = AdConsentController();
      await AdHelper.initializeAds(
        client: _FakeUmpClient(
          onCall: order.add,
          infoError: Exception('offline'),
        ),
        consent: consent,
        initializeMobileAds: () async {
          order.add('init');
        },
        consentParameters: ConsentRequestParameters(),
      );
      expect(order, ['info', 'init']);
      expect(consent.mode, AdConsentMode.nonPersonalized);
      expect(adRequestForMode(consent.mode).nonPersonalizedAds, isTrue);
    });

    test('dismissed required form initializes ads but does not request them',
        () async {
      final consent = AdConsentController();
      var initialized = false;
      await AdHelper.initializeAds(
        client: _FakeUmpClient(
          status: ConsentStatus.required,
          canRequest: false,
          privacyOptions: true,
        ),
        consent: consent,
        initializeMobileAds: () async {
          initialized = true;
        },
        consentParameters: ConsentRequestParameters(),
      );
      expect(initialized, isTrue);
      expect(consent.mode, AdConsentMode.adsDisabled);
      expect(consent.privacyOptionsRequired, isTrue);
      expect(consentAllowsAdRequest(consent.mode), isFalse);
    });

    test('form timeout falls back to non-personalized then applies a late choice',
        () async {
      final formGate = Completer<FormError?>();
      final consent = AdConsentController();
      final client = _FakeUmpClient(
        formGate: formGate,
        status: ConsentStatus.obtained,
        canRequest: true,
        privacyOptions: true,
      );
      await AdHelper.initializeAds(
        client: client,
        consent: consent,
        consentFormTimeout: const Duration(milliseconds: 30),
        initializeMobileAds: () async {},
        consentParameters: ConsentRequestParameters(),
      );
      expect(consent.mode, AdConsentMode.nonPersonalized);

      formGate.complete(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(consent.mode, AdConsentMode.umpHonored);
      expect(consent.privacyOptionsRequired, isTrue);
      expect(adRequestForMode(consent.mode).nonPersonalizedAds, isNot(true));
    });

    test('a form that finishes during ads init is not overwritten by the timeout',
        () async {
      final formGate = Completer<FormError?>();
      final consent = AdConsentController();
      final client = _FakeUmpClient(
        formGate: formGate,
        status: ConsentStatus.obtained,
        canRequest: true,
      );
      await AdHelper.initializeAds(
        client: client,
        consent: consent,
        consentFormTimeout: const Duration(milliseconds: 20),
        initializeMobileAds: () async {
          formGate.complete(null);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        },
        consentParameters: ConsentRequestParameters(),
      );
      expect(consent.mode, AdConsentMode.umpHonored);
      expect(consent.isReady, isTrue);
    });

    test('privacy options form refreshes the stored decision', () async {
      final consent = AdConsentController();
      consent.resolve(
        const AdConsentDecision(
          mode: AdConsentMode.adsDisabled,
          privacyOptionsRequired: true,
        ),
      );
      final client = _FakeUmpClient(
        status: ConsentStatus.obtained,
        canRequest: true,
        privacyOptions: true,
      );
      await AdHelper.presentPrivacyOptions(client: client, consent: consent);
      expect(client.calls, contains('privacy'));
      expect(consent.mode, AdConsentMode.umpHonored);
    });

    test('skips UMP off Android and iOS when no client is injected', () async {
      final previous = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final consent = AdConsentController();
      var initialized = false;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = previous;
      });
      await AdHelper.initializeAds(
        consent: consent,
        initializeMobileAds: () async {
          initialized = true;
        },
      );
      expect(initialized, isFalse);
      expect(consent.mode, AdConsentMode.adsDisabled);
    });
  });

  testWidgets('ad privacy tile is hidden until UMP requires it', (tester) async {
    final consent = AdConsentController();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdPrivacyChoicesTile(
            consent: consent,
            onShowPrivacyOptions: () async {
              opened++;
            },
          ),
        ),
      ),
    );
    expect(find.text('Ad privacy choices'), findsNothing);

    consent.resolve(
      const AdConsentDecision(
        mode: AdConsentMode.umpHonored,
        privacyOptionsRequired: true,
      ),
    );
    await tester.pump();
    expect(find.text('Ad privacy choices'), findsOneWidget);

    await tester.tap(find.text('Ad privacy choices'));
    await tester.pump();
    expect(opened, 1);
  });
}

class _FakeUmpClient implements UmpClient {
  _FakeUmpClient({
    this.onCall,
    this.status = ConsentStatus.notRequired,
    this.canRequest = true,
    this.privacyOptions = false,
    this.infoError,
    this.formGate,
  });

  final void Function(String call)? onCall;
  final ConsentStatus status;
  final bool canRequest;
  final bool privacyOptions;
  final Object? infoError;
  final Completer<FormError?>? formGate;
  final List<String> calls = [];

  void _mark(String call) {
    calls.add(call);
    onCall?.call(call);
  }

  @override
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params) async {
    _mark('info');
    final error = infoError;
    if (error != null) throw error;
  }

  @override
  Future<FormError?> showConsentFormIfRequired() {
    _mark('form');
    final gate = formGate;
    if (gate != null) return gate.future;
    return Future<FormError?>.value();
  }

  @override
  Future<FormError?> showPrivacyOptionsForm() async {
    _mark('privacy');
    return null;
  }

  @override
  Future<ConsentStatus> consentStatus() async => status;

  @override
  Future<bool> canRequestAds() async => canRequest;

  @override
  Future<bool> privacyOptionsRequired() async => privacyOptions;
}
