import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

import 'tester_checks_png.dart';

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
      await _enableFlutterShots(tester);
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
      try {
        await _shot(tester, '99-$phase-error');
      } catch (shotError) {
        _logLine('HARNESS error-shot $shotError');
      }
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

const _shotPort = 18765;
const _shotChannel = MethodChannel('plugins.flutter.io/integration_test');

ServerSocket? _shotServer;
Completer<Socket>? _shotPending;
int? _prevFingerprint;

/// Converts the Flutter surface once, inside the test. The plugin then
/// registers a tearDown; that call throws because the test has started, and
/// the surface is already an image by then.
Future<void> _enableFlutterShots(WidgetTester tester) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  Object? last;
  for (var attempt = 0; attempt < 6; attempt++) {
    try {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      _logLine('HARNESS surface converted');
      return;
    } on StateError catch (e) {
      await tester.pump();
      _logLine('HARNESS surface converted $e');
      return;
    } catch (e) {
      last = e;
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  _logLine('HARNESS surface failed $last');
}

Future<void> _ensureShotServer() async {
  if (_shotServer != null) return;
  SocketException? last;
  for (var attempt = 0; attempt < 8; attempt++) {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        _shotPort,
        shared: true,
      );
      server.listen(
        (socket) {
          final pending = _shotPending;
          if (pending != null && !pending.isCompleted) {
            pending.complete(socket);
          } else {
            socket.destroy();
          }
        },
        onError: (Object error) {
          _logLine('HARNESS socket $error');
        },
      );
      _shotServer = server;
      return;
    } on SocketException catch (error) {
      last = error;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
  throw StateError('screenshot socket: $last');
}

void _dropScreenshotBytes(IntegrationTestWidgetsFlutterBinding binding) {
  final shots = binding.reportData?['screenshots'];
  if (shots is List) shots.clear();
}

Future<List<int>> _readScreenshotChunks() async {
  final length = await _shotChannel.invokeMethod<int>('screenshotLength') ?? 0;
  if (length <= 0) {
    throw StateError('screenshotLength=$length');
  }
  const chunk = 200000;
  final out = BytesBuilder(copy: false);
  for (var offset = 0; offset < length; offset += chunk) {
    final n = length - offset < chunk ? length - offset : chunk;
    final part = await _shotChannel.invokeMethod<Object>(
      'readScreenshotChunk',
      <String, int>{'offset': offset, 'length': n},
    );
    if (part is Uint8List) {
      out.add(part);
    } else if (part is List) {
      out.add(part.cast<int>());
    } else {
      throw StateError('chunk at $offset was ${part.runtimeType}');
    }
  }
  final bytes = out.takeBytes();
  if (bytes.length != length) {
    throw StateError('screenshot bytes ${bytes.length} of $length');
  }
  return bytes;
}

Future<List<int>> _captureBytes(String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  List<int>? inline;
  try {
    final bytes = await binding.takeScreenshot(name);
    _dropScreenshotBytes(binding);
    if (bytes.isNotEmpty && bytes.length <= 400000) return bytes;
    inline = bytes;
  } catch (_) {
    _dropScreenshotBytes(binding);
  }
  try {
    final bytes = await _readScreenshotChunks();
    _dropScreenshotBytes(binding);
    if (bytes.isNotEmpty) return bytes;
  } catch (e) {
    if (inline != null && inline.isNotEmpty) return inline;
    _logLine('HARNESS capture $name $e');
    rethrow;
  }
  if (inline != null && inline.isNotEmpty) return inline;
  throw StateError('empty screenshot $name');
}

Future<({List<int> bytes, int retries})> _captureFresh(
  WidgetTester tester,
  String name,
) async {
  if (WidgetsBinding.instance.rootElement != null) {
    await tester.pump();
  }
  List<int> bytes;
  try {
    bytes = await _captureBytes(name);
  } catch (e) {
    _logLine('HARNESS capture-retry $name $e');
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    bytes = await _captureBytes(name);
    final fingerprint = pngFingerprint(bytes);
    _prevFingerprint = fingerprint;
    _logLine(
      'CAPTURE $name retries=1 black=${pngLooksBlack(bytes) ? 'yes' : 'no'} '
      'identical=no bytes=${bytes.length}',
    );
    return (bytes: bytes, retries: 1);
  }
  var black = pngLooksBlack(bytes);
  var fingerprint = pngFingerprint(bytes);
  var identical = _prevFingerprint != null && fingerprint == _prevFingerprint;
  var retries = 0;
  if (black || identical) {
    retries = 1;
    try {
      await tester.pump(const Duration(milliseconds: 200));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      bytes = await _captureBytes(name);
      black = pngLooksBlack(bytes);
      fingerprint = pngFingerprint(bytes);
      identical = _prevFingerprint != null && fingerprint == _prevFingerprint;
    } catch (e) {
      _logLine('HARNESS recapture $name $e');
    }
  }
  _prevFingerprint = fingerprint;
  _logLine(
    'CAPTURE $name retries=$retries black=${black ? 'yes' : 'no'} '
    'identical=${identical ? 'yes' : 'no'} bytes=${bytes.length}',
  );
  return (bytes: bytes, retries: retries);
}

Future<void> _sendPng(String name, List<int> bytes, int retries) async {
  await _ensureShotServer();
  final pending = Completer<Socket>();
  _shotPending = pending;
  _logLine('PNGREADY $name ${bytes.length} $retries');
  try {
    final socket = await pending.future.timeout(const Duration(seconds: 25));
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  } finally {
    if (identical(_shotPending, pending)) _shotPending = null;
  }
}

Future<void> _shot(
  WidgetTester tester,
  String name, {
  Duration hold = Duration.zero,
  bool adb = false,
}) async {
  final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  if (adb) {
    // The maps activity is outside Flutter. The host screencaps after
    // dumpsys window leaves this package.
    _logLine('SHOTADB $safe');
    await Future<void>.delayed(hold);
    return;
  }
  try {
    final shot = await _captureFresh(tester, safe);
    await _sendPng(safe, shot.bytes, shot.retries);
    if (hold > Duration.zero) {
      await Future<void>.delayed(hold);
    }
  } catch (e) {
    // A missing plugin or a binder failure must not abort the phase.
    // The host takes one adb frame of the current activity.
    _logLine('HARNESS capture-fallback $safe $e');
    _logLine('SHOTFALLBACK $safe');
    final pause = hold < const Duration(seconds: 5)
        ? const Duration(seconds: 5)
        : hold;
    await Future<void>.delayed(pause);
  }
}

Future<bool> _waitUntil(
  WidgetTester tester,
  bool Function() ready, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (ready()) return true;
    // Bounded settle. A repeating mosaic shimmer never goes idle, so the
    // timeout must stay short and a timeout is not a failure by itself.
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(milliseconds: 400),
      );
    } catch (_) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (ready()) return true;
  }
  return ready();
}

