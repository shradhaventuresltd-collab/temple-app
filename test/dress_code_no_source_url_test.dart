// KAN-197 AC4: a missing or non-http source URL shows "Confirm with the
// temple" and no link.
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const bad = <Object?>[
    null,
    '',
    '   ',
    'not a url',
    'javascript:alert(1)',
    'ftp://x.org/dress',
    'mailto:a@b.c',
    'file:///etc/hosts',
    'intent://x#Intent;end',
    'https://',
    '//x.org/dress',
    42,
  ];

  for (final url in bad) {
    testWidgets('url=$url: Confirm with the temple, no link', (t) async {
      final l = installLauncher(FakeLauncher());
      await pumpDetail(t, dressTemple(url: url));
      expect(find.byKey(kDressChip), findsOneWidget);
      expect(find.byKey(kDressLink), findsNothing);
      expect(find.text('View source'), findsNothing);
      expect(find.text('Confirm with the temple.'), findsOneWidget);
      await t.ensureVisible(find.byKey(kDressChip));
      await t.tap(find.text('Confirm with the temple.'));
      await t.pumpAndSettle();
      expect(l.launches, 0);
    });
  }

  testWidgets('no-link semantics label', (t) async {
    final h = t.ensureSemantics();
    await pumpDetail(t, dressTemple(url: null));
    expect(
      find.bySemanticsLabel(
        'Dress code unverified. Check before visiting. '
        'Confirm with the temple.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('dress-code-source-link'), findsNothing);
    h.dispose();
  });

  testWidgets('http and https both link', (t) async {
    for (final u in ['http://x.org', '  https://x.org/a  ']) {
      await pumpDetail(t, dressTemple(url: u));
      expect(find.byKey(kDressLink), findsOneWidget, reason: u);
    }
  });

  testWidgets('verified with no url: no notice at all', (t) async {
    await pumpDetail(t, dressTemple(url: null, verified: true));
    expect(find.byKey(kDressSection), findsOneWidget);
    expect(find.byKey(kDressChip), findsNothing);
    expect(find.text('Confirm with the temple.'), findsNothing);
  });
}
