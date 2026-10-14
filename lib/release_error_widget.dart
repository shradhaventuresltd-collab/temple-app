import 'package:flutter/widgets.dart';

/// Shows the exception text on a release error screen.
///
/// Flutter's default [ErrorWidget.builder] assigns [ErrorWidget.message]
/// only inside an `assert`, so a release build paints a blank grey
/// [RenderErrorBox] (`#F0C0C0C0`) and the exception stays in logcat.
void installReleaseErrorWidget() {
  ErrorWidget.builder = releaseErrorWidget;
}

/// Builder installed by [installReleaseErrorWidget].
Widget releaseErrorWidget(FlutterErrorDetails details) {
  return ErrorWidget.withDetails(message: releaseErrorMessage(details));
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
