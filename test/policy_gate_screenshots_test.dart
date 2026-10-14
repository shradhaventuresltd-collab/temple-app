// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';

/// Writes frame A and frame C PNGs when CAPTURE_POLICY_SCREENSHOTS=1.
///
/// Layout is 360×800 dp. Images are saved at 3× (1080 px wide) under
/// docs/screenshots/kan-93/. Flutter tests block HTTP, so the capture loads
/// Lora and Poppins from /tmp/kan93-fonts. The test is skipped in normal runs
/// so CI does not depend on font rasterization.
void main() {
  final capture = Platform.environment['CAPTURE_POLICY_SCREENSHOTS'] == '1';

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = capture;
    if (!capture) return;
    google_fonts_base.httpClient = _LocalFontClient();
    PathProviderPlatform.instance = _FakePathProvider();
  });

  testWidgets('capture frame A and frame C at 360dp', (tester) async {
    const cases = <(String, PolicyGateKind, double)>[
      ('frame-a-360dp-text-scale-1.png', PolicyGateKind.firstLaunch, 1),
      ('frame-a-360dp-text-scale-2.png', PolicyGateKind.firstLaunch, 2),
      ('frame-c-360dp-text-scale-1.png', PolicyGateKind.policyUpdate, 1),
      ('frame-c-360dp-text-scale-2.png', PolicyGateKind.policyUpdate, 2),
    ];

    for (final item in cases) {
      final (name, kind, scale) = item;
      await _pumpGate(tester, kind: kind, textScale: scale);
      // Font loads finish on a later frame. Awaiting them without pumping
      // deadlocks the test binding.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      await _writePng(tester, 'docs/screenshots/kan-93/$name');
    }
  }, skip: !capture);
}

Future<void> _pumpGate(
  WidgetTester tester, {
  required PolicyGateKind kind,
  required double textScale,
}) async {
  const dpr = 3.0;
  tester.view.physicalSize = const Size(360 * dpr, 800 * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('policy-shot'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: PolicyGateColors.saffron,
            primary: PolicyGateColors.saffron,
          ),
          scaffoldBackgroundColor: PolicyGateColors.cream,
        ),
        home: PolicyAcceptanceGate(
          kind: kind,
          onAccept: () async {},
          onOpenUrl: (_) async => true,
          onExit: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _writePng(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('policy-shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

class _LocalFontClient extends http.BaseClient {
  static const _dir = '/tmp/kan93-fonts';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final file = File('$_dir/${request.url.pathSegments.last}');
    if (!file.existsSync()) {
      throw Exception('Missing font file for ${request.url}');
    }
    final bytes = await file.readAsBytes();
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    final directory = Directory('/tmp/kan93-app-support');
    await directory.create(recursive: true);
    return directory.path;
  }
}
