// KAN-197 AC2: timings and dress code use one shared caution widget; the
// timings notice keeps its copy, ids and behaviour, with the new tokens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('both notices are UnverifiedSourceNotice', (t) async {
    await pumpDetail(t, dressTemple(timingsUnverified: true));
    expect(find.byType(UnverifiedSourceNotice), findsNWidgets(2));
    final ids = t
        .widgetList<UnverifiedSourceNotice>(find.byType(UnverifiedSourceNotice))
        .map((w) => w.id)
        .toList();
    expect(ids, ['timings', 'dress-code']);
    expect(
      find.descendant(
        of: find.byType(TimingsUnverifiedChip),
        matching: find.byType(UnverifiedSourceNotice),
      ),
      findsOneWidget,
    );
  });

  testWidgets('timings copy and ids are unchanged', (t) async {
    final h = t.ensureSemantics();
    await pumpDetail(t, dressTemple(timingsUnverified: true, dressCode: null));
    expect(find.byKey(kTimingsChip), findsOneWidget);
    expect(find.byKey(kTimingsLink), findsOneWidget);
    expect(find.text('Timings may have changed. '), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Timings unverified. Check before visiting. '
        'View source, opens browser.',
      ),
      findsOneWidget,
    );
    h.dispose();
  });

  testWidgets('timings without a link keeps its copy', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: TimingsUnverifiedChip())),
    );
    expect(
      find.text('Timings may have changed. Confirm with the place.'),
      findsOneWidget,
    );
  });

  testWidgets('both notices share tokens, icon and title style', (t) async {
    await pumpDetail(t, dressTemple(timingsUnverified: true));
    for (final key in [kTimingsChip, kDressChip]) {
      final box = decorationUnder(t, find.byKey(key));
      expect(box.color, DetailUxTokens.light.cautionBg, reason: '$key');
      expect(
        (box.border! as Border).top.color,
        DetailUxTokens.light.cautionBorder,
      );
      final icon = t.widget<Icon>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byIcon(Icons.warning_amber_rounded),
        ),
      );
      expect(icon.color, DetailUxTokens.light.cautionIcon);
      final title = t.widget<Text>(
        find.descendant(
          of: find.byKey(key),
          matching: find.text(UnverifiedSourceNotice.title),
        ),
      );
      expect(title.style!.fontSize, 13);
      expect(title.style!.fontWeight, FontWeight.w600);
    }
  });

  testWidgets('links open their own source', (t) async {
    final l = installLauncher(FakeLauncher());
    await pumpDetail(t, dressTemple(timingsUnverified: true));
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(kTimingsLink));
    await t.tap(find.byKey(kTimingsLink));
    await t.pumpAndSettle();
    expect(l.urls, [kDressSrc, kTimingsSrc]);
  });
}
