// KAN-203 §2.5 dress-code source footer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/utils/place_sources.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'helpers/dress_code_fixtures.dart';

const kWiki = 'https://en.wikipedia.org/wiki/Shore_Temple';
const kOsm = 'https://www.openstreetmap.org/?mlat=12.6';
const kNic = 'https://kurukshetra.gov.in/temple';
const kExtra = 'https://example.net/notes';

String joinUrls(List<String> urls) => urls.join(' ');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('0 sources: Compiled from public sources, not tappable', (
    t,
  ) async {
    await pumpDetail(t, dressTemple(url: null, type: null));
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.text(compiledFromPublicSources), findsOneWidget);
    expect(
      find.byKey(const Key('detail-dress-code-source-link-0')),
      findsNothing,
    );
    final ink = find.descendant(
      of: find.byKey(kDressSource),
      matching: find.byType(InkWell),
    );
    expect(ink, findsNothing);
  });

  testWidgets('1 source: Source: <site>, tap opens the URL', (t) async {
    final launcher = installLauncher(FakeLauncher());
    await pumpDetail(
      t,
      dressTemple(url: kWiki, type: 'secondary', verified: true),
    );
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.textContaining('Source:'), findsWidgets);
    expect(find.text('en.wikipedia.org'), findsOneWidget);
    await t.tap(find.byKey(const Key('detail-dress-code-source-link-0')));
    await t.pump();
    expect(launcher.urls, [kWiki]);
    expect(launcher.mode, PreferredLaunchMode.externalApplication);
  });

  testWidgets('2 sources: each name opens its own URL', (t) async {
    final launcher = installLauncher(FakeLauncher());
    await pumpDetail(
      t,
      dressTemple(url: joinUrls([kWiki, kOsm]), type: 'secondary'),
    );
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.textContaining('Sources:'), findsWidgets);
    expect(find.text('en.wikipedia.org'), findsOneWidget);
    expect(find.text('openstreetmap.org'), findsOneWidget);
    expect(
      find.byKey(const Key('detail-dress-code-source-more')),
      findsNothing,
    );
    await t.tap(find.text('en.wikipedia.org'));
    await t.pump();
    await t.tap(find.text('openstreetmap.org'));
    await t.pump();
    expect(launcher.urls, [kWiki, kOsm]);
  });

  testWidgets('3 sources: three names, no +N more', (t) async {
    final launcher = installLauncher(FakeLauncher());
    await pumpDetail(
      t,
      dressTemple(url: joinUrls([kWiki, kOsm, kNic]), type: 'secondary'),
    );
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.text('en.wikipedia.org'), findsOneWidget);
    expect(find.text('openstreetmap.org'), findsOneWidget);
    expect(find.text('kurukshetra.gov.in'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    await t.tap(find.text('kurukshetra.gov.in'));
    await t.pump();
    expect(launcher.urls, [kNic]);
  });

  testWidgets('4+ sources: +N more opens the remaining list', (t) async {
    final launcher = installLauncher(FakeLauncher());
    await pumpDetail(
      t,
      dressTemple(
        url: joinUrls([kWiki, kOsm, kNic, kExtra]),
        type: 'secondary',
      ),
    );
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.text('en.wikipedia.org'), findsOneWidget);
    expect(find.text('openstreetmap.org'), findsOneWidget);
    expect(find.text('kurukshetra.gov.in'), findsOneWidget);
    expect(find.text('+1 more'), findsOneWidget);
    expect(find.text('example.net'), findsNothing);
    await t.tap(find.byKey(const Key('detail-dress-code-source-more')));
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('detail-dress-code-source-sheet')),
      findsOneWidget,
    );
    expect(find.text('example.net'), findsWidgets);
    await t.tap(find.byKey(const Key('detail-dress-code-source-sheet-3')));
    await t.pumpAndSettle();
    expect(launcher.urls, [kExtra]);
  });

  testWidgets('official + URL may use Official temple website', (t) async {
    await pumpDetail(t, dressTemple(url: kWiki, type: 'official'));
    await t.ensureVisible(find.byKey(kDressSource));
    expect(find.text('Official temple website'), findsOneWidget);
    expect(find.text('Source: temple website'), findsNothing);
    expect(find.text('Source: secondary source'), findsNothing);
  });

  testWidgets('generic temple website / secondary source never appear', (
    t,
  ) async {
    for (final type in ['official', 'secondary', null, 'blog']) {
      await pumpDetail(t, dressTemple(url: kWiki, type: type));
      expect(
        find.text('Source: temple website'),
        findsNothing,
        reason: '$type',
      );
      expect(
        find.text('Source: secondary source'),
        findsNothing,
        reason: '$type',
      );
    }
  });

  testWidgets('failed launch shows Couldn\'t open the source link.', (t) async {
    installLauncher(FakeLauncher(result: false));
    await pumpDetail(t, dressTemple(url: kWiki, type: 'secondary'));
    await t.ensureVisible(find.byKey(kDressSource));
    await t.tap(find.byKey(const Key('detail-dress-code-source-link-0')));
    await t.pump();
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsOneWidget);
  });

  testWidgets('thrown launch shows the same snackbar', (t) async {
    installLauncher(ThrowingLauncher());
    await pumpDetail(t, dressTemple(url: kWiki, type: 'secondary'));
    await t.ensureVisible(find.byKey(kDressSource));
    await t.tap(find.byKey(const Key('detail-dress-code-source-link-0')));
    await t.pump();
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsOneWidget);
  });

  testWidgets('ArgumentError from launchUrl shows the same snackbar', (
    t,
  ) async {
    installLauncher(ArgumentErrorLauncher());
    await pumpDetail(t, dressTemple(url: kWiki, type: 'secondary'));
    await t.ensureVisible(find.byKey(kDressSource));
    await t.tap(find.byKey(const Key('detail-dress-code-source-link-0')));
    await t.pump();
    expect(find.text(UnverifiedSourceNotice.launchFailedText), findsOneWidget);
  });

  testWidgets(
    'a secondary source with a URL never shows Official temple website',
    (t) async {
      await pumpDetail(t, dressTemple(url: kWiki, type: 'secondary'));
      await t.ensureVisible(find.byKey(kDressSource));
      expect(find.text('Official temple website'), findsNothing);
      expect(find.textContaining('Source:'), findsWidgets);
      expect(find.text('en.wikipedia.org'), findsOneWidget);
    },
  );

  test('a non-http URL is dropped from the footer sources', () {
    expect(
      parseHttpSourceUrls(
        'javascript:alert(1) ftp://x.org/dress https://en.wikipedia.org/wiki/X',
      ),
      [Uri.parse('https://en.wikipedia.org/wiki/X')],
    );
    final temple = dressTemple(url: 'javascript:alert(1)', type: 'official');
    expect(dressCodeSourcesOf(temple), isEmpty);
    expect(
      placeSourceFooterLayout(dressCodeSourcesOf(temple)).text,
      compiledFromPublicSources,
    );
  });

  testWidgets('long domain at 200% font truncates without overflow', (t) async {
    const long = 'https://very.long.subdomain.chain.example.international/path';
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed') ||
          details.toString().contains('RenderFlex')) {
        fail(details.toString());
      }
      FlutterError.presentError(details);
    };
    await pumpDetail(t, dressTemple(url: long, type: 'secondary'));
    await t.pump();
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pump();
    final link = find.byKey(const Key('detail-dress-code-source-link-0'));
    expect(link, findsOneWidget);
    expect(t.getSize(link).height, greaterThanOrEqualTo(48));
    final launcher = installLauncher(FakeLauncher());
    await t.ensureVisible(link);
    await t.tap(link);
    await t.pump();
    expect(launcher.urls, [long]);
  });

  testWidgets('KAN-197 typography and link colour stay on the tokens', (
    t,
  ) async {
    await pumpDetail(t, dressTemple(url: kWiki, type: 'secondary'));
    final chrome = t.widget<DefaultTextStyle>(find.byKey(kDressSource));
    expect(chrome.style.fontSize, 11.5);
    expect(chrome.style.color, DetailUxTokens.light.muted);
    final name = t.widget<Text>(find.text('en.wikipedia.org'));
    expect(name.style!.color, DetailUxTokens.light.accent);
    expect(name.style!.decoration, TextDecoration.underline);
    expect(
      t
          .getSize(find.byKey(const Key('detail-dress-code-source-link-0')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  test('helper layouts 0 / 1 / 2 / 3 / 4+ from a URI list', () {
    final urls = [
      Uri.parse(kWiki),
      Uri.parse(kOsm),
      Uri.parse(kNic),
      Uri.parse(kExtra),
    ];
    expect(placeSourceFooterLayout(const []).text, compiledFromPublicSources);
    expect(
      placeSourceFooterLayout(placeSourcesFromUrls(urls.take(1))).text,
      'Source: en.wikipedia.org',
    );
    expect(
      placeSourceFooterLayout(placeSourcesFromUrls(urls.take(2))).text,
      'Sources: en.wikipedia.org, openstreetmap.org',
    );
    expect(
      placeSourceFooterLayout(placeSourcesFromUrls(urls.take(3))).moreCount,
      0,
    );
    final four = placeSourceFooterLayout(placeSourcesFromUrls(urls));
    expect(
      four.text,
      'Sources: en.wikipedia.org, openstreetmap.org, kurukshetra.gov.in +1 more',
    );
    expect(four.moreCount, 1);
    expect(four.remaining.single.hostLabel, 'example.net');
  });
}