/// Home is ready for a launch screenshot only when Browse N is on screen.
/// The loading spinner (`Loading temples…`) is not that screen.
bool _directoryReady(WidgetTester tester) {
  if (tester.any(find.textContaining('Loading temples'))) return false;
  if (tester.any(find.text('Preparing the directory. This usually takes a moment.'))) {
    return false;
  }
  if (_browseCount(_browseLabel(tester)) != _expectedTemples) return false;
  return tester.any(find.byKey(const Key('home-browse-temples')));
}

/// True only after [ready] is on screen. In-app frames are Flutter
/// screenshots. [adb] is only the maps handoff, which leaves the app.
/// A check must not PASS when this returns false.
Future<bool> _captureWhen(
  WidgetTester tester,
  String name,
  bool Function() ready, {
  required String waitingFor,
  Duration timeout = const Duration(seconds: 20),
  Duration hold = Duration.zero,
  bool adb = false,
}) async {
  final ok = await _waitUntil(tester, ready, timeout: timeout);
  if (!ok) {
    _logLine(
      'SHOTWAIT $name FAIL missing $waitingFor screen=${_screenHint(tester)}',
    );
    await _shot(tester, name, hold: hold, adb: adb);
    return false;
  }
  _logLine('SHOTWAIT $name PASS $waitingFor');
  await _shot(tester, name, hold: hold, adb: adb);
  return true;
}

