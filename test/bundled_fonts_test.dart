import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/bundled_fonts.dart';

void main() {
  testWidgets('Poppins and Lora OFL texts are registered', (tester) async {
    registerBundledFontLicenses();

    final poppins = await rootBundle.loadString(poppinsLicenseAsset);
    final lora = await rootBundle.loadString(loraLicenseAsset);
    expect(poppins, contains('SIL OPEN FONT LICENSE'));
    expect(lora, contains('SIL OPEN FONT LICENSE'));
    expect(poppins, isNot(lora));

    final entries = await LicenseRegistry.licenses.toList();
    final poppinsEntry = entries
        .whereType<LicenseEntryWithLineBreaks>()
        .singleWhere((entry) => entry.packages.contains('Poppins'));
    final loraEntry = entries
        .whereType<LicenseEntryWithLineBreaks>()
        .singleWhere((entry) => entry.packages.contains('Lora'));

    expect(poppinsEntry.text, poppins);
    expect(loraEntry.text, lora);
    expect(poppinsEntry.packages, contains('Poppins'));
    expect(loraEntry.packages, contains('Lora'));
  });

  test('PlatformDispatcher.onError logs a font-loading failure', () {
    final printed = <String>[];
    final forwarded = <Object>[];
    final previousDebugPrint = debugPrint;
    final previousOnError = PlatformDispatcher.instance.onError;
    debugPrint = (String? message, {int? wrapWidth}) {
      printed.add(message ?? '');
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      forwarded.add(error);
      return true;
    };
    try {
      installFontLoadErrorLogging();
      final handler = PlatformDispatcher.instance.onError;
      expect(handler, isNotNull);

      const fontError =
          'Failed to load font with url: https://fonts.gstatic.com/poppins.ttf';
      final fontHandled = handler!(
        Exception(fontError),
        StackTrace.fromString('#0 loadFontIfNecessary\n'),
      );
      expect(fontHandled, isTrue);
      expect(printed.join('\n'), contains('Font load failed'));
      expect(printed.join('\n'), contains(fontError));
      expect(printed.join('\n'), contains('#0 loadFontIfNecessary'));
      expect(forwarded, hasLength(1));

      printed.clear();
      final otherHandled = handler(StateError('not-a-font'), StackTrace.empty);
      expect(otherHandled, isTrue);
      expect(printed, isEmpty);
      expect(forwarded, hasLength(2));
    } finally {
      debugPrint = previousDebugPrint;
      PlatformDispatcher.instance.onError = previousOnError;
    }
  });
}
