import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/main.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/release_error_widget.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

import 'helpers/fake_admin_auth.dart';

void main() {
  test('release error widget keeps the exception text', () {
    final details = FlutterErrorDetails(
      exception: Exception('boom-marker'),
      stack: StackTrace.fromString('#0 gate\n#1 main\n'),
    );
    final message = releaseErrorMessage(details);
    expect(message, contains('boom-marker'));
    expect(message, contains('#0 gate'));
    expect(message, isNot(contains('See also:')));

    final widget = releaseErrorWidget(details);
    expect(widget, isA<ErrorWidget>());
    expect((widget as ErrorWidget).message, message);
  });

  test('installReleaseErrorWidget replaces the default builder', () {
    final previous = ErrorWidget.builder;
    try {
      installReleaseErrorWidget();
      expect(ErrorWidget.builder, same(releaseErrorWidget));
    } finally {
      ErrorWidget.builder = previous;
    }
  });

  testWidgets('gate paints when runtime font fetching is off', (tester) async {
    final previousFetching = GoogleFonts.config.allowRuntimeFetching;
    addTearDown(
      () => GoogleFonts.config.allowRuntimeFetching = previousFetching,
    );
    // Same switch as main(). A missing bundled file becomes an unhandled
    // google_fonts error and fails this test.
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      TempleDirectoryApp(
        acceptanceStore: _Store(),
        currentPolicyVersion: PolicyConfig.currentVersion,
        initializeFirebase: () async => true,
        initializeAds: () async {},
        templesLoader: () async => const <Temple>[],
        adminAuth: FakeAdminAuth(),
        adminToolsEnabled: true,
        now: () => DateTime.utc(2026, 10, 14),
        onExitApp: () {},
        launchPolicyUrl: (_) async => true,
      ),
    );
    await tester.pump();
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(PolicyAcceptanceGate), findsOneWidget);
    expect(find.text(PolicyGateCopy.firstLaunchTitle), findsOneWidget);
  });
}

class _Store implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async => null;

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}