/// Icon-only tiles are [MosaicTilePlaceholder]. A collage with neither a
/// network image nor Photo pending is blank.
String _mosaicDefect(WidgetTester tester) {
  final mosaic = find.byType(HomeMosaicCollage);
  if (!tester.any(mosaic)) return 'mosaic-missing';
  final iconOnly = find
      .descendant(of: mosaic, matching: find.byType(MosaicTilePlaceholder))
      .evaluate()
      .length;
  final photos = find
      .descendant(of: mosaic, matching: find.byType(CachedNetworkImage))
      .evaluate()
      .length;
  final pending = find
      .descendant(of: mosaic, matching: find.text('Photo pending'))
      .evaluate()
      .length;
  if (iconOnly > 0) {
    return 'icon-only=$iconOnly photos=$photos pending=$pending';
  }
  if (photos == 0 && pending == 0) return 'blank photos=0 pending=0';
  return 'ok photos=$photos pending=$pending icon-only=0';
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
  final browse = await _captureWhen(
    tester,
    '01-accept-after',
    () => _directoryReady(tester),
    waitingFor: 'Browse $_expectedTemples Temples',
    timeout: const Duration(seconds: 45),
  );
  _result(
    1,
    left && browse,
    browse
        ? 'one tap left the gate; Browse $_expectedTemples Temples was on screen'
        : 'Browse $_expectedTemples Temples was not on screen after the tap; '
            '${_screenHint(tester)}',
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
        _directoryReady(tester) ||
        _gateVisible(tester) ||
        _maintenanceVisible(tester) ||
        _updateBlock(tester) != null ||
        _firebaseOnScreen(tester) ||
        tester.any(find.text('Could not load temples.')) ||
        tester.any(find.text('Retry')),
    timeout: const Duration(seconds: 45),
  );
  final label = _browseLabel(tester);
  if (_directoryReady(tester)) {
    // The browse button sits below the 420px collage. Scrolling it on
    // screen unmounts the mosaic, so the launch shot stays at offset 0.
    await _jumpHomeToTop(tester);
    await _waitUntil(
      tester,
      () => _mosaicDefect(tester).startsWith('ok'),
      timeout: const Duration(seconds: 3),
    );
  }
  // The soft-update banner claims a preferences day after the first Home frame.
  if (_updateBlock(tester) == null && _directoryReady(tester)) {
    await _waitUntil(
      tester,
      () => _updateBlock(tester) != null,
      timeout: const Duration(seconds: 2),
    );
  }
  var shotOk = !capture;
  if (capture) {
    final shotName = phase == 'cold' ? '02-cold-start' : '02-$phase';
    final defect = _mosaicDefect(tester);
    _logLine('MOSAIC $shotName $defect');
    shotOk = await _captureWhen(
      tester,
      shotName,
      () => _directoryReady(tester),
      waitingFor: 'Browse $_expectedTemples Temples',
      timeout: const Duration(seconds: 15),
    );
  }

  final count = _browseCount(label);
  final firebase = _firebaseOnScreen(tester);
  final gate = _gateVisible(tester);
  final maintenance = _maintenanceVisible(tester);
  final pass =
      ready &&
      shotOk &&
      _directoryReady(tester) &&
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

Future<void> _jumpHomeToTop(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  try {
    final position = tester.state<ScrollableState>(scrollables.first).position;
    if (position.pixels != 0) {
      position.jumpTo(0);
      await tester.pump(const Duration(milliseconds: 200));
    }
  } catch (e) {
    _logLine('HARNESS scroll-top $e');
  }
}

Future<void> _mosaicCheck(WidgetTester tester) async {
  await _jumpHomeToTop(tester);
  await _waitUntil(
    tester,
    () => _mosaicDefect(tester).startsWith('ok'),
    timeout: const Duration(seconds: 8),
  );
  await _jumpHomeToTop(tester);
  final defect = _mosaicDefect(tester);
  _logLine('MOSAIC 03-home-mosaic $defect');
  final shot = await _captureWhen(
    tester,
    '03-home-mosaic',
    () => tester.any(find.byType(HomeMosaicCollage)),
    waitingFor: 'home mosaic',
    timeout: const Duration(seconds: 5),
  );
  final pass = shot && defect.startsWith('ok');
  _result(3, pass, defect);
}

Future<bool> _openBrowse(WidgetTester tester) async {
  final ready = await _waitUntil(
    tester,
    () => _directoryReady(tester),
    timeout: const Duration(seconds: 25),
  );
  if (!ready) return false;
  final button = find.byKey(const Key('home-browse-temples'));
  if (button.evaluate().length != 1) return false;
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
    await _captureWhen(
      tester,
      '04-long-name',
      () => false,
      waitingFor: 'a 2-line temple name',
      timeout: Duration.zero,
    );
    _result(4, false, 'no browse name wrapped to 2 lines');
    await _typeQuery(tester, '');
    return;
  }
  await tester.ensureVisible(found.finder);
  final shot = await _captureWhen(
    tester,
    '04-long-name',
    () => _twoLineName(tester)?.lines == 2,
    waitingFor: 'a 2-line temple name',
    timeout: const Duration(seconds: 8),
  );
  _result(
    4,
    shot && found.lines == 2,
    '"${found.name}" wraps to ${found.lines} lines'
        '${shot ? '' : '; screenshot missed the wrapped name'}',
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
    bool Function(Temple temple, int? count) matches, {
    required bool rankingFinding,
    String? expected,
  }) async {
    await _typeQuery(tester, query);
    final top = _visibleTemples(tester, limit: 3);
    final count = _resultCount(tester);
    final label = _templeList(top);
    final topMatches = top.isNotEmpty && matches(top.first, count);
    final shot = await _captureWhen(
      tester,
      '05-search-${query.toLowerCase()}',
      () =>
          _visibleTemples(tester, limit: 1).isNotEmpty ||
          _resultCount(tester) != null,
      waitingFor: 'results for $query',
      timeout: const Duration(seconds: 12),
    );
    if (rankingFinding) {
      notes.add(
        '$query RANKING top-matches=${topMatches ? 'yes' : 'no'} '
        'expected=${expected ?? 'named temple'} '
        'count=${count ?? 'none'} top3=$label shot=${shot ? 'yes' : 'no'}',
      );
      _logLine(
        'SEARCH $query RANKING top-matches=${topMatches ? 'yes' : 'no'} '
        'top3=$label count=${count ?? 'none'}',
      );
    } else {
      if (!topMatches || !shot) pass = false;
      notes.add(
        '$query found=${topMatches ? 'yes' : 'no'} '
        'count=${count ?? 'none'} top3=$label shot=${shot ? 'yes' : 'no'}',
      );
      _logLine(
        'SEARCH $query ${topMatches && shot ? 'PASS' : 'FAIL'} '
        'top3=$label count=${count ?? 'none'}',
      );
    }
  }

  await named('Minakshi', (temple, count) {
    final name = temple.name.toLowerCase();
    return name.contains('minakshi') || name.contains('meenakshi');
  }, rankingFinding: false);
  await named(
    'Tirupathi',
    (temple, count) => _isTirupatiVenkateswara(temple),
    rankingFinding: true,
    expected: 'Tirumala/Tirupati Venkateswara',
  );
  await named('Tiruchendur', _isTiruchendur, rankingFinding: false);
  await named(
    'Sivan',
    (temple, count) => temple.name.toLowerCase().contains('sivan'),
    rankingFinding: true,
    expected: 'a Sivan temple',
  );

  final counts = <String>[];
  for (final query in const ['ee', 'th', 'it']) {
    await _typeQuery(tester, query);
    final count = _resultCount(tester);
    final label = _templeList(_visibleTemples(tester, limit: 3));
    final shot = await _captureWhen(
      tester,
      '05-search-$query',
      () => _resultCount(tester) != null,
      waitingFor: '$query result count',
      timeout: const Duration(seconds: 8),
    );
    counts.add('$query=${count ?? 'none'} top3=$label shot=${shot ? 'yes' : 'no'}');
    _logLine('SEARCH $query COUNT ${count ?? 'none'} top3=$label');
    if (count == null || !shot) pass = false;
  }
  await _typeQuery(tester, '');
  _result(5, pass, '${notes.join('; ')}; ${counts.join(' ')}');
}

