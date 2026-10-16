import 'dart:developer' as developer;
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:temple_app/main.dart' as app;
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/maintenance_screen.dart';
import 'package:temple_app/widgets/home_mosaic_collage.dart';
import 'package:temple_app/widgets/mosaic_tile_placeholder.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';

/// Read-only checks against the release app on prod Firestore.
///
/// The host passes `-e phase`. The Android test runner writes that value
/// before launch. No admin tools, no demo defines, and this file does not write
/// Firestore.
///
/// Janaki caption check 7 runs because Manu's #77 (`80da497`) is in main
/// `63da3fc`. It is not reported N/A.
const _phasePaths = <String>[
  '/data/user/0/com.shradhaventures.temple/files/tester_checks_phase.txt',
  '/data/data/com.shradhaventures.temple/files/tester_checks_phase.txt',
];

const _log = 'TESTER_CHECKS';
const _expectedTemples = 984;

final IntegrationTestWidgetsFlutterBinding _binding =
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

bool _surfaceReady = false;

void main() {
  testWidgets('tester checks', (tester) async {
    final phase = _readPhase();
    _logLine('PHASE $phase');
    try {
      await app.main();
      await tester.pump(const Duration(milliseconds: 300));
      switch (phase) {
        case 'accept':
          await _acceptPhase(tester);
        case 'relaunch-1':
        case 'relaunch-2':
        case 'relaunch-3':
        case 'cold':
          await _homeLaunch(tester, phase);
          if (phase == 'cold') {
            await _uiChecks(tester);
          }
        case 'airplane':
          await _airplanePhase(tester);
        default:
          _result(0, false, 'unknown phase $phase');
      }
    } catch (e, st) {
      _logLine('HARNESS FAIL $phase $e');
      final stack = st.toString().split('\n').take(6).join(' | ');
      _logLine('STACK $stack');
      await _shot(tester, '99-$phase-error');
    }
  });
}

String _readPhase() {
  for (final path in _phasePaths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final text = file.readAsStringSync().trim();
    if (text.isNotEmpty) return text;
  }
  return 'accept';
}

void _logLine(String message) {
  final flat = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  developer.log(flat, name: _log);
}

void _result(int id, bool pass, String note) {
  _logLine('RESULT $id ${pass ? 'PASS' : 'FAIL'} $note');
}

Future<void> _shot(WidgetTester tester, String name) async {
  final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  if (!_surfaceReady) {
    try {
      await _binding.convertFlutterSurfaceToImage();
      _surfaceReady = true;
    } catch (e) {
      _logLine('SURFACE $e');
    }
  }
  await tester.pump(const Duration(milliseconds: 100));
  _logLine('SHOT $safe');
  // The host screencap runs while this frame is still up.
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  if (!_surfaceReady) return;
  try {
    await _binding.takeScreenshot(safe);
    _binding.reportData?.remove('screenshots');
  } catch (e) {
    _logLine('SHOT_ERR $safe $e');
  }
}

Future<bool> _waitUntil(
  WidgetTester tester,
  bool Function() ready, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (ready()) return true;
  }
  return ready();
}

bool _gateVisible(WidgetTester tester) {
  return tester.any(find.byKey(const Key('policy-acceptance-gate'))) ||
      tester.any(find.text('Accept & continue'));
}

bool _maintenanceVisible(WidgetTester tester) {
  return tester.any(find.byKey(const Key('maintenance-screen'))) ||
      tester.any(find.text(MaintenanceScreen.title));
}

bool _firebaseOnScreen(WidgetTester tester) {
  final text = _allText(tester);
  return text.contains('No Firebase App') ||
      text.contains('[core/no-app]') ||
      text.contains('core/no-app') ||
      text.contains('Something went wrong');
}

String _allText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final data = widget.data;
    if (data != null && data.isNotEmpty) {
      buffer.writeln(data);
    }
    final span = widget.textSpan;
    if (span != null) {
      buffer.writeln(span.toPlainText());
    }
  }
  return buffer.toString();
}

String? _browseLabel(WidgetTester tester) {
  final match = RegExp(r'Browse \d+ Temples?');
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final data = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    final found = match.firstMatch(data);
    if (found != null) return found.group(0);
  }
  return null;
}

