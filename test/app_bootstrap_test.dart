import 'package:flutter_test/flutter_test.dart';
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
  });

  group('AppBootstrap.initializeAdsSafely', () {
    test('completes when initialize throws', () async {
      await AppBootstrap.initializeAdsSafely(
        initialize: () async => throw Exception('ads unavailable'),
      );
    });

    test('completes when initialize times out', () async {
      await AppBootstrap.initializeAdsSafely(
        initialize: () => Future<void>.delayed(const Duration(days: 1)),
        timeout: const Duration(milliseconds: 40),
      );
    });

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