bool _isTiruchendur(Temple temple, int? count) {
  final blob =
      '${temple.name} ${temple.city} ${temple.state} ${temple.location}'
          .toLowerCase();
  if (blob.contains('tiruchendur') || blob.contains('thiruchendur')) {
    return true;
  }
  // Prod lists this temple as Subramanya Swamy Temple. Tiruchendur is the
  // town, and the query returns that single result.
  final subramanya =
      blob.contains('subramanya') || blob.contains('subrahmanya');
  return subramanya && count == 1;
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

Future<void> _scrollUntilHit(WidgetTester tester, Finder finder) async {
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  if (finder.evaluate().length == 1) {
    try {
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 200));
    } catch (_) {}
    if (finder.hitTestable().evaluate().isNotEmpty) return;
  }
  for (var i = 0; i < 6; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    final scroll = find.byType(Scrollable);
    if (!tester.any(scroll)) break;
    await tester.drag(scroll.last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 250));
  }
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
    await _captureWhen(
      tester,
      '07-janaki-caption',
      () => false,
      waitingFor: 'Janaki Temple Sitamarhi',
      timeout: Duration.zero,
    );
    _result(7, false, 'Janaki Temple Sitamarhi was not in the loaded list');
    _result(8, false, 'no Janaki card to open');
    return;
  }

  await tester.ensureVisible(janaki.finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(janaki.finder);
  await tester.pump(const Duration(seconds: 1));
  await _waitUntil(
    tester,
    () =>
        tester.any(find.byKey(const Key('detail-temple-name'))) ||
        tester.any(find.byKey(const Key('get-directions-button'))),
    timeout: const Duration(seconds: 20),
  );
  // The caption is "Shows Punaura Dham". textContaining matches that
  // phrase. Several widgets can contain it, so do not ensureVisible.
  final caption = find.textContaining('Punaura Dham');
  await _scrollUntilHit(tester, caption);
  final captionShot = await _captureWhen(
    tester,
    '07-janaki-caption',
    () => caption.hitTestable().evaluate().isNotEmpty,
    waitingFor: 'Punaura Dham',
    timeout: const Duration(seconds: 12),
  );
  _result(
    7,
    captionShot,
    captionShot
        ? 'caption Punaura Dham was visible'
        : 'Punaura Dham was not visible; screen=${_screenHint(tester)}',
  );

  var visible = await _revealDirections(tester);
  if (!visible) {
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
      visible = await _revealDirections(tester);
    }
  }
  final directionsShot = await _captureWhen(
    tester,
    '08-get-directions',
    () =>
        find
            .byKey(const Key('get-directions-button'))
            .hitTestable()
            .evaluate()
            .isNotEmpty,
    waitingFor: 'Get Directions',
    timeout: const Duration(seconds: 8),
  );
  if (!directionsShot) {
    _result(8, false, 'Get Directions was not visible for the screenshot');
    return;
  }
  await tester.tap(find.byKey(const Key('get-directions-button')));
  final mapsShot = await _captureWhen(
    tester,
    '08-maps-intent',
    () {
      final life = tester.binding.lifecycleState;
      final snack = tester.any(
        find.textContaining("Couldn't open directions"),
      );
      final left = life == AppLifecycleState.inactive ||
          life == AppLifecycleState.paused ||
          life == AppLifecycleState.hidden;
      return left || snack;
    },
    waitingFor: 'a maps handoff',
    timeout: const Duration(seconds: 8),
    hold: const Duration(seconds: 10),
    adb: true,
  );
  final life = tester.binding.lifecycleState;
  final snack = tester.any(
    find.textContaining("Couldn't open directions"),
  );
  final left = life == AppLifecycleState.inactive ||
      life == AppLifecycleState.paused ||
      life == AppLifecycleState.hidden;
  _result(
    8,
    directionsShot && mapsShot && left && !snack,
    'Get Directions visible; lifecycle=$life; '
        'snackbar=${snack ? 'yes' : 'no'}; '
        'maps-shot=${mapsShot ? 'yes' : 'no'}',
  );
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
    await _captureWhen(
      tester,
      shot,
      () => false,
      waitingFor: label,
      timeout: Duration.zero,
    );
    return '$label missing shot=no';
  }
  final stored = _directoryPlaceholder(<Temple>[found.card.temple]);
  await tester.ensureVisible(found.finder);
  await tester.pump(const Duration(milliseconds: 400));
  final state = _cardPhotoState(tester, found.finder);
  final captured = await _captureWhen(
    tester,
    shot,
    () => _cardWhere(tester, test) != null,
    waitingFor: label,
    timeout: const Duration(seconds: 8),
  );
  final shotNote = 'shot=${captured ? 'yes' : 'no'}';
  if (stored != null) {
    return '$label stored-placeholder $stored; card=$state; $shotNote';
  }
  return '$label $state; $shotNote';
}

