import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:temple_app/config/build_flags.dart';

/// Detailed exception text is for debug builds only.
///
/// Release and profile binaries, including demo and admin-tool APKs, use
/// [productionReleaseErrorWidget]. A raw stack on the demo APK was the grey
/// screen testers saw. [demoBuild] and [adminTools] stay in the signature so
/// callers still pass the Play and demo defines. Neither flag turns the
/// stack back on outside debug. The Play AAB script is unchanged.
bool showDetailedReleaseError({
  required bool debug,
  required bool demoBuild,
  required bool adminTools,
}) {
  // Release and profile never paint a stack, including when demo or admin
  // tools are compiled in. Both branches return [debug] so those defines
  // cannot turn the stack back on.
  if (demoBuild || adminTools) return debug;
  return debug;
}

/// Shows a build failure instead of Flutter's blank grey release box.
///
/// [installReleaseErrorWidget] always replaces [ErrorWidget.builder]. The
/// detailed exception and stack are installed only when
/// [showDetailedReleaseError] is true (debug). Release and profile builds
/// get the branded fallback, with no exception text and no stack.
void installReleaseErrorWidget({
  bool? debug,
  bool? demoBuild,
  bool? adminTools,
}) {
  final detailed = showDetailedReleaseError(
    debug: debug ?? kDebugMode,
    demoBuild: demoBuild ?? kDemoBuild,
    adminTools: adminTools ?? kEnableAdminToolsDefine,
  );
  ErrorWidget.builder = detailed
      ? releaseErrorWidget
      : productionReleaseErrorWidget;
}

/// Builder installed for debug, demo, and admin-tool builds.
///
/// Flutter's default [ErrorWidget.builder] assigns [ErrorWidget.message]
/// only inside an `assert`, so a release build paints a blank grey
/// [RenderErrorBox] (`#F0C0C0C0`) and the exception stays in logcat.
Widget releaseErrorWidget(FlutterErrorDetails details) {
  return ErrorWidget.withDetails(message: releaseErrorMessage(details));
}

/// Branded fallback for the production AAB. No exception text and no stack.
///
/// Flutter reports the error once before it builds this widget. Reporting
/// again here would log the same failure a second time.
Widget productionReleaseErrorWidget(FlutterErrorDetails details) {
  return const BrandedReleaseErrorScreen();
}

/// Exception text plus a short stack, safe to paint from [ErrorWidget].
String releaseErrorMessage(FlutterErrorDetails details) {
  String exception;
  try {
    exception = details.exceptionAsString();
  } catch (_) {
    exception = 'Error';
  }
  final stack = details.stack?.toString();
  if (stack == null || stack.isEmpty) return exception;
  final head = stack.split('\n').take(6).join('\n');
  if (head.isEmpty) return exception;
  return '$exception\n$head';
}

/// Cream and saffron fallback. It does not read [FlutterErrorDetails].
class BrandedReleaseErrorScreen extends StatelessWidget {
  const BrandedReleaseErrorScreen({super.key});

  static const String message = 'Something went wrong';
  static const String appName = 'Temple Directory India';

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFBF2),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFF8F00),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6D4C41),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
