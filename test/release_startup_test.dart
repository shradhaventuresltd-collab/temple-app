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

  test('kDebugMode shows the exception text and stack', () {
    expectDetailedErrorBranch(debug: true, demoBuild: false, adminTools: false);
  });

  test('release DEMO_BUILD shows the branded screen, not a stack', () {
    expectBrandedReleaseBranch(demoBuild: true, adminTools: false);
  });

  test('release ENABLE_ADMIN_TOOLS shows the branded screen, not a stack', () {
    expectBrandedReleaseBranch(demoBuild: false, adminTools: true);
  });

  testWidgets(
    'production AAB shows a branded screen and does not report twice',
    (tester) async {
      final previousBuilder = ErrorWidget.builder;
      try {
        expect(
          showDetailedReleaseError(
            debug: false,
            demoBuild: false,
            adminTools: false,
          ),
          isFalse,
        );
        installReleaseErrorWidget(
          debug: false,
          demoBuild: false,
          adminTools: false,
        );
        expect(ErrorWidget.builder, same(productionReleaseErrorWidget));

        final reported = <FlutterErrorDetails>[];
        final printed = <String>[];
        final previousOnError = FlutterError.onError;
        final previousDebugPrint = debugPrint;
        FlutterError.onError = reported.add;
        debugPrint = (String? message, {int? wrapWidth}) {
          printed.add(message ?? '');
        };
        final details = _boomDetails();
        late final Widget screen;
        try {
          // The framework reports once, then builds the fallback.
          FlutterError.reportError(details);
          screen = ErrorWidget.builder(details);
        } finally {
          FlutterError.onError = previousOnError;
          debugPrint = previousDebugPrint;
        }

        await tester.pumpWidget(screen);

        expect(find.byType(BrandedReleaseErrorScreen), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.text(BrandedReleaseErrorScreen.message), findsOneWidget);
        expect(find.text(BrandedReleaseErrorScreen.appName), findsOneWidget);
        expect(find.textContaining('boom-marker'), findsNothing);
        expect(find.textContaining('#0 gate'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);

        expect(reported, hasLength(1));
        expect(reported.single.exceptionAsString(), contains('boom-marker'));
        expect(reported.single.stack.toString(), contains('#0 gate'));
        expect(printed, isEmpty);
      } finally {
        ErrorWidget.builder = previousBuilder;
      }
    },
  );

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

FlutterErrorDetails _boomDetails() {
  return FlutterErrorDetails(
    exception: Exception('boom-marker'),
    stack: StackTrace.fromString('#0 gate\n#1 main\n'),
  );
}

void expectBrandedReleaseBranch({
  required bool demoBuild,
  required bool adminTools,
}) {
  final previous = ErrorWidget.builder;
  try {
    expect(
      showDetailedReleaseError(
        debug: false,
        demoBuild: demoBuild,
        adminTools: adminTools,
      ),
      isFalse,
    );
    installReleaseErrorWidget(
      debug: false,
      demoBuild: demoBuild,
      adminTools: adminTools,
    );
    expect(ErrorWidget.builder, same(productionReleaseErrorWidget));
    final widget = ErrorWidget.builder(_boomDetails());
    expect(widget, isA<BrandedReleaseErrorScreen>());
    expect(widget, isNot(isA<ErrorWidget>()));
  } finally {
    ErrorWidget.builder = previous;
  }
}

void expectDetailedErrorBranch({
  required bool debug,
  required bool demoBuild,
  required bool adminTools,
}) {
  final previous = ErrorWidget.builder;
  try {
    expect(
      showDetailedReleaseError(
        debug: debug,
        demoBuild: demoBuild,
        adminTools: adminTools,
      ),
      isTrue,
    );
    installReleaseErrorWidget(
      debug: debug,
      demoBuild: demoBuild,
      adminTools: adminTools,
    );
    expect(ErrorWidget.builder, same(releaseErrorWidget));
    final widget = ErrorWidget.builder(_boomDetails());
    expect(widget, isA<ErrorWidget>());
    final message = (widget as ErrorWidget).message;
    expect(message, contains('boom-marker'));
    expect(message, contains('#0 gate'));
    expect(message, isNot(contains('See also:')));
    expect(message, isNot(contains(BrandedReleaseErrorScreen.message)));
  } finally {
    ErrorWidget.builder = previous;
  }
}

class _Store implements PolicyAcceptanceStore {
  @override
  Future<PolicyAcceptance?> read() async => null;

  @override
  Future<void> write(PolicyAcceptance acceptance) async {}
}
