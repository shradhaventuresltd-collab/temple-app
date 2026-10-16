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
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/utils/detail_honesty.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('tester checks', (tester) async {
    final phase = _readPhase();
    _logLine('PHASE $phase');
    try {
      if (phase == 'kill-switch') {
        app.integrationTestConfigOverride = const AppConfig(
          killSwitch: true,
          maintenanceMessage: 'Tester kill switch',
        );
      } else if (phase == 'force-update') {
        app.integrationTestConfigOverride = const AppConfig(
          minSupportedBuild: 1000000,
        );
      }
      await app.main();
      await tester.pump(const Duration(milliseconds: 300));
      switch (phase) {
        case 'accept':
          await _acceptPhase(tester);
        case 'relaunch-1':
        case 'relaunch-2':
        case 'relaunch-3':
          await _homeLaunch(tester, phase);
        case 'cold':
          await _homeLaunch(tester, phase);
          await _uiChecks(tester);
        case 'resume':
          await _homeLaunch(tester, phase, capture: false);
          await _resumeOnly(tester);
        case 'detail':
          await _homeLaunch(tester, phase, capture: false);
          await _detailOnly(tester);
        case 'airplane':
          await _airplanePhase(tester);
        case 'kill-switch':
          await _killSwitchPhase(tester);
        case 'force-update':
          await _forceUpdatePhase(tester);
        default:
          _result(0, false, 'unknown phase $phase');
      }
    } catch (e, st) {
      _logLine('HARNESS FAIL $phase $e');
      final stack = st.toString().split('\n').take(6).join(' | ');
      _logLine('STACK $stack');
      await _shot(tester, '99-$phase-error');
    } finally {
      _logLine('DONE $phase');
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
  final line = '$_log $flat';
  developer.log(line, name: _log);
  // Release AOT does not publish dart:developer names as a logcat tag.
  // debugPrint reaches logcat as I/flutter in release.
  debugPrint(line);
}

void _result(int id, bool pass, String note) {
  _logLine('RESULT $id ${pass ? 'PASS' : 'FAIL'} $note');
}

Future<void> _shot(WidgetTester tester, String name) async {
  final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  // Host screencap is the evidence. convertFlutterSurfaceToImage registers
  // a tearDown after the test has started and drops the element tree.
  // Pump one frame, then wait so the emulator surface has presented it.
  // A 360dp force-update frame was black when the capture raced that present.
  if (WidgetsBinding.instance.rootElement != null) {
    await tester.pump();
  }
  await Future<void>.delayed(const Duration(milliseconds: 600));
  _logLine('SHOT $safe');
  await Future<void>.delayed(const Duration(milliseconds: 1200));
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

/// Force-update screen or soft-update banner from the default Remote Config
/// path. Defaults are min and recommended build 1, so neither should show.
String? _updateBlock(WidgetTester tester) {
  const keys = <String>[
    'force-update-screen',
    'force-update-button',
    'soft-update-nudge',
    'soft-update-open',
    'soft-update-dismiss',
  ];
  for (final name in keys) {
    if (tester.any(find.byKey(Key(name)))) return name;
  }
  const phrases = <String>[
    'Update required',
    'Update on Play Store',
    'A newer version is ready on the Play Store.',
  ];
  final text = _allText(tester);
  for (final phrase in phrases) {
    if (text.contains(phrase)) return phrase;
  }
  return null;
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

Future<void> _homeLaunch(
  WidgetTester tester,
  String phase, {
  bool capture = true,
}) async {
  final ready = await _waitUntil(
    tester,
    () =>
        _browseLabel(tester) != null ||
        _gateVisible(tester) ||
        _maintenanceVisible(tester) ||
        _updateBlock(tester) != null ||
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
  // The soft-update banner claims a preferences day after the first Home frame.
  if (_updateBlock(tester) == null) {
    await _waitUntil(
      tester,
      () => _updateBlock(tester) != null,
      timeout: const Duration(seconds: 2),
    );
  }
  if (capture) {
    final shotName = phase == 'cold' ? '02-cold-start' : '02-$phase';
    await _shot(tester, shotName);
  }

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
  final update = _updateBlock(tester);
  _logLine(
    'UPDATE $phase ${update == null ? 'PASS' : 'FAIL'} '
    '${update ?? 'no force-update or soft-update prompt'}',
  );
}

Future<void> _uiChecks(WidgetTester tester) async {
  await _mosaicCheck(tester);
  if (!await _openBrowse(tester)) {
    _result(4, false, 'browse did not open; ${_screenHint(tester)}');
    _result(5, false, 'browse did not open');
    _result(10, false, 'browse did not open');
    return;
  }
  await _longNameCheck(tester);
  await _searchChecks(tester);
  await _picsumCheck(tester);
}

Future<void> _resumeOnly(WidgetTester tester) async {
  if (!await _openBrowse(tester)) {
    _result(11, false, 'browse did not open; ${_screenHint(tester)}');
    return;
  }
  await _resumeCheck(tester);
}

Future<void> _detailOnly(WidgetTester tester) async {
  if (!await _openBrowse(tester)) {
    _result(7, false, 'browse did not open; ${_screenHint(tester)}');
    _result(8, false, 'browse did not open');
    return;
  }
  await _janakiAndDirections(tester);
}

Future<void> _mosaicCheck(WidgetTester tester) async {
  final mosaic = find.byType(HomeMosaicCollage);
  if (tester.any(mosaic)) {
    await tester.ensureVisible(mosaic);
    await tester.pump(const Duration(milliseconds: 200));
  }
  await _waitUntil(
    tester,
    () =>
        _loadingInMosaic(tester) == 0 &&
        (_photosInMosaic(tester) > 0 || _pendingInMosaic(tester) > 0),
    timeout: const Duration(seconds: 12),
  );
  if (tester.any(mosaic)) {
    await tester.ensureVisible(mosaic);
  }
  final pending = _pendingInMosaic(tester);
  final photos = _photosInMosaic(tester);
  final loading = _loadingInMosaic(tester);
  await _shot(tester, '03-home-mosaic');
  // Real covers are expected. A grey shimmer or an empty collage is not.
  final pass =
      tester.any(mosaic) && loading == 0 && (photos > 0 || pending > 0);
  _result(
    3,
    pass,
    'network tiles=$photos Photo pending tiles=$pending '
        'grey placeholders=$loading',
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
  final notes = <String>[];
  var pass = true;

  Future<void> named(
    String query,
    bool Function(Temple temple) matches, {
    required bool rankingFinding,
    String? expected,
  }) async {
    await _typeQuery(tester, query);
    final top = _visibleTemples(tester, limit: 3);
    final count = _resultCount(tester);
    final label = _templeList(top);
    final topMatches = top.isNotEmpty && matches(top.first);
    if (rankingFinding) {
      notes.add(
        '$query RANKING top-matches=${topMatches ? 'yes' : 'no'} '
        'expected=${expected ?? 'named temple'} '
        'count=${count ?? 'none'} top3=$label',
      );
      _logLine(
        'SEARCH $query RANKING top-matches=${topMatches ? 'yes' : 'no'} '
        'top3=$label count=${count ?? 'none'}',
      );
    } else {
      if (!topMatches) pass = false;
      notes.add(
        '$query found=${topMatches ? 'yes' : 'no'} '
        'count=${count ?? 'none'} top3=$label',
      );
      _logLine(
        'SEARCH $query ${topMatches ? 'PASS' : 'FAIL'} '
        'top3=$label count=${count ?? 'none'}',
      );
    }
    await _shot(tester, '05-search-${query.toLowerCase()}');
  }

  await named('Minakshi', (temple) {
    final name = temple.name.toLowerCase();
    return name.contains('minakshi') || name.contains('meenakshi');
  }, rankingFinding: false);
  await named(
    'Tirupathi',
    _isTirupatiVenkateswara,
    rankingFinding: true,
    expected: 'Tirumala/Tirupati Venkateswara',
  );
  await named('Tiruchendur', (temple) {
    final blob = '${temple.name} ${temple.city} ${temple.state}'.toLowerCase();
    return blob.contains('tiruchendur') || blob.contains('thiruchendur');
  }, rankingFinding: false);
  await named(
    'Sivan',
    (temple) => temple.name.toLowerCase().contains('sivan'),
    rankingFinding: true,
    expected: 'a Sivan temple',
  );

  final counts = <String>[];
  for (final query in const ['ee', 'th', 'it']) {
    await _typeQuery(tester, query);
    final count = _resultCount(tester);
    final label = _templeList(_visibleTemples(tester, limit: 3));
    counts.add('$query=${count ?? 'none'} top3=$label');
    _logLine('SEARCH $query COUNT ${count ?? 'none'} top3=$label');
    await _shot(tester, '05-search-$query');
    if (count == null) pass = false;
  }
  await _typeQuery(tester, '');
  _result(5, pass, '${notes.join('; ')}; ${counts.join(' ')}');
}

bool _isTirupatiVenkateswara(Temple temple) {
  final blob = '${temple.name} ${temple.city} ${temple.state}'.toLowerCase();
  final deity = blob.contains('venkateswara') ||
      blob.contains('venkateshwara') ||
      blob.contains('balaji');
  final place = blob.contains('tirupati') ||
      blob.contains('tirumala') ||
      blob.contains('tirupathi');
  return deity && place;
}

List<Temple> _visibleTemples(WidgetTester tester, {required int limit}) {
  final cards = find.byType(TempleBrowseCard);
  final count = cards.evaluate().length;
  final temples = <Temple>[];
  for (var i = 0; i < count && temples.length < limit; i++) {
    temples.add(tester.widget<TempleBrowseCard>(cards.at(i)).temple);
  }
  return temples;
}

String _templeList(List<Temple> temples) {
  if (temples.isEmpty) return 'none';
  return temples.map((temple) => temple.name).join(' / ');
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

bool _isPicsumOrPlaceholder(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return false;
  if (url.toLowerCase().contains('picsum.photos')) return true;
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }
  return isPlaceholderImageUrl(url);
}

List<String> _templeImageUrls(Temple temple) {
  return <String>[
    temple.imageUrl,
    ...temple.images,
    for (final photo in temple.photos) photo.url,
    for (final photo in temple.photos)
      if (photo.thumbUrl != null) photo.thumbUrl!,
  ];
}

String? _directoryPlaceholder(List<Temple> temples) {
  for (final temple in temples) {
    for (final raw in _templeImageUrls(temple)) {
      if (!_isPicsumOrPlaceholder(raw)) continue;
      final who = temple.id.isEmpty ? temple.name : temple.id;
      return '$who ${raw.trim()}';
    }
  }
  return null;
}

List<String> _visibleImageUrls(WidgetTester tester, Finder scope) {
  final images = find.descendant(
    of: scope,
    matching: find.byType(CachedNetworkImage),
  );
  return <String>[
    for (final widget in tester.widgetList<CachedNetworkImage>(images))
      widget.imageUrl,
  ];
}

bool _isAnjengo(Temple temple) {
  final id = temple.id.toLowerCase();
  final name = temple.name.toLowerCase();
  return id == 'anjengo-sree-durga-devi-temple' || name.contains('anjengo');
}

bool _isAkshardham(Temple temple) {
  final id = temple.id.toLowerCase();
  final name = temple.name.toLowerCase();
  final place = '${temple.city} ${temple.state} ${temple.location}'.toLowerCase();
  if (name.contains('delhi') || place.contains('delhi')) return false;
  if (id == 'akshardham-temple') return true;
  if (!name.contains('akshardham')) return false;
  return place.contains('gandhinagar') || place.contains('gujarat');
}

/// Photo pending, or a real network photo. A picsum or other placeholder URL
/// fails even when the tile also says Photo pending.
String _cardPhotoState(WidgetTester tester, Finder card) {
  final urls = _visibleImageUrls(tester, card);
  for (final url in urls) {
    if (_isPicsumOrPlaceholder(url)) return 'placeholder $url';
  }
  final pending = find.descendant(
    of: card,
    matching: find.text('Photo pending'),
  );
  if (tester.any(pending)) return 'photo-pending';
  if (urls.isNotEmpty) return 'photo ${urls.first}';
  return 'neither';
}

Future<String> _templePhotoNote(
  WidgetTester tester, {
  required String label,
  required String query,
  required bool Function(Temple temple) test,
  required String shot,
}) async {
  await _typeQuery(tester, query);
  final found = await _findCard(tester, test);
  if (found == null) {
    await _shot(tester, shot);
    return '$label missing';
  }
  final stored = _directoryPlaceholder(<Temple>[found.card.temple]);
  await tester.ensureVisible(found.finder);
  await tester.pump(const Duration(milliseconds: 400));
  final state = _cardPhotoState(tester, found.finder);
  await _shot(tester, shot);
  if (stored != null) {
    return '$label stored-placeholder $stored; card=$state';
  }
  if (state == 'photo-pending' || state.startsWith('photo ')) {
    return '$label $state';
  }
  return '$label $state';
}

bool _photoNotePasses(String note) {
  if (note.contains(' missing')) return false;
  if (note.contains('stored-placeholder')) return false;
  if (note.contains('placeholder ')) return false;
  if (note.contains('neither')) return false;
  return note.contains('photo-pending') || note.contains('photo ');
}

Future<void> _picsumCheck(WidgetTester tester) async {
  final published = TempleService.published;
  final stored = published == null ? null : _directoryPlaceholder(published);
  final onScreen = _visibleImageUrls(tester, find.byType(MaterialApp));
  final visibleBad = onScreen.where(_isPicsumOrPlaceholder).toList();
  final anjengo = await _templePhotoNote(
    tester,
    label: 'Anjengo',
    query: 'Anjengo',
    test: _isAnjengo,
    shot: '10-anjengo',
  );
  final akshardham = await _templePhotoNote(
    tester,
    label: 'Akshardham',
    query: 'Akshardham',
    test: _isAkshardham,
    shot: '10-akshardham',
  );
  await _typeQuery(tester, '');
  final pass = published != null &&
      stored == null &&
      visibleBad.isEmpty &&
      _photoNotePasses(anjengo) &&
      _photoNotePasses(akshardham);
  final directory = published == null
      ? 'directory=missing'
      : 'directory=${published.length} placeholder=${stored ?? 'none'}';
  _result(
    10,
    pass,
    '$directory; visible-placeholder=${visibleBad.isEmpty ? 'none' : visibleBad.first}; '
        '$anjengo; $akshardham',
  );
}

Future<void> _resumeCheck(WidgetTester tester) async {
  try {
    await _typeQuery(tester, '');
    final beforeName = _topTempleName(tester);
    final beforeCards = find.byType(TempleBrowseCard).evaluate().length;
    final beforePublished = TempleService.published?.length;
    final beforeCount = beforePublished ?? beforeCards;
    final binding = tester.binding;
    // Synchronous lifecycle only. A multi-second pump here never returned:
    // the cold phase was killed at its cap before this check could log.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _shot(tester, '11-resume');
    final afterName = _topTempleName(tester);
    final afterCards = find.byType(TempleBrowseCard).evaluate().length;
    final afterPublished = TempleService.published?.length;
    final afterCount = afterPublished ?? afterCards;
    final text = _allText(tester);
    final empty = text.contains('No temples to browse') ||
        text.contains('Loading temples') ||
        text.contains('Could not load temples');
    final pass = beforeCount > 0 &&
        afterCount > 0 &&
        beforeCount == afterCount &&
        beforeCards > 0 &&
        afterCards > 0 &&
        beforeName != null &&
        beforeName == afterName &&
        !empty;
    _result(
      11,
      pass,
      'before=$beforeCount after=$afterCount '
          'cards=$beforeCards->$afterCards '
          'top=${beforeName ?? 'none'}->${afterName ?? 'none'} '
          'empty=${empty ? 'yes' : 'no'}',
    );
  } catch (e) {
    await _shot(tester, '11-resume');
    _result(11, false, 'resume threw $e');
  }
}

Future<void> _killSwitchPhase(WidgetTester tester) async {
  final shown = await _waitUntil(
    tester,
    () =>
        _maintenanceVisible(tester) ||
        tester.any(find.text('Tester kill switch')),
    timeout: const Duration(seconds: 20),
  );
  await _shot(tester, '12-kill-switch');
  final maintenance = _maintenanceVisible(tester);
  final message = _allText(tester).contains('Tester kill switch');
  final home = _browseLabel(tester) != null;
  _result(
    12,
    shown && maintenance && message && !home,
    'maintenance=${maintenance ? 'yes' : 'no'}; '
        'message=${message ? 'yes' : 'no'}; '
        'home=${home ? 'yes' : 'no'}; ${_screenHint(tester)}',
  );
}

Future<void> _forceUpdatePhase(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        _gateVisible(tester) ||
        _updateBlock(tester) != null ||
        _browseLabel(tester) != null ||
        _maintenanceVisible(tester),
    timeout: const Duration(seconds: 25),
  );
  if (_gateVisible(tester)) {
    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pump(const Duration(milliseconds: 300));
  }
  final shown = await _waitUntil(
    tester,
    () => _updateBlock(tester) != null || _browseLabel(tester) != null,
    timeout: const Duration(seconds: 25),
  );
  await _shot(tester, '13-force-update');
  final update = _updateBlock(tester);
  final hard = update == 'force-update-screen' ||
      update == 'force-update-button' ||
      update == 'Update required' ||
      update == 'Update on Play Store';
  final home = _browseLabel(tester) != null;
  _result(
    13,
    shown && hard && !home,
    'update=${update ?? 'none'}; home=${home ? 'yes' : 'no'}; '
        '${_screenHint(tester)}',
  );
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
