// KAN-197 AC1: absent, verified and unverified dress-code card states.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('absent dressCode: no card', (t) async {
    await pumpDetail(t, noDressTemple());
    expect(find.byKey(kDressSection), findsNothing);
    expect(find.text('Dress code'), findsNothing);
    expect(find.byKey(kDressChip), findsNothing);
  });

  testWidgets('empty or blank dressCode: no card, even when unverified', (
    t,
  ) async {
    for (final v in ['', '   ', '\n\t']) {
      await pumpDetail(t, dressTemple(dressCode: v));
      expect(find.byKey(kDressSection), findsNothing, reason: '"$v"');
      expect(find.byKey(kDressChip), findsNothing, reason: '"$v"');
    }
  });

  testWidgets('wrong-typed dressCode: no card', (t) async {
    await pumpDetail(t, dressTemple(dressCode: 42));
    expect(find.byKey(kDressSection), findsNothing);
  });

  testWidgets('verified: card, text, source footer, no caution block', (
    t,
  ) async {
    await pumpDetail(t, dressTemple(verified: true, type: 'official'));
    await t.ensureVisible(find.byKey(kDressSection));
    expect(find.byKey(kDressHeading), findsOneWidget);
    expect(find.text('Dress code'), findsOneWidget);
    expect(find.text(kDressRule), findsOneWidget);
    expect(find.text('Source: temple website'), findsOneWidget);
    expect(find.byKey(kDressChip), findsNothing);
    expect(find.byKey(kDressLink), findsNothing);
    expect(find.text(UnverifiedSourceNotice.title), findsNothing);
  });

  testWidgets('missing verified flag reads as verified', (t) async {
    await pumpDetail(t, dressTemple(verified: null));
    expect(find.byKey(kDressSection), findsOneWidget);
    expect(find.byKey(kDressChip), findsNothing);
  });

  testWidgets('unverified: card with the caution block and the link', (
    t,
  ) async {
    await pumpDetail(t, dressTemple());
    await t.ensureVisible(find.byKey(kDressSection));
    expect(
      find.descendant(
        of: find.byKey(kDressSection),
        matching: find.byKey(kDressChip),
      ),
      findsOneWidget,
    );
    expect(find.text(UnverifiedSourceNotice.title), findsOneWidget);
    expect(find.text('Rules may have changed. '), findsOneWidget);
    expect(find.byKey(kDressLink), findsOneWidget);
    expect(find.text('View source'), findsOneWidget);
    expect(find.text(kDressRule), findsOneWidget);
    expect(find.text('Source: secondary source'), findsOneWidget);
    // Notice sits between the title and the body (mockup 06).
    final title = t.getTopLeft(find.byKey(kDressHeading)).dy;
    final chip = t.getTopLeft(find.byKey(kDressChip)).dy;
    final body = t.getTopLeft(find.byKey(kDressBody)).dy;
    expect(title < chip && chip < body, isTrue);
  });

  testWidgets('source footer: official, secondary, none, unknown', (t) async {
    const cases = {
      'official': 'Source: temple website',
      'secondary': 'Source: secondary source',
    };
    for (final e in cases.entries) {
      await pumpDetail(t, dressTemple(type: e.key));
      expect(find.text(e.value), findsOneWidget, reason: e.key);
    }
    for (final v in [null, 'Official', 'blog']) {
      await pumpDetail(t, dressTemple(type: v));
      expect(find.byKey(kDressSource), findsNothing, reason: '$v');
    }
  });

  testWidgets('card sits directly after the timings card', (t) async {
    await pumpDetail(t, dressTemple());
    final timings = t.getBottomLeft(
      find.byKey(const Key('detail-timings-body')),
    );
    final dress = t.getTopLeft(find.byKey(kDressSection));
    final coords = t.getTopLeft(find.text('Coordinates'));
    expect(dress.dy, greaterThan(timings.dy));
    expect(dress.dy, lessThan(coords.dy));
  });

  testWidgets('card tokens: surface, radius 16, 1px divider border', (t) async {
    await pumpDetail(t, dressTemple());
    final box =
        t.widget<Container>(find.byKey(kDressSection)).decoration!
            as BoxDecoration;
    expect(box.color, DetailUxTokens.light.surface);
    expect(box.borderRadius, BorderRadius.circular(16));
    expect((box.border! as Border).top.color, DetailUxTokens.light.divider);
    expect((box.border! as Border).top.width, 1);
    final title = t.widget<Text>(find.byKey(kDressHeading));
    expect(title.style!.fontSize, 17);
    expect(title.style!.fontWeight, FontWeight.w700);
    final body = t.widget<Text>(find.byKey(kDressBody));
    expect(body.style!.fontSize, 14);
    expect(body.style!.fontWeight, FontWeight.w500);
    expect(body.style!.height, 1.5);
    final footer = t.widget<Text>(find.byKey(kDressSource));
    expect(footer.style!.fontSize, 11.5);
    expect(footer.style!.color, DetailUxTokens.light.muted);
  });

  testWidgets('long text: 6 lines, Show more, Show less', (t) async {
    final long = List.filled(60, 'Wear modest clothing.').join(' ');
    await pumpDetail(t, dressTemple(dressCode: long));
    await t.ensureVisible(find.byKey(kDressMore));
    expect(t.widget<Text>(find.byKey(kDressBody)).maxLines, 6);
    expect(find.text('Show more'), findsOneWidget);
    expect(t.getSize(find.byKey(kDressMore)).height, greaterThanOrEqualTo(48));
    await t.tap(find.byKey(kDressMore));
    await t.pump();
    expect(t.widget<Text>(find.byKey(kDressBody)).maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
    await t.ensureVisible(find.byKey(kDressMore));
    await t.tap(find.byKey(kDressMore));
    await t.pump();
    expect(t.widget<Text>(find.byKey(kDressBody)).maxLines, 6);
  });

  testWidgets('short text: no Show more', (t) async {
    await pumpDetail(t, dressTemple());
    expect(find.byKey(kDressMore), findsNothing);
    expect(t.widget<Text>(find.byKey(kDressBody)).maxLines, isNull);
  });

  testWidgets('semantics ids on card and notice', (t) async {
    final h = t.ensureSemantics();
    await pumpDetail(t, dressTemple());
    expect(find.bySemanticsIdentifier('detail-dress-code'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('dress-code-unverified-chip'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Dress code unverified. Check before visiting. '
        'View source, opens browser.',
      ),
      findsOneWidget,
    );
    expect(
      t.getSemantics(find.bySemanticsIdentifier('dress-code-source-link')),
      isSemantics(
        identifier: 'dress-code-source-link',
        label: 'View source, opens browser',
        isButton: true,
        isLink: true,
        hasTapAction: true,
      ),
    );
    h.dispose();
  });
}
