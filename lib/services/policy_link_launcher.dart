import 'package:url_launcher/url_launcher.dart';

/// Opens a hosted policy page in an in-app browser.
///
/// Uses [LaunchMode.inAppBrowserView] (Android Custom Tabs, or the platform
/// in-app browser view). Only https URLs are opened. Returns false when the
/// link cannot be opened.
Future<bool> openPolicyUrl(Uri url) async {
  if (url.scheme != 'https') return false;
  try {
    return await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    return false;
  }
}
