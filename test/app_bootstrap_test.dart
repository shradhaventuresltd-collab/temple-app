import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/ad_consent.dart';
import 'package:temple_app/services/app_bootstrap.dart';

void main() {
  group('AppBootstrap.initializeFirebase', () {
    test('returns false when initialize times out', () async {
      final ok = await AppBootstrap.initializeFirebase(
        initialize: () => Future<void>.delayed(const Duration(days: 1)),
        timeout: const Duration(milliseconds: 40),
      );
      expect(ok, isFalse);
    });

    test('returns false when initialize throws', () async {
      final ok = await AppBootstrap.initializeFirebase(
        initialize: () async => throw Exception('firebase unavailable'),
      );
      expect(ok, isFalse);
    });

    test('demo distribution passes no Dart options', () {
      const configured = FirebaseOptions(
        apiKey: 'key',
        appId: 'app',
        messagingSenderId: 'sender',
        projectId: 'project',
      );
      expect(
        startupFirebaseOptions(
          demoAppIdSuffix: true,
          isWeb: false,
          isAndroid: true,
          configured: configured,
        ),
        isNull,
      );
    });

    test('seed and Play flavours pass the configured options', () {
      const configured = FirebaseOptions(
        apiKey: 'key',
        appId: 'app',
        messagingSenderId: 'sender',
        projectId: 'project',
      );
      expect(
        startupFirebaseOptions(
          demoAppIdSuffix: false,
          isWeb: false,
          isAndroid: true,
          configured: configured,
        ),
        same(configured),
      );
      expect(
        startupFirebaseOptions(
          demoAppIdSuffix: true,
          isWeb: true,
          isAndroid: false,
          configured: configured,
        ),
        same(configured),
      );
    });

    test('returns true when initialize completes', () async {
      var called = false;
      final ok = await AppBootstrap.initializeFirebase(
        initialize: () async {
          called = true;
        },
      );
      expect(ok, isTrue);
      expect(called, isTrue);
    });

    test('configures Firestore after init and not when init fails', () async {
      var configured = false;
      final ok = await AppBootstrap.initializeFirebase(
        initialize: () async {},
        configureFirestore: () => configured = true,
      );
      expect(ok, isTrue);
      expect(configured, isTrue);

      configured = false;
      final failed = await AppBootstrap.initializeFirebase(
        initialize: () async => throw Exception('firebase unavailable'),
        configureFirestore: () => configured = true,
      );
      expect(failed, isFalse);
      expect(configured, isFalse);
    });

    test('a Firestore settings failure still counts Firebase as ready', () async {
      final ok = await AppBootstrap.initializeFirebase(
        initialize: () async {},
        configureFirestore: () => throw Exception('settings unavailable'),
      );
      expect(ok, isTrue);
    });
  });

  group('AppBootstrap.initializeAdsSafely', () {
    tearDown(AdConsentController.instance.resetForTest);

    test('startup cap outlasts the consent form cap', () {
      expect(
        AppBootstrap.adsStartupTimeout,
        greaterThan(
          AppBootstrap.consentFormTimeout + AppBootstrap.mobileAdsTimeout,
        ),
      );
    });

    test('completes when initialize throws and unblocks ads as NPA', () async {
      await AppBootstrap.initializeAdsSafely(
        initialize: () async => throw Exception('ads unavailable'),
      );
      expect(AdConsentController.instance.isReady, isTrue);
      expect(AdConsentController.instance.mode, AdConsentMode.nonPersonalized);
      expect(
        adRequestForMode(AdConsentController.instance.mode).nonPersonalizedAds,
        isTrue,
      );
    });

    test(
      'completes when initialize times out and unblocks ads as NPA',
      () async {
        final hung = Completer<void>();
        await AppBootstrap.initializeAdsSafely(
          initialize: () => hung.future,
          timeout: const Duration(milliseconds: 40),
        );
        expect(AdConsentController.instance.isReady, isTrue);
        expect(
          AdConsentController.instance.mode,
          AdConsentMode.nonPersonalized,
        );
      },
    );

    test('completes when initialize succeeds', () async {
      var called = false;
      await AppBootstrap.initializeAdsSafely(
        initialize: () async {
          called = true;
        },
      );
      expect(called, isTrue);
    });
  });
}
