// KAN-197 AC5: 200% font, the notice wraps with no clipping and the link
// tap target is at least 48dp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpLarge(WidgetTester t, Temple temple, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(2),
          ),
          child: Scaffold(body: TempleDetailBody(temple: temple)),
        ),
      ),
    );
    await t.pump();
  }

  for (final size in [const Size(360, 800), const Size(320, 640)]) {
    testWidgets('200% at ${size.width.toInt()}dp: no overflow, 48dp link', (
      t,
    ) async {
      await pumpLarge(t, dressTemple(timingsUnverified: true), size);
      await t.ensureVisible(find.byKey(kDressChip));
      await t.pump();
      expect(t.takeException(), isNull);
      final chip = t.getRect(find.byKey(kDressChip));
      final card = t.getRect(find.byKey(kDressSection));
      expect(chip.right, lessThanOrEqualTo(card.right));
      expect(chip.left, greaterThanOrEqualTo(card.left));
      final link = t.getRect(find.byKey(kDressLink));
      expect(link.height, greaterThanOrEqualTo(48));
      expect(link.width, greaterThanOrEqualTo(48));
      expect(link.right, lessThanOrEqualTo(chip.right));
      expect(link.bottom, lessThanOrEqualTo(chip.bottom));
      final title = t.getRect(
        find.descendant(
          of: find.byKey(kDressChip),
          matching: find.text('Unverified, check before visiting'),
        ),
      );
      expect(title.right, lessThanOrEqualTo(chip.right));
      // Wrapped onto more than one line at 200%.
      expect(title.height, greaterThan(13 * 2 * 1.4 + 1));
    });
  }

  testWidgets('200%: no-link notice and long body do not overflow', (t) async {
    await pumpLarge(
      t,
      dressTemple(
        url: null,
        dressCode: List.filled(30, 'Wear modest clothing.').join(' '),
      ),
      const Size(360, 800),
    );
    await t.ensureVisible(find.byKey(kDressMore));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('Show more'), findsOneWidget);
    expect(t.getSize(find.byKey(kDressMore)).height, greaterThanOrEqualTo(48));
  });

  testWidgets('200%: tapping the link launches', (t) async {
    final l = installLauncher(FakeLauncher());
    await pumpLarge(t, dressTemple(), const Size(360, 800));
    await t.ensureVisible(find.byKey(kDressLink));
    await t.tap(find.byKey(kDressLink));
    await t.pumpAndSettle();
    expect(l.launches, 1);
  });
}
