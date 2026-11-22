import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/services/review_prompt.dart';

import 'helpers/fake_review.dart';

void main() {
  final day0 = DateTime.utc(2026, 11, 1, 10);

  late FakeReviewClient client;
  late MemoryReviewPromptStore store;
  late DateTime now;

  ReviewPrompter prompter() =>
      ReviewPrompter(client: client, store: store, now: () => now);

  /// One process launch: a fresh prompter over the same storage.
  Future<bool> launch() => prompter().onSessionStart();

  setUp(() {
    client = FakeReviewClient();
    store = MemoryReviewPromptStore();
    now = day0;
  });

  group('session trigger', () {
    test('first launch never asks', () async {
      expect(await launch(), isFalse);
      expect(store.sessionCount, 1);
      expect(client.availabilityChecks, 0);
      expect(client.requests, 0);
    });

    test('second launch does not ask', () async {
      await launch();
      expect(await launch(), isFalse);
      expect(store.sessionCount, 2);
      expect(client.requests, 0);
    });

    test('third launch asks once, checking isAvailable first', () async {
      await launch();
      await launch();
      expect(await launch(), isTrue);
      expect(store.sessionCount, 3);
      expect(client.availabilityChecks, 1);
      expect(client.requests, 1);
      expect(store.lastPrompt, day0);
    });

    test('later launches do not re-ask on launch alone', () async {
      for (var i = 0; i < 3; i++) {
        await launch();
      }
      now = day0.add(const Duration(days: 90));
      expect(await launch(), isFalse);
      expect(await launch(), isFalse);
      expect(client.requests, 1);
    });

    test('a session is counted once per process', () async {
      final p = prompter();
      await p.onSessionStart();
      await p.onSessionStart();
      await p.onSessionStart();
      expect(store.sessionCount, 1);
      expect(client.requests, 0);
    });

    test('isAvailable false: no request and no cooldown stamp', () async {
      client.available = false;
      for (var i = 0; i < 3; i++) {
        await launch();
      }
      expect(client.availabilityChecks, 1);
      expect(client.requests, 0);
      expect(store.lastPrompt, isNull);
    });

    test('disabled prompter touches nothing', () async {
      final off = ReviewPrompter.disabled();
      expect(await off.onSessionStart(), isFalse);
      expect(await off.onPositiveMoment(ReviewTrigger.directions), isFalse);
    });
  });

  group('save and directions triggers', () {
    for (final trigger in [ReviewTrigger.save, ReviewTrigger.directions]) {
      test('${trigger.name} in the first session does not ask', () async {
        final p = prompter();
        await p.onSessionStart();
        expect(await p.onPositiveMoment(trigger), isFalse);
        expect(client.requests, 0);
      });

      test(
        '${trigger.name} before any session is counted does not ask',
        () async {
          expect(await prompter().onPositiveMoment(trigger), isFalse);
          expect(client.requests, 0);
        },
      );

      test('${trigger.name} in the second session asks', () async {
        await launch();
        final p = prompter();
        await p.onSessionStart();
        expect(await p.onPositiveMoment(trigger), isTrue);
        expect(client.requests, 1);
        expect(store.lastPrompt, day0);
      });
    }

    test('session is not accepted as an action trigger', () async {
      store.sessionCount = 5;
      expect(await prompter().onPositiveMoment(ReviewTrigger.session), isFalse);
      expect(client.requests, 0);
    });
  });

  group('30-day cooldown', () {
    Future<ReviewPrompter> secondSessionAfterPrompt() async {
      store.sessionCount = 4;
      store.lastPrompt = day0;
      final p = prompter();
      await p.onSessionStart();
      return p;
    }

    test('29 days after the last ask: no', () async {
      now = day0.add(const Duration(days: 29));
      final p = await secondSessionAfterPrompt();
      expect(await p.onPositiveMoment(ReviewTrigger.directions), isFalse);
      expect(client.availabilityChecks, 0);
    });

    test('29 days 23 hours 59 minutes: still no', () async {
      now = day0.add(const Duration(days: 30) - const Duration(minutes: 1));
      final p = await secondSessionAfterPrompt();
      expect(await p.onPositiveMoment(ReviewTrigger.save), isFalse);
    });

    test('exactly 30 days: yes', () async {
      now = day0.add(const Duration(days: 30));
      final p = await secondSessionAfterPrompt();
      expect(await p.onPositiveMoment(ReviewTrigger.directions), isTrue);
      expect(store.lastPrompt, now);
    });

    test('31 days: yes', () async {
      now = day0.add(const Duration(days: 31));
      final p = await secondSessionAfterPrompt();
      expect(await p.onPositiveMoment(ReviewTrigger.save), isTrue);
    });

    test('a last ask in the future (clock moved back) waits', () async {
      now = day0.subtract(const Duration(days: 3));
      final p = await secondSessionAfterPrompt();
      expect(await p.onPositiveMoment(ReviewTrigger.save), isFalse);
    });

    test('repeated saves within the cooldown ask only once', () async {
      await launch();
      final p = prompter();
      await p.onSessionStart();
      expect(await p.onPositiveMoment(ReviewTrigger.save), isTrue);
      for (var i = 1; i <= 10; i++) {
        now = day0.add(Duration(days: i * 2));
        expect(await p.onPositiveMoment(ReviewTrigger.save), isFalse);
        expect(await p.onPositiveMoment(ReviewTrigger.directions), isFalse);
      }
      expect(client.requests, 1);
    });

    test('third-launch ask then directions the same week: one ask', () async {
      await launch();
      await launch();
      final p = prompter();
      expect(await p.onSessionStart(), isTrue);
      now = day0.add(const Duration(days: 6));
      expect(await p.onPositiveMoment(ReviewTrigger.directions), isFalse);
      expect(client.requests, 1);
    });

    test('two triggers at once ask once', () async {
      store.sessionCount = 2;
      final p = prompter();
      final results = await Future.wait([
        p.onPositiveMoment(ReviewTrigger.save),
        p.onPositiveMoment(ReviewTrigger.directions),
      ]);
      expect(results.where((r) => r), hasLength(1));
      expect(client.requests, 1);
    });
  });

  group('fails silently', () {
    test('isAvailable throwing is swallowed', () async {
      client.availableError = Exception('Play services missing');
      store.sessionCount = 2;
      expect(
        await prompter().onPositiveMoment(ReviewTrigger.directions),
        isFalse,
      );
      expect(client.requests, 0);
    });

    test('requestReview throwing is swallowed and still stamps', () async {
      client.requestError = StateError('no activity');
      store.sessionCount = 2;
      final p = prompter();
      expect(await p.onPositiveMoment(ReviewTrigger.save), isFalse);
      expect(store.lastPrompt, day0);
      // In-flight guard is released after a throw; cooldown still holds.
      now = day0.add(const Duration(days: 1));
      expect(await p.onPositiveMoment(ReviewTrigger.save), isFalse);
      expect(client.requests, 1);
    });

    test('storage throwing is swallowed for sessions and actions', () async {
      final p = ReviewPrompter(
        client: client,
        store: ThrowingReviewPromptStore(),
        now: () => now,
      );
      expect(await p.onSessionStart(), isFalse);
      expect(await p.onPositiveMoment(ReviewTrigger.directions), isFalse);
      expect(client.requests, 0);
    });

    test('a missing plugin is swallowed', () async {
      SharedPreferences.setMockInitialValues({
        ReviewPromptKeys.sessionCount: 5,
      });
      final p = ReviewPrompter(
        store: SharedPreferencesReviewPromptStore(),
        now: () => now,
      );
      // The real InAppReview channel has no handler in tests.
      expect(await p.onPositiveMoment(ReviewTrigger.directions), isFalse);
    });
  });

  group('SharedPreferencesReviewPromptStore', () {
    test('round-trips the count and a UTC timestamp', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsStore = SharedPreferencesReviewPromptStore();
      expect(await prefsStore.readSessionCount(), 0);
      expect(await prefsStore.readLastPrompt(), isNull);
      await prefsStore.writeSessionCount(3);
      await prefsStore.writeLastPrompt(DateTime.utc(2026, 11, 13, 6, 30));
      expect(await prefsStore.readSessionCount(), 3);
      expect(
        await prefsStore.readLastPrompt(),
        DateTime.utc(2026, 11, 13, 6, 30),
      );
    });

    test('sessions persist across prompter instances', () async {
      SharedPreferences.setMockInitialValues({});
      for (var i = 0; i < 3; i++) {
        await ReviewPrompter(
          client: client,
          store: SharedPreferencesReviewPromptStore(),
          now: () => now,
        ).onSessionStart();
      }
      expect(client.requests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ReviewPromptKeys.sessionCount), 3);
      expect(
        prefs.getInt(ReviewPromptKeys.lastPromptMs),
        day0.millisecondsSinceEpoch,
      );
    });
  });
}
