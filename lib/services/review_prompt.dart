import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/services/app_analytics.dart';

/// Positive moments that may ask for a Play review.
enum ReviewTrigger {
  /// The [ReviewPrompter.sessionMilestone]th launch that reaches Home.
  session,

  /// The user saved a place. Main has no save action yet; the trigger is
  /// ready for when one lands.
  save,

  /// Get Directions opened Maps and the user came back to the app.
  directions,
}

/// `review_requested` trigger values: session3, directions, save.
String reviewTriggerAnalyticsName(ReviewTrigger trigger) => switch (trigger) {
  ReviewTrigger.session => 'session${ReviewPrompter.sessionMilestone}',
  ReviewTrigger.directions => 'directions',
  ReviewTrigger.save => 'save',
};

/// Google Play In-App Review. Tests pass a fake.
abstract class ReviewClient {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

class InAppReviewClient implements ReviewClient {
  const InAppReviewClient();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

/// Launch count and the last time a review was requested.
abstract class ReviewPromptStore {
  Future<int> readSessionCount();

  Future<void> writeSessionCount(int count);

  Future<DateTime?> readLastPrompt();

  Future<void> writeLastPrompt(DateTime at);

  /// The session-milestone ask was held back (soft-update banner on the
  /// same Home open) and is still owed on a later open.
  Future<bool> readSessionDeferred();

  Future<void> writeSessionDeferred(bool deferred);
}

abstract final class ReviewPromptKeys {
  static const String sessionCount = 'review_prompt_session_count';
  static const String lastPromptMs = 'review_prompt_last_ms';
  static const String sessionDeferred = 'review_prompt_session_deferred';
}

class SharedPreferencesReviewPromptStore implements ReviewPromptStore {
  SharedPreferencesReviewPromptStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<int> readSessionCount() async {
    final prefs = await _preferences();
    return prefs.getInt(ReviewPromptKeys.sessionCount) ?? 0;
  }

  @override
  Future<void> writeSessionCount(int count) async {
    final prefs = await _preferences();
    await prefs.setInt(ReviewPromptKeys.sessionCount, count);
  }

