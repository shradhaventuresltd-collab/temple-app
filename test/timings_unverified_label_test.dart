import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const _chip = Key('timings-unverified-chip');
const _link = Key('timings-source-link');

Temple _temple({
  bool? verified,
  String? url,
  String? timings = '6:00 AM–8:00 PM daily.',
}) {
  return Temple(
    name: 'Draft Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Shiva',
    imageUrl: '',
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Temple Street',
    timings: timings,
    specialities: const ['Stone gateway'],
    timingsVerified: verified,
    timingsSourceUrl: url,
  );
}

class _FakeLauncher extends UrlLauncherPlatform {
  _FakeLauncher({this.result = true, this.gate});
  final bool result;
  final Completer<void>? gate;
  int launches = 0;
  String? url;
  PreferredLaunchMode? mode;

  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches++;
    this.url = url;
    mode = options.mode;
    if (gate != null) await gate!.future;
    return result;
  }
}

void main() {
  late UrlLauncherPlatform original;
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => original = UrlLauncherPlatform.instance);
  tearDown(() => UrlLauncherPlatform.instance = original);

  Future<void> pump(WidgetTester t, Temple temple, {ThemeData? theme}) async {
    await t.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: TempleDetailBody(temple: temple)),
      ),
    );
    await t.pump();
  }

  group('Temple.fromMap timings verification', () {
    test('parses bool and url', () {
      final t = Temple.fromMap('a', {
        'timingsVerified': false,
        'timingsSourceUrl': 'https://example.org/t',
      });
      expect(t.timingsVerified, isFalse);
      expect(t.timingsUnverified, isTrue);
      expect(t.timingsSourceUri.toString(), 'https://example.org/t');
    });
    test('missing or wrong types are null', () {
      final t = Temple.fromMap('a', {
        'timingsVerified': 'false',
        'timingsSourceUrl': 42,
      });
      expect(t.timingsVerified, isNull);
      expect(t.timingsUnverified, isFalse);
      expect(t.timingsSourceUrl, isNull);
      expect(Temple.fromMap('b', {}).timingsVerified, isNull);
    });
    test('invalid or non-http urls are rejected', () {
      for (final u in [
        '',
        '  ',
        'not a url',
        'ftp://x.org',
        'javascript:alert(1)',
        'mailto:a@b.c',
        'https://',
      ]) {
        expect(_temple(url: u).timingsSourceUri, isNull, reason: u);
      }
      expect(_temple(url: 'http://x.org').timingsSourceUri, isNotNull);
    });
    test('fields are not written back to Firestore', () {
      final data = _temple(
        verified: false,
        url: 'https://x.org',
      ).toFirestoreData();
      expect(data.containsKey('timingsVerified'), isFalse);
      expect(data.containsKey('timingsSourceUrl'), isFalse);
    });
  });

  group('matrix', () {
    for (final verified in [true, false, null]) {
      for (final url in ['https://example.org/src', null]) {
        testWidgets('verified=$verified url=$url', (t) async {
          await pump(t, _temple(verified: verified, url: url));
          final shows = verified == false;
          expect(find.byKey(_chip), shows ? findsOneWidget : findsNothing);
          expect(
            find.text('Unverified, check before visiting'),
            shows ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(_link),
            shows && url != null ? findsOneWidget : findsNothing,
          );
          if (shows && url == null) {
            expect(
              find.text('Timings may have changed. Confirm with the temple.'),
              findsOneWidget,
            );
          }
        });
      }
    }
  });

  testWidgets('invalid url shows no link', (t) async {
    await pump(t, _temple(verified: false, url: 'javascript:alert(1)'));
    expect(find.byKey(_chip), findsOneWidget);
    expect(find.byKey(_link), findsNothing);
  });

  testWidgets('no timings shown hides label', (t) async {
    await pump(
      t,
      _temple(verified: false, url: 'https://x.org', timings: null),
    );
    expect(find.byKey(_chip), findsNothing);
  });

  testWidgets('semantics label', (t) async {
    final h = t.ensureSemantics();
    await pump(t, _temple(verified: false, url: 'https://x.org'));
    expect(
      find.bySemanticsLabel(
        'Timings unverified. Check before visiting. View source, opens browser.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('timings-unverified-chip'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('timings-source-link'), findsOneWidget);
    expect(
      t.getSemantics(find.bySemanticsIdentifier('timings-source-link')),
      isSemantics(
        identifier: 'timings-source-link',
        label: 'View source, opens browser',
        isButton: true,
        isLink: true,
        hasTapAction: true,
      ),
    );
    h.dispose();
  });

  testWidgets('double tap launches once, externally', (t) async {
    final gate = Completer<void>();
    final l = _FakeLauncher(gate: gate);
    UrlLauncherPlatform.instance = l;
    await pump(t, _temple(verified: false, url: 'https://example.org/src'));
    await t.ensureVisible(find.byKey(_link));
    await t.tap(find.byKey(_link));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.byKey(_link));
    await t.pump();
    gate.complete();
    await t.pumpAndSettle();
    expect(l.launches, 1);
    expect(l.url, 'https://example.org/src');
    expect(l.mode, PreferredLaunchMode.externalApplication);
    expect(t.getSize(find.byKey(_link)).height, greaterThanOrEqualTo(48));
  });

  testWidgets('launch failure shows snackbar', (t) async {
    UrlLauncherPlatform.instance = _FakeLauncher(result: false);
    await pump(t, _temple(verified: false, url: 'https://example.org/src'));
    await t.ensureVisible(find.byKey(_link));
    await t.tap(find.byKey(_link));
    await t.pump();
    await t.pump();
    expect(find.text("Couldn't open the source link."), findsOneWidget);
  });

  testWidgets('200% text at 360dp has no overflow', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: TempleDetailBody(
              temple: _temple(verified: false, url: 'https://example.org/src'),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byKey(_chip), findsOneWidget);
  });

  testWidgets('dark theme golden', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TimingsUnverifiedChip(sourceUri: Uri.parse('https://x.org')),
                const SizedBox(height: 8),
                const TimingsUnverifiedChip(),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/timings_unverified_dark.png'),
    );
  });
}