int? _browseCount(String? label) {
  if (label == null) return null;
  final match = RegExp(r'Browse (\d+) Temples?').firstMatch(label);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

String _screenHint(WidgetTester tester) {
  const needles = <String>[
    'Accept & continue',
    "We'll be back soon",
    'Something went wrong',
    'No Firebase App',
    '[core/no-app]',
    'Could not load temples.',
    'Retry',
    'Photo pending',
    'Loading temples',
    "You're offline",
    'No temples available yet.',
    'Showing the offline sample.',
  ];
  final text = _allText(tester);
  final hits = <String>[
    if (_browseLabel(tester) != null) _browseLabel(tester)!,
    for (final needle in needles)
      if (text.contains(needle)) needle,
  ];
  if (hits.isEmpty) return 'no recognised home text';
  return hits.join('; ');
}

Future<void> _acceptPhase(WidgetTester tester) async {
  final gate = await _waitUntil(
    tester,
    () => _gateVisible(tester) || _browseLabel(tester) != null,
    timeout: const Duration(seconds: 20),
  );
  await _shot(tester, '01-accept-before');
  if (!gate || !_gateVisible(tester)) {
    _result(
      1,
      false,
      'terms gate was not showing; ${_screenHint(tester)}',
    );
    return;
  }

  await tester.tap(find.byKey(const Key('policy-accept-button')));
  await tester.pump(const Duration(milliseconds: 300));
  final left = await _waitUntil(
    tester,
    () => !_gateVisible(tester),
    timeout: const Duration(seconds: 15),
  );
  await _waitUntil(
    tester,
    () =>
        _browseLabel(tester) != null ||
        _firebaseOnScreen(tester) ||
        tester.any(find.text('Could not load temples.')) ||
        tester.any(find.text('Retry')),
    timeout: const Duration(seconds: 40),
  );
  await _shot(tester, '01-accept-after');
  _result(
    1,
    left,
    left
        ? 'one tap left the gate; ${_screenHint(tester)}'
        : 'gate still showing after one tap; ${_screenHint(tester)}',
  );
}

Future<void> _homeLaunch(WidgetTester tester, String phase) async {
  final ready = await _waitUntil(
    tester,
    () =>
        _browseLabel(tester) != null ||
        _gateVisible(tester) ||
        _maintenanceVisible(tester) ||
        _firebaseOnScreen(tester) ||
        tester.any(find.text('Could not load temples.')) ||
        tester.any(find.text('Retry')),
    timeout: const Duration(seconds: 45),
  );
  final label = _browseLabel(tester);
  if (label != null) {
    final button = find.byKey(const Key('home-browse-temples'));
    if (tester.any(button)) {
      await tester.ensureVisible(button);
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  final shotName = phase == 'cold' ? '02-cold-start' : '02-$phase';
  await _shot(tester, shotName);

  final count = _browseCount(label);
  final firebase = _firebaseOnScreen(tester);
  final gate = _gateVisible(tester);
  final maintenance = _maintenanceVisible(tester);
  final pass =
      ready &&
      count == _expectedTemples &&
      !firebase &&
      !gate &&
      !maintenance;
  final note = StringBuffer()
    ..write('n=${count ?? 'missing'}')
    ..write(' label=${label ?? 'none'}')
    ..write(' firebase=${firebase ? 'yes' : 'no'}')
    ..write(' gate=${gate ? 'yes' : 'no'}')
    ..write(' maintenance=${maintenance ? 'yes' : 'no'}')
    ..write(' screen=${_screenHint(tester)}');
  _logLine('LAUNCH $phase ${pass ? 'PASS' : 'FAIL'} $note');
}

Future<void> _uiChecks(WidgetTester tester) async {
  await _mosaicCheck(tester);
  if (!await _openBrowse(tester)) {
    _result(4, false, 'browse did not open; ${_screenHint(tester)}');
    _result(5, false, 'browse did not open');
    _result(7, false, 'browse did not open');
    _result(8, false, 'browse did not open');
    return;
  }
  await _longNameCheck(tester);
  await _searchChecks(tester);
  await _janakiAndDirections(tester);
}

Future<void> _mosaicCheck(WidgetTester tester) async {
  final mosaic = find.byType(HomeMosaicCollage);
  if (tester.any(mosaic)) {
    await tester.ensureVisible(mosaic);
    await tester.pump(const Duration(milliseconds: 200));
  }
  var pending = _pendingInMosaic(tester);
  var photos = _photosInMosaic(tester);
  var loading = _loadingInMosaic(tester);
  if (pending == 0) {
    await tester.pump(const Duration(seconds: 6));
    pending = _pendingInMosaic(tester);
    photos = _photosInMosaic(tester);
    loading = _loadingInMosaic(tester);
  }
  if (tester.any(mosaic)) {
    await tester.ensureVisible(mosaic);
  }
  await _shot(tester, '03-home-mosaic');
  final pass = pending > 0;
  _result(
    3,
    pass,
    'Photo pending tiles=$pending network tiles=$photos '
        'loading placeholders=$loading',
  );
}

int _pendingInMosaic(WidgetTester tester) {
  final mosaic = find.byType(HomeMosaicCollage);
  if (!tester.any(mosaic)) {
    return find.text('Photo pending').evaluate().length;
  }
  return find
      .descendant(of: mosaic, matching: find.text('Photo pending'))
      .evaluate()
      .length;
}

int _photosInMosaic(WidgetTester tester) {
  final mosaic = find.byType(HomeMosaicCollage);
  if (!tester.any(mosaic)) return 0;
  return find
      .descendant(of: mosaic, matching: find.byType(CachedNetworkImage))
      .evaluate()
      .length;
}

int _loadingInMosaic(WidgetTester tester) {
  final mosaic = find.byType(HomeMosaicCollage);
  if (!tester.any(mosaic)) return 0;
  return find
      .descendant(of: mosaic, matching: find.byType(MosaicTilePlaceholder))
      .evaluate()
      .length;
}

Future<bool> _openBrowse(WidgetTester tester) async {
  final button = find.byKey(const Key('home-browse-temples'));
  if (!tester.any(button)) return false;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump(const Duration(seconds: 1));
  return _waitUntil(
    tester,
    () => tester.any(find.byKey(const Key('temple-list-search-field'))),
    timeout: const Duration(seconds: 15),
  );
}

Future<void> _longNameCheck(WidgetTester tester) async {
  var found = _twoLineName(tester);
  if (found == null) {
    for (var i = 0; i < 8 && found == null; i++) {
      final list = find.byType(ListView);
      if (!tester.any(list)) break;
      await tester.drag(list.first, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 250));
      found = _twoLineName(tester);
    }
  }
  if (found == null) {
    const queries = <String>[
      'Mayapur',
      'Janmabhoomi',
      'Kalahasti',
      'Chandrodaya',
      'Ram Mandir',
    ];
    for (final query in queries) {
      await _typeQuery(tester, query);
      found = _twoLineName(tester);
      if (found != null) break;
    }
  }
  if (found == null) {
    await _shot(tester, '04-long-name');
    _result(4, false, 'no browse name wrapped to 2 lines');
    await _typeQuery(tester, '');
    return;
  }
  await tester.ensureVisible(found.finder);
  await _shot(tester, '04-long-name');
  _result(
    4,
    found.lines == 2,
    '"${found.name}" wraps to ${found.lines} lines',
  );
  await _typeQuery(tester, '');
}

int _lineCount(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  if (text.isEmpty) return 0;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

({String name, int lines, Finder finder})? _twoLineName(WidgetTester tester) {
  final names = find.byKey(const Key('browse-temple-name'));
  final count = names.evaluate().length;
  for (var i = 0; i < count; i++) {
    final finder = names.at(i);
    final text = tester.widget<Text>(finder);
    final render = tester.renderObject<RenderParagraph>(finder);
    final lines = _lineCount(render);
    if (lines >= 2) {
      return (
        name: text.data ?? text.textSpan?.toPlainText() ?? '',
        lines: lines,
        finder: finder,
      );
    }
  }
  return null;
}

Future<void> _typeQuery(WidgetTester tester, String query) async {
  final field = find.byKey(const Key('temple-list-search-field'));
  if (!tester.any(field)) {
    _logLine('SEARCH_FIELD missing for "$query"');
    return;
  }
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 200));
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  if (!tester.any(editable)) {
    _logLine('SEARCH_FIELD no editable for "$query"');
    return;
  }
  try {
    await tester.enterText(field, query);
  } catch (e) {
    _logLine('SEARCH_ENTER $e');
  }
  tester
      .state<EditableTextState>(editable)
      .updateEditingValue(
        TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        ),
      );
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _searchChecks(WidgetTester tester) async {
  final named = <(String query, bool Function(String name) matches)>[
    (
      'Minakshi',
      (name) {
        final lower = name.toLowerCase();
        return lower.contains('minakshi') || lower.contains('meenakshi');
      },
    ),
    ('Tirupathi', (name) => name.toLowerCase().contains('tirupati')),
    (
      'Tiruchendur',
      (name) {
        final lower = name.toLowerCase();
        return lower.contains('tiruchendur') ||
            lower.contains('thiruchendur');
      },
    ),
    ('Sivan', (name) => name.toLowerCase().contains('sivan')),
  ];
  final notes = <String>[];
  var namedPass = true;
  for (final row in named) {
    await _typeQuery(tester, row.$1);
    final top = _topTempleName(tester);
    final count = _resultCount(tester);
    final pass = top != null && row.$2(top);
    if (!pass) namedPass = false;
    notes.add('${row.$1} top=${top ?? 'none'} count=${count ?? 'none'}');
    _logLine(
      'SEARCH ${row.$1} ${pass ? 'PASS' : 'FAIL'} '
      'top=${top ?? 'none'} count=${count ?? 'none'}',
    );
    final slug = row.$1.toLowerCase();
    await _shot(tester, '05-search-$slug');
  }

  final counts = <String>[];
  for (final query in const ['ee', 'th', 'it']) {
    await _typeQuery(tester, query);
    final count = _resultCount(tester);
    counts.add('$query=${count ?? 'none'}');
    _logLine('SEARCH $query COUNT ${count ?? 'none'}');
    await _shot(tester, '05-search-$query');
    if (count == null) namedPass = false;
  }
  await _typeQuery(tester, '');
  _result(5, namedPass, '${notes.join('; ')}; ${counts.join(' ')}');
}

String? _topTempleName(WidgetTester tester) {
  final names = find.byKey(const Key('browse-temple-name'));
  if (!tester.any(names)) return null;
  final text = tester.widget<Text>(names.first);
  final value = text.data ?? text.textSpan?.toPlainText();
  if (value == null || value.trim().isEmpty) return null;
  return value.trim();
}

int? _resultCount(WidgetTester tester) {
  final exact = RegExp(r'^(\d+) temples?$');
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    final data = (widget.data ?? widget.textSpan?.toPlainText() ?? '').trim();
    final match = exact.firstMatch(data);
    if (match != null) return int.tryParse(match.group(1)!);
  }
  final text = _allText(tester);
  if (text.contains('No temples match')) return 0;
  return null;
}

