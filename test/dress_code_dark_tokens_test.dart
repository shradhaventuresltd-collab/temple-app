// KAN-197 AC6: a dark ThemeData uses the dark caution and card tokens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/widgets/unverified_source_notice.dart';

import 'helpers/dress_code_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('token values match SPEC.md section 6', () {
    const l = DetailUxTokens.light;
    const d = DetailUxTokens.dark;
    expect(l.cautionBg, const Color(0xFFFFF4DC));
    expect(l.cautionBorder, const Color(0xFFF2B544));
    expect(l.cautionIcon, const Color(0xFFB26A00));
    expect(l.accent, const Color(0xFFB23C00));
    expect(d.cautionBg, const Color(0xFF3A2A0E));
    expect(d.cautionBorder, const Color(0xFFFFCA6B));
    expect(d.cautionIcon, const Color(0xFFFFCA6B));
    expect(d.accent, const Color(0xFFFFB74D));
    expect(d.surface, const Color(0xFF2B1F1B));
    expect(d.divider, const Color(0xFF3A2A24));
    expect(d.text, const Color(0xFFF6EADB));
    expect(d.muted, const Color(0xFFA99079));
  });

  test('link and text contrast is at least 4.5:1 in both themes', () {
    for (final tk in [DetailUxTokens.light, DetailUxTokens.dark]) {
      expect(_contrast(tk.accent, tk.cautionBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(tk.text, tk.cautionBg), greaterThanOrEqualTo(4.5));
      expect(_contrast(tk.accent, tk.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(tk.text, tk.surface), greaterThanOrEqualTo(4.5));
      expect(_contrast(tk.muted, tk.surface), greaterThanOrEqualTo(4.5));
    }
    expect(
      _contrast(DetailUxTokens.light.accent, DetailUxTokens.light.cautionBg),
      closeTo(5.43, 0.01),
    );
  });

  testWidgets('light link is #B23C00 and underlined', (t) async {
    await pumpDetail(t, dressTemple(timingsUnverified: true));
    for (final key in [kDressChip, kTimingsChip]) {
      final link = t.widget<Text>(
        find.descendant(
          of: find.byKey(key),
          matching: find.text('View source'),
        ),
      );
      expect(link.style!.color, const Color(0xFFB23C00), reason: '$key');
      expect(link.style!.decoration, TextDecoration.underline);
      expect(link.style!.decorationColor, const Color(0xFFB23C00));
    }
  });

  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    testWidgets('$name theme picks $name tokens', (t) async {
      final tokens = dark ? DetailUxTokens.dark : DetailUxTokens.light;
      await pumpDetail(
        t,
        dressTemple(timingsUnverified: true),
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          useMaterial3: true,
        ),
      );
      for (final key in [kDressChip, kTimingsChip]) {
        final box = decorationUnder(t, find.byKey(key));
        expect(box.color, tokens.cautionBg, reason: '$name $key');
        expect((box.border! as Border).top.color, tokens.cautionBorder);
        final icon = t.widget<Icon>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byIcon(Icons.warning_amber_rounded),
          ),
        );
        expect(icon.color, tokens.cautionIcon);
        final link = t.widget<Text>(
          find.descendant(
            of: find.byKey(key),
            matching: find.text('View source'),
          ),
        );
        expect(link.style!.color, tokens.accent);
        final title = t.widget<Text>(
          find.descendant(
            of: find.byKey(key),
            matching: find.text(UnverifiedSourceNotice.title),
          ),
        );
        expect(title.style!.color, tokens.text);
      }
      final card =
          t.widget<Container>(find.byKey(kDressSection)).decoration!
              as BoxDecoration;
      expect(card.color, tokens.surface);
      expect((card.border! as Border).top.color, tokens.divider);
      expect(t.widget<Text>(find.byKey(kDressBody)).style!.color, tokens.text);
      expect(
        t.widget<DefaultTextStyle>(find.byKey(kDressSource)).style.color,
        tokens.muted,
      );
    });
  }

  testWidgets('dark golden', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                UnverifiedSourceNotice(
                  id: 'dress-code',
                  subject: 'Dress code',
                  lead: 'Rules may have changed.',
                  noLinkText: 'Confirm with the place.',
                  sourceUri: Uri.parse('https://x.org'),
                ),
                const SizedBox(height: 8),
                const UnverifiedSourceNotice(
                  id: 'dress-code-b',
                  subject: 'Dress code',
                  lead: 'Rules may have changed.',
                  noLinkText: 'Confirm with the place.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dress_code_unverified_dark.png'),
    );
  });

  testWidgets('light golden', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                UnverifiedSourceNotice(
                  id: 'dress-code',
                  subject: 'Dress code',
                  lead: 'Rules may have changed.',
                  noLinkText: 'Confirm with the place.',
                  sourceUri: Uri.parse('https://x.org'),
                ),
                const SizedBox(height: 8),
                const UnverifiedSourceNotice(
                  id: 'dress-code-b',
                  subject: 'Dress code',
                  lead: 'Rules may have changed.',
                  noLinkText: 'Confirm with the place.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dress_code_unverified_light.png'),
    );
  });
}

/// WCAG 2.x contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