  @override
  Future<DateTime?> readLastPrompt() async {
    final prefs = await _preferences();
    final ms = prefs.getInt(ReviewPromptKeys.lastPromptMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> writeLastPrompt(DateTime at) async {
    final prefs = await _preferences();
    await prefs.setInt(
      ReviewPromptKeys.lastPromptMs,
      at.toUtc().millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> readSessionDeferred() async {
    final prefs = await _preferences();
    return prefs.getBool(ReviewPromptKeys.sessionDeferred) ?? false;
  }

  @override
  Future<void> writeSessionDeferred(bool deferred) async {
    final prefs = await _preferences();
    if (deferred) {
      await prefs.setBool(ReviewPromptKeys.sessionDeferred, true);
    } else {
      await prefs.remove(ReviewPromptKeys.sessionDeferred);
    }
  }
}

/// In-memory store for tests.
class MemoryReviewPromptStore implements ReviewPromptStore {
  MemoryReviewPromptStore({
    this.sessionCount = 0,
    this.lastPrompt,
    this.sessionDeferred = false,
  });

  int sessionCount;
  DateTime? lastPrompt;
  bool sessionDeferred;

  @override
  Future<int> readSessionCount() async => sessionCount;

  @override
  Future<void> writeSessionCount(int count) async {
    sessionCount = count;
  }

  @override
  Future<DateTime?> readLastPrompt() async => lastPrompt;

  @override
  Future<void> writeLastPrompt(DateTime at) async {
    lastPrompt = at;
  }

  @override
  Future<bool> readSessionDeferred() async => sessionDeferred;

  @override
  Future<void> writeSessionDeferred(bool deferred) async {
    sessionDeferred = deferred;
  }
}

/// Asks for a Play review after a positive moment.
///
/// * Never in the first session (fresh install or cleared data).
/// * [ReviewTrigger.session] fires once, on the [sessionMilestone]th launch.
/// * [ReviewTrigger.save] and [ReviewTrigger.directions] fire from the
///   second session on.
/// * At most one request per [cooldown], whatever the trigger.
/// * Not on a Home open that shows the soft-update banner: the session ask
///   is deferred, not spent, and runs on the next open.
/// * Logs `review_requested` (trigger only) when Play is actually asked.
/// * Fails silently: every error is caught and logged in debug, nothing is
///   shown, and callers never await it on a UI path.
///
/// The timestamp is written before `requestReview`, so a throw or a second
/// trigger while the first is in flight cannot ask twice. Play applies its
/// own quota on top of this, so a request may show nothing.
class ReviewPrompter {
  ReviewPrompter({
    ReviewClient? client,
    ReviewPromptStore? store,
    DateTime Function()? now,
    AppAnalytics? analytics,
    this.enabled = true,
  }) : _client = client ?? const InAppReviewClient(),
       _store = store ?? SharedPreferencesReviewPromptStore(),
       _now = now ?? DateTime.now,
       _analytics = analytics;

  /// Off: every call returns false without touching storage or Play.
  ReviewPrompter.disabled()
    : _client = const InAppReviewClient(),
      _store = MemoryReviewPromptStore(),
      _now = DateTime.now,
      _analytics = null,
      enabled = false;

  static const Duration cooldown = Duration(days: 30);
  static const int sessionMilestone = 3;

  /// Action triggers need at least this many sessions (never the first).
  static const int minSessionsForActions = 2;

  static ReviewPrompter instance = ReviewPrompter();

  /// Test hook. Production does not call this.
  @visibleForTesting
  static void resetForTest([ReviewPrompter? replacement]) {
    instance = replacement ?? ReviewPrompter();
  }

  final ReviewClient _client;
  final ReviewPromptStore _store;
  final DateTime Function() _now;

  /// Null uses [AppAnalytics.instance] at call time.
  final AppAnalytics? _analytics;
  final bool enabled;

  bool _sessionCounted = false;
  bool _inFlight = false;
  int? _sessionCount;

  /// Counts this launch once per process, then checks the session trigger.
  /// Returns true only when a review was requested.
  ///
  /// [softUpdateShown] resolves to whether this Home open shows the
  /// soft-update banner. When it does, the session ask is deferred to the
  /// next open instead of being spent.
  Future<bool> onSessionStart({Future<bool>? softUpdateShown}) async {
    if (!enabled || _sessionCounted) return false;
    _sessionCounted = true;
    var wasDeferred = false;
    try {
      final count = await _store.readSessionCount() + 1;
      _sessionCount = count;
      await _store.writeSessionCount(count);
      if (count > sessionMilestone) {
        wasDeferred = await _store.readSessionDeferred();
      }
      if (count != sessionMilestone && !wasDeferred) return false;
      if (softUpdateShown != null && await _shown(softUpdateShown)) {
        if (!wasDeferred) await _store.writeSessionDeferred(true);
        return false;
      }
      if (wasDeferred) await _store.writeSessionDeferred(false);
    } catch (e, st) {
      debugPrint('Review prompt session count failed: $e\n$st');
      return false;
    }
    return _maybeRequest(ReviewTrigger.session);
  }

  static Future<bool> _shown(Future<bool> decision) async {
    try {
      return await decision;
    } catch (_) {
      return false;
    }
  }

  /// A save or a completed directions hand-off. Returns true only when a
  /// review was requested.
  Future<bool> onPositiveMoment(ReviewTrigger trigger) {
    if (trigger == ReviewTrigger.session) return Future.value(false);
    return _maybeRequest(trigger);
  }

  Future<bool> _maybeRequest(ReviewTrigger trigger) async {
    if (!enabled || _inFlight) return false;
    _inFlight = true;
    try {
      final sessions = _sessionCount ?? await _store.readSessionCount();
      final needed = trigger == ReviewTrigger.session
          ? sessionMilestone
          : minSessionsForActions;
      if (sessions < needed) return false;
      final now = _now().toUtc();
      final last = await _store.readLastPrompt();
      // A last prompt in the future (clock moved back) also waits.
      if (last != null && now.difference(last.toUtc()) < cooldown) {
        return false;
      }
      if (!await _client.isAvailable()) return false;
      await _store.writeLastPrompt(now);
      unawaited(
        (_analytics ?? AppAnalytics.instance).logReviewRequested(
          reviewTriggerAnalyticsName(trigger),
        ),
      );
      await _client.requestReview();
      return true;
    } catch (e, st) {
      debugPrint('Review prompt (${trigger.name}) failed: $e\n$st');
      return false;
    } finally {
      _inFlight = false;
    }
  }
}