Future<void> _janakiAndDirections(WidgetTester tester) async {
  await _typeQuery(tester, 'Sitamarhi');
  var janaki = await _findCard(
    tester,
    (temple) => temple.name == 'Janaki Temple Sitamarhi',
  );
  if (janaki == null) {
    await _typeQuery(tester, 'Janaki');
    janaki = await _findCard(
      tester,
      (temple) =>
          temple.name.toLowerCase().contains('janaki') &&
          (temple.city.toLowerCase().contains('sitamarhi') ||
              temple.name.toLowerCase().contains('sitamarhi')),
    );
  }
  janaki ??= await _findCard(
    tester,
    (temple) => temple.name.toLowerCase().contains('janaki'),
  );
  if (janaki == null) {
    await _shot(tester, '07-janaki-caption');
    _result(7, false, 'Janaki Temple Sitamarhi was not in the loaded list');
    _result(8, false, 'no Janaki card to open');
    return;
  }

  await tester.ensureVisible(janaki.finder);
  await tester.pump(const Duration(milliseconds: 200));
  final onCard = _allText(tester);
  await tester.tap(janaki.finder);
  await tester.pump(const Duration(seconds: 1));
  await _waitUntil(
    tester,
    () =>
        tester.any(find.byKey(const Key('detail-temple-name'))) ||
        tester.any(find.byKey(const Key('get-directions-button'))),
    timeout: const Duration(seconds: 20),
  );
  await tester.pump(const Duration(seconds: 2));
  final onDetail = _allText(tester);
  final caption = onCard.contains('Punaura Dham') ||
      onDetail.contains('Punaura Dham');
  final shown = _captionSnippet(onCard) ?? _captionSnippet(onDetail);
  if (tester.any(find.byKey(const Key('detail-photo-credit')))) {
    await tester.ensureVisible(find.byKey(const Key('detail-photo-credit')));
  } else if (tester.any(find.textContaining('Punaura'))) {
    await tester.ensureVisible(find.textContaining('Punaura'));
  }
  await _shot(tester, '07-janaki-caption');
  _result(
    7,
    caption,
    caption
        ? 'caption contains Punaura Dham (${shown ?? "on screen"})'
        : 'Punaura Dham was not on the card or detail; '
              'screen=${_screenHint(tester)}',
  );

  final opened = await _revealDirections(tester);
  if (!opened) {
    await _leaveDetail(tester);
    final withPin = _cardWhere(tester, (temple) => temple.hasCoordinates);
    if (withPin != null) {
      await tester.ensureVisible(withPin.finder);
      await tester.tap(withPin.finder);
      await tester.pump(const Duration(seconds: 1));
      await _waitUntil(
        tester,
        () => tester.any(find.byKey(const Key('detail-temple-name'))),
        timeout: const Duration(seconds: 15),
      );
    }
  }
  final visible = await _revealDirections(tester);
  if (!visible) {
    await _shot(tester, '08-get-directions');
    _result(8, false, 'Get Directions was not on the detail page');
    return;
  }
  await _shot(tester, '08-get-directions');
  await tester.tap(find.byKey(const Key('get-directions-button')));
  await tester.pump(const Duration(seconds: 2));
  final life = tester.binding.lifecycleState;
  final snack = tester.any(
    find.textContaining("Couldn't open directions"),
  );
  final left = life == AppLifecycleState.inactive ||
      life == AppLifecycleState.paused ||
      life == AppLifecycleState.hidden;
  await _shot(tester, '08-maps-intent');
  _result(
    8,
    visible && left && !snack,
    'Get Directions visible; lifecycle=$life; '
        'snackbar=${snack ? 'yes' : 'no'}',
  );
}

