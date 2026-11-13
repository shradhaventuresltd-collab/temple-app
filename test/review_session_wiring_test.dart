import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/review_prompt.dart';

import 'helpers/fake_review.dart';

const _temple = Temple(
  name: 'Meenakshi Amman Temple',
  state: 'Tamil Nadu',
  city: 'Madurai',
  deity: 'Devi',
  imageUrl: '',
  description: '',
  story: '',
  location: '',
  timings: null,
  specialities: [],
);

class _AcceptedStore implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async => PolicyAcceptance(
    version: PolicyConfig.currentVersion,
    acceptedAt: DateTime.utc(2026, 10, 14),
  );

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

class _EmptyStore implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async => null;

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> launch(
    WidgetTester tester, {
    required ReviewPrompter prompter,
    PolicyAcceptanceStore? acceptance,
  }) async {
    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: acceptance ?? _AcceptedStore(),
        initializeFirebase: () async => true,
        initializeAds: () async {},
        templesLoader: () async => [_temple],
        adminToolsEnabled: false,
        installedBuildNumber: null,
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
        reviewPrompter: prompter,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reaching Home counts one session; the third launch asks', (
    tester,
  ) async {
    final client = FakeReviewClient();
    final store = MemoryReviewPromptStore();
    ReviewPrompter prompter() => ReviewPrompter(
      client: client,
      store: store,
      now: () => DateTime.utc(2026, 11, 13),
    );

    await launch(tester, prompter: prompter());
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(store.sessionCount, 1);
    expect(client.requests, 0);

    await tester.pumpWidget(const SizedBox());
    await launch(tester, prompter: prompter());
    expect(store.sessionCount, 2);
    expect(client.requests, 0);

    await tester.pumpWidget(const SizedBox());
    await launch(tester, prompter: prompter());
    expect(store.sessionCount, 3);
    expect(client.requests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Terms gate on first launch does not count a session', (
    tester,
  ) async {
    final store = MemoryReviewPromptStore();
    final client = FakeReviewClient();
    await launch(
      tester,
      prompter: ReviewPrompter(client: client, store: store),
      acceptance: _EmptyStore(),
    );
    expect(find.byType(HomeScreen), findsNothing);
    expect(store.sessionCount, 0);
    expect(client.availabilityChecks, 0);
  });

  testWidgets('a throwing review store still opens Home', (tester) async {
    await launch(
      tester,
      prompter: ReviewPrompter(
        client: FakeReviewClient(),
        store: ThrowingReviewPromptStore(),
      ),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
