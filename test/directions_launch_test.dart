import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const _unavailable = "Couldn't open directions on this device.";

Temple _temple() {
  return const Temple(
    name: 'Draft Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Shiva',
    imageUrl: '',
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Temple Street',
    timings: '6:00 AM–8:00 PM daily.',
    specialities: ['Stone gateway'],
    latitude: 9.9,
    longitude: 78.1,
  );
}

class _FakeUrlLauncher extends UrlLauncherPlatform {
  _FakeUrlLauncher({
    required this.canOpen,
    this.launchResult = true,
    this.throwOnLaunch = false,
  });

  final bool canOpen;
  final bool launchResult;
  final bool throwOnLaunch;
  String? launchedUrl;
  PreferredLaunchMode? launchMode;
  int canLaunchCount = 0;

  @override
  Future<bool> canLaunch(String url) async {
    canLaunchCount++;
    return canOpen;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    launchMode = options.mode;
    if (throwOnLaunch) {
      throw Exception('launch failed');
    }
    return launchResult;
  }
}

void main() {
  late UrlLauncherPlatform original;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    original = UrlLauncherPlatform.instance;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = original;
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _temple())),
      ),
    );
    await tester.pump();
  }

  Future<void> tapDirections(WidgetTester tester) async {
    final button = find.byKey(const Key('get-directions-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows a snackbar when no app can open the maps link', (
    tester,
  ) async {
    final launcher = _FakeUrlLauncher(canOpen: false);
    UrlLauncherPlatform.instance = launcher;

    await pumpDetail(tester);
    await tapDirections(tester);

    expect(find.text(_unavailable), findsOneWidget);
    expect(launcher.canLaunchCount, 1);
    expect(launcher.launchedUrl, isNull);
  });

  testWidgets('shows a snackbar when the maps launch returns false', (
    tester,
  ) async {
    final launcher = _FakeUrlLauncher(canOpen: true, launchResult: false);
    UrlLauncherPlatform.instance = launcher;

    await pumpDetail(tester);
    await tapDirections(tester);

    expect(find.text(_unavailable), findsOneWidget);
    expect(
      launcher.launchedUrl,
      'https://www.google.com/maps/search/?api=1&query=9.9,78.1',
    );
    expect(launcher.launchMode, PreferredLaunchMode.externalApplication);
  });

  testWidgets('shows a snackbar when the maps launch throws', (tester) async {
    final launcher = _FakeUrlLauncher(canOpen: true, throwOnLaunch: true);
    UrlLauncherPlatform.instance = launcher;

    await pumpDetail(tester);
    await tapDirections(tester);

    expect(find.text(_unavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the existing https maps link without a snackbar', (
    tester,
  ) async {
    final launcher = _FakeUrlLauncher(canOpen: true);
    UrlLauncherPlatform.instance = launcher;

    await pumpDetail(tester);
    await tapDirections(tester);

    expect(find.text(_unavailable), findsNothing);
    expect(
      launcher.launchedUrl,
      'https://www.google.com/maps/search/?api=1&query=9.9,78.1',
    );
    expect(launcher.launchMode, PreferredLaunchMode.externalApplication);
  });
}
