import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const String poppinsLicenseAsset = 'assets/google_fonts/Poppins-OFL.txt';
const String loraLicenseAsset = 'assets/google_fonts/Lora-OFL.txt';

/// Registers the bundled Poppins and Lora OFL texts for showLicensePage.
void registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const <String>[
      'Poppins',
    ], await rootBundle.loadString(poppinsLicenseAsset));
    yield LicenseEntryWithLineBreaks(const <String>[
      'Lora',
    ], await rootBundle.loadString(loraLicenseAsset));
  });
}

/// True for the exceptions google_fonts rethrows from its load future.
///
/// google_fonts starts that future and attaches `.then` with no
/// `catchError`, so a miss becomes an unhandled async error.
bool isFontLoadError(Object error) {
  final text = error.toString();
  return text.contains('Failed to load font') ||
      text.contains('allowRuntimeFetching is false but font') ||
      text.contains('Invalid fontUrl') ||
      text.contains('did not match expected length and checksum');
}

/// Logs font-load failures that arrive as unhandled async errors.
///
/// Call after [WidgetsFlutterBinding.ensureInitialized], which may already
/// own [PlatformDispatcher.onError]. Font failures are debugPrinted, then
/// forwarded to that previous handler.
void installFontLoadErrorLogging() {
  final previous = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (isFontLoadError(error)) {
      debugPrint('Font load failed: $error\n$stack');
    }
    final handler = previous;
    if (handler != null) return handler(error, stack);
    return false;
  };
}
