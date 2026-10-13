import 'package:url_launcher/url_launcher.dart';

/// Opens a hosted policy page in an in-app browser, then an external browser
/// if the in-app view is unavailable.
///
/// Only https URLs are opened. Returns false when the link cannot be opened.
Future<bool> openPolicyUrl(Uri url) async {
  if (url.scheme != 'https') return false;
  try {
    final openedInApp = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (openedInApp) return true;
  } catch (_) {
    // Fall through to the external browser.
  }
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