bool _photoNotePasses(String note) {
  if (note.contains('shot=no')) return false;
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
    final shot = await _captureWhen(
      tester,
      '11-resume',
      () {
        final text = _allText(tester);
        final empty = text.contains('No temples to browse') ||
            text.contains('Loading temples') ||
            text.contains('Could not load temples');
        return beforeName != null &&
            _topTempleName(tester) == beforeName &&
            find.byType(TempleBrowseCard).evaluate().isNotEmpty &&
            !empty;
      },
      waitingFor: 'browse list still showing ${beforeName ?? 'the same temple'}',
      timeout: const Duration(seconds: 12),
    );
    final afterName = _topTempleName(tester);
    final afterCards = find.byType(TempleBrowseCard).evaluate().length;
    final afterPublished = TempleService.published?.length;
    final afterCount = afterPublished ?? afterCards;
    final text = _allText(tester);
    final empty = text.contains('No temples to browse') ||
        text.contains('Loading temples') ||
        text.contains('Could not load temples');
    final pass = shot &&
        beforeCount > 0 &&
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
          'empty=${empty ? 'yes' : 'no'} '
          'shot=${shot ? 'yes' : 'no'}',
    );
  } catch (e) {
    await _captureWhen(
      tester,
      '11-resume',
      () => false,
      waitingFor: 'browse list after resume',
      timeout: Duration.zero,
    );
    _result(11, false, 'resume threw $e');
  }
}