String? _captionSnippet(String text) {
  final match = RegExp(r'Shows Punaura Dham|Punaura Dham').firstMatch(text);
  return match?.group(0);
}

Future<({Finder finder, TempleBrowseCard card})?> _findCard(
  WidgetTester tester,
  bool Function(Temple temple) test,
) async {
  for (var i = 0; i < 6; i++) {
    final found = _cardWhere(tester, test);
    if (found != null) return found;
    final list = find.byType(ListView);
    if (!tester.any(list)) break;
    await tester.drag(list.first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 250));
  }
  return _cardWhere(tester, test);
}

({Finder finder, TempleBrowseCard card})? _cardWhere(
  WidgetTester tester,
  bool Function(Temple temple) test,
) {
  final cards = find.byType(TempleBrowseCard);
  final count = cards.evaluate().length;
  for (var i = 0; i < count; i++) {
    final finder = cards.at(i);
    final card = tester.widget<TempleBrowseCard>(finder);
    if (test(card.temple)) {
      return (finder: finder, card: card);
    }
  }
  return null;
}

Future<bool> _revealDirections(WidgetTester tester) async {
  final button = find.byKey(const Key('get-directions-button'));
  if (!tester.any(button)) {
    final scroll = find.byType(Scrollable);
    if (tester.any(scroll)) {
      await tester.drag(scroll.last, const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
  if (!tester.any(button)) return false;
  await tester.ensureVisible(button);
  await tester.pump(const Duration(milliseconds: 200));
  return true;
}

Future<void> _leaveDetail(WidgetTester tester) async {
  final back = find.byIcon(Icons.arrow_back_rounded);
  if (tester.any(back)) {
    await tester.tap(back);
    await tester.pump(const Duration(milliseconds: 500));
    return;
  }
  await tester.pageBack();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _airplanePhase(WidgetTester tester) async {
  String link = 'unavailable';
  try {
    final results = await Connectivity().checkConnectivity();
    link = results.map((result) => result.name).join('+');
  } catch (e) {
    link = 'error';
  }
  final gate = await _waitUntil(
    tester,
    () => _gateVisible(tester) || _maintenanceVisible(tester),
    timeout: const Duration(seconds: 20),
  );
  if (gate && _gateVisible(tester)) {
    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await _waitUntil(
      tester,
      () => !_gateVisible(tester),
      timeout: const Duration(seconds: 15),
    );
  }
  await _waitUntil(
    tester,
    () =>
        _maintenanceVisible(tester) ||
        _browseLabel(tester) != null ||
        tester.any(find.text('Could not load temples.')) ||
        tester.any(find.text('Retry')) ||
        tester.any(find.text('No temples available yet.')),
    timeout: const Duration(seconds: 30),
  );
  await _shot(tester, '06-airplane');
  final maintenance = _maintenanceVisible(tester);
  final retry = tester.any(find.text('Retry'));
  final error = tester.any(find.text('Could not load temples.'));
  _result(
    6,
    !maintenance,
    'maintenance=${maintenance ? 'yes' : 'no'}; '
        'connectivity=$link; '
        'showed ${_screenHint(tester)}; '
        'no-cache error=${error && retry ? 'yes' : 'no'}',
  );
}
