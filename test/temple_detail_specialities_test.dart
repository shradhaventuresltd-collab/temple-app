import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';

Temple _templeWithLongestSpeciality() {
  var best = sampleTemples.first;
  var bestLength = 0;
  for (final temple in sampleTemples) {
    for (final item in temple.specialities) {
      if (item.length > bestLength) {
        best = temple;
        bestLength = item.length;
      }
    }
  }
  return best;
}

String _longestSpeciality(Temple temple) {
  return temple.specialities.reduce((a, b) => a.length >= b.length ? a : b);
}

Temple _bhadrakaliWarangal() {
  return sampleTemples.firstWhere(
    (temple) => temple.name == 'Bhadrakali Temple' && temple.city == 'Warangal',
  );
}

int _paintedLineCount(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Temple temple,
  required double textScale,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: Scaffold(body: TempleDetailBody(temple: temple)),
    ),
  );
  await tester.pump();
}

void _expectSpecialityFullyRendered(WidgetTester tester, String spec) {
  expect(find.text(spec), findsOneWidget);

  final text = tester.widget<Text>(find.text(spec));
  expect(text.maxLines, isNull);
  expect(text.softWrap, isTrue);
  expect(text.overflow, TextOverflow.visible);
  expect(text.data, spec);

  expect(
    find.ancestor(of: find.text(spec), matching: find.byType(Chip)),
    findsNothing,
  );

  final paragraph = tester.renderObject<RenderParagraph>(find.text(spec));
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.text.toPlainText(), spec);

  final rect = tester.getRect(find.text(spec));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(360));

  final row = find
      .ancestor(of: find.text(spec), matching: find.byType(Row))
      .first;
  final icon = tester.getRect(
    find.descendant(of: row, matching: find.byIcon(Icons.auto_awesome_rounded)),
  );
  // The sparkle stays on the first line instead of centering on a tall pill.
  expect((icon.top - rect.top).abs(), lessThan(8));

  final pill = tester.getRect(
    find.ancestor(of: find.text(spec), matching: find.byType(Container)).first,
  );
  // Page padding is 20 on each side of a 360dp-wide screen.
  expect(pill.width, closeTo(320, 1));
  expect(pill.left, greaterThanOrEqualTo(0));
  expect(pill.right, lessThanOrEqualTo(360));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test(
    'seed data longest speciality is the Kashi Vishwanath gold-plating line',
    () {
      final temple = _templeWithLongestSpeciality();
      expect(temple.name, 'Kashi Vishwanath Temple');
      expect(temple.city, 'Varanasi');
      expect(
        _longestSpeciality(temple),
        'Ahilyabai Holkar rebuild (1780); gold plating associated with Maharaja '
        'Ranjit Singh (1835)',
      );
    },
  );

  for (final textScale in const [1.0, 1.3, 2.0]) {
    testWidgets(
      'longest specialities wrap at 360dp with text scale $textScale',
      (tester) async {
        final temple = _templeWithLongestSpeciality();
        await _pumpDetail(tester, temple: temple, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.text('Specialities'), findsOneWidget);

        final longest = _longestSpeciality(temple);
        for (final spec in temple.specialities) {
          _expectSpecialityFullyRendered(tester, spec);
        }
        expect(_paintedLineCount(tester, longest), greaterThan(1));
      },
    );

    testWidgets(
      'Bhadrakali Warangal specialities wrap at 360dp with text scale $textScale',
      (tester) async {
        final temple = _bhadrakaliWarangal();
        await _pumpDetail(tester, temple: temple, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(find.text('Specialities'), findsOneWidget);

        const reported = [
          'Traditional Chalukya-era founding association (~7th century)',
          'Kakatiya regional guardian-goddess heritage',
        ];
        for (final spec in temple.specialities) {
          _expectSpecialityFullyRendered(tester, spec);
        }
        for (final spec in reported) {
          expect(temple.specialities, contains(spec));
          expect(find.text(spec), findsOneWidget);
          expect(_paintedLineCount(tester, spec), greaterThan(1));
        }
      },
    );
  }
}
