import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/widgets/app_drawer.dart';
import 'package:temple_app/widgets/directory_filter_bar.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// Spaces let the line break. Repeated so two lines are not enough at 360dp.
const _overflowName = 'Sri Kalahasti Swamy Temple of the Sacred Hill ';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('browse card wraps a long name to two lines at 360dp', (
    tester,
  ) async {
    await _pump360(
      tester,
      TempleBrowseCard(temple: _temple(_overflowName * 4)),
    );
    _expectTwoLineEllipsis(tester, find.byKey(const Key('browse-temple-name')));
  });

  testWidgets('detail name wraps to two lines at 360dp', (tester) async {
    await _pump360(
      tester,
      TempleDetailBody(temple: _temple(_overflowName * 4)),
    );
    _expectTwoLineEllipsis(tester, find.byKey(const Key('detail-temple-name')));
  });

  testWidgets('list app bar wraps a long title without clipping at 360dp', (
    tester,
  ) async {
    await _pump360(
      tester,
      TempleListScreen(
        temples: [_temple('Meenakshi')],
        title: _overflowName * 4,
      ),
    );
    final title = find.byKey(const Key('temple-list-title'));
    _expectTwoLineEllipsis(tester, title);
    final titleRect = tester.getRect(title);
    final bar = tester.getRect(find.byType(AppBar));
    expect(bar.top, lessThanOrEqualTo(titleRect.top));
    expect(
      bar.bottom,
      greaterThanOrEqualTo(titleRect.bottom),
      reason: 'the toolbar must be tall enough for both lines',
    );
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight,
      greaterThan(kToolbarHeight),
    );
  });

  for (final textScale in const [1.0, 1.3]) {
    testWidgets(
      'names, places, and deity chips fit at 360dp text scale $textScale',
      (tester) async {
        final temple = _narrowTemple();
        await _pump360(
          tester,
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [TempleBrowseCard(temple: temple, onTap: () {})],
          ),
          textScale: textScale,
        );

        _expectShown(
          tester,
          find.byKey(const Key('browse-temple-name')),
          temple.name,
        );
        _expectShown(
          tester,
          find.byKey(const Key('browse-temple-place')),
          'Tirupati, Andhra Pradesh',
        );
        _expectShown(tester, find.text(temple.deity), temple.deity);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('browse-temple-name')))
              .maxLines,
          2,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('browse-temple-place')))
              .maxLines,
          2,
        );
        expect(
          tester.widget<Text>(find.text(temple.deity)).overflow,
          isNot(TextOverflow.ellipsis),
        );
        expect(tester.takeException(), isNull);

        await _pump360(
          tester,
          TempleDetailBody(temple: temple),
          textScale: textScale,
        );
        _expectShown(
          tester,
          find.byKey(const Key('detail-temple-name')),
          temple.name,
        );
        _expectShown(
          tester,
          find.byKey(const Key('detail-temple-place')),
          'Tirupati, Andhra Pradesh',
        );
        _expectShown(
          tester,
          find.text('Listed focus: ${temple.deity}'),
          'Listed focus: ${temple.deity}',
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('detail-temple-name')))
              .maxLines,
          2,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('detail-temple-place')))
              .maxLines,
          2,
        );
        expect(tester.takeException(), isNull);

        final deityLabel = directoryDeityChipLabel(temple.deity);
        await _pump360(
          tester,
          DirectoryFilterBar(
            temples: [temple],
            selectedState: 'Andhra Pradesh',
            selectedDeity: temple.deity,
            onChanged: (_, _, _) {},
          ),
          textScale: textScale,
        );
        _expectShown(tester, find.text(deityLabel), deityLabel);
        _expectShown(tester, find.text('Andhra Pradesh'), 'Andhra Pradesh');
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Temple _temple(String name) {
  return Temple(
    name: name,
    state: 'Andhra Pradesh',
    city: 'Srikalahasti',
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: 'Srikalahasti, Andhra Pradesh',
    timings: '',
    specialities: const [],
    latitude: 13.75,
    longitude: 79.70,
  );
}

Temple _narrowTemple() {
  return Temple(
    name: 'Abirami (Parvati)',
    state: 'Andhra Pradesh',
    city: 'Tirupati',
    deity: 'Sri Ramakrishna (Ramakrishna–Vedanta tradition)',
    imageUrl: '',
    description: 'A hill shrine.',
    story: 'Story',
    location: 'Tirupati, Andhra Pradesh',
    timings: '6am–9pm',
    specialities: const ['A long speciality that stays off this check'],
    latitude: 13.65,
    longitude: 79.42,
  );
}

Future<void> _pump360(
  WidgetTester tester,
  Widget home, {
  double textScale = 1,
}) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
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
      home: Scaffold(body: home),
    ),
  );
}

void _expectShown(WidgetTester tester, Finder finder, String full) {
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.data ?? text.textSpan?.toPlainText(), full);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.text.toPlainText(), full);
  final maxWidth = paragraph.constraints.maxWidth;
  expect(maxWidth.isFinite, isTrue);
  expect(paragraph.size.width, lessThanOrEqualTo(maxWidth + 1));
  final rect = tester.getRect(finder);
  expect(rect.width, lessThanOrEqualTo(360.1));
}

void _expectTwoLineEllipsis(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  expect(text.maxLines, 2);
  expect(text.overflow, TextOverflow.ellipsis);
  expect(text.softWrap, isTrue);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isTrue);
  expect(_lineCount(paragraph), 2);
  expect(tester.takeException(), isNull);
}

int _lineCount(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}