Future<void> _killSwitchPhase(WidgetTester tester) async {
  final shot = await _captureWhen(
    tester,
    '12-kill-switch',
    () =>
        _maintenanceVisible(tester) &&
        tester.any(find.text('Tester kill switch')),
    waitingFor: "We'll be back soon",
    timeout: const Duration(seconds: 20),
  );
  final maintenance = _maintenanceVisible(tester);
  final message = _allText(tester).contains('Tester kill switch');
  final home = _browseLabel(tester) != null;
  _result(
    12,
    shot && maintenance && message && !home,
    'maintenance=${maintenance ? 'yes' : 'no'}; '
        'message=${message ? 'yes' : 'no'}; '
        'home=${home ? 'yes' : 'no'}; '
        'shot=${shot ? 'yes' : 'no'}; ${_screenHint(tester)}',
  );
}

Future<void> _forceUpdatePhase(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        _gateVisible(tester) ||
        tester.any(find.text('Update required')) ||
        _updateBlock(tester) != null ||
        _browseLabel(tester) != null ||
        _maintenanceVisible(tester),
    timeout: const Duration(seconds: 20),
  );
  if (_gateVisible(tester)) {
    await tester.tap(find.byKey(const Key('policy-accept-button')));
    await tester.pump(const Duration(milliseconds: 300));
  }
  final shot = await _captureWhen(
    tester,
    '13-force-update',
    () =>
        tester.any(find.text('Update required')) &&
        tester.any(find.byKey(const Key('force-update-screen'))),
    waitingFor: 'Update required',
    timeout: const Duration(seconds: 20),
    // Keeps the activity up while the host reads the widget hierarchy.
    hold: const Duration(seconds: 3),
  );
  final update = _updateBlock(tester);
  final hard = update == 'force-update-screen' ||
      update == 'force-update-button' ||
      update == 'Update required' ||
      update == 'Update on Play Store';
  final home = _browseLabel(tester) != null;
  _result(
    13,
    shot && hard && !home,
    'update=${update ?? 'none'}; home=${home ? 'yes' : 'no'}; '
        'shot=${shot ? 'yes' : 'no'}; ${_screenHint(tester)}',
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
  final shot = await _captureWhen(
    tester,
    '06-airplane',
    () =>
        !_maintenanceVisible(tester) &&
        (_browseLabel(tester) != null ||
            tester.any(find.text('Could not load temples.')) ||
            tester.any(find.text('Retry')) ||
            tester.any(find.text('No temples available yet.')) ||
            tester.any(find.text("You're offline")) ||
            _allText(tester).contains('Showing the offline sample.')),
    waitingFor: 'offline home or Retry',
    timeout: const Duration(seconds: 30),
  );
  final maintenance = _maintenanceVisible(tester);
  final retry = tester.any(find.text('Retry'));
  final error = tester.any(find.text('Could not load temples.'));
  _result(
    6,
    shot && !maintenance,
    'maintenance=${maintenance ? 'yes' : 'no'}; '
        'connectivity=$link; '
        'showed ${_screenHint(tester)}; '
        'no-cache error=${error && retry ? 'yes' : 'no'}; '
        'shot=${shot ? 'yes' : 'no'}',
  );
}
