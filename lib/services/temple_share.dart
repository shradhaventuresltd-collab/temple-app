import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// THE switch for the share button (open decision with Sanu).
///
/// false: the button reads "Share" and opens the system share sheet.
/// true:  when WhatsApp is installed the button reads "Share on WhatsApp"
///        and opens it directly (whatsapp://, then wa.me), falling back to
///        the share sheet, then a SnackBar. Turning this on also needs the
///        WhatsApp `<queries>` entries in AndroidManifest.xml, or Android 11+
///        never reports WhatsApp as installed;
///        test/share_whatsapp_manifest_test.dart keeps the two in step.
const bool kShareDirectToWhatsApp = false;

/// Play listing linked from a shared place. Always the production listing,
/// also from the demo build, so a recipient lands on the public app.
const String kTempleSharePlayUrl =
    'https://play.google.com/store/apps/details?id=$kPlayStorePackageName';

/// Where a share goes: straight to WhatsApp or the system share sheet.
enum ShareTarget { whatsapp, system }

/// Share text for [temple]: name, town and state, then the Play link.
String templeShareText(Temple temple) {
  return ShareStrings.templeDetailShareText(
    temple.name,
    temple.city,
    temple.state,
    kTempleSharePlayUrl,
  );
}

/// Opens the system share sheet. Tests pass a fake.
///
/// No package targeting: WhatsApp shows where Android's share ranking puts
/// it. Text only, so no file provider use and no new permissions.
abstract class TempleSharer {
  const TempleSharer();

  static TempleSharer instance = const SharePlusTempleSharer();

  /// True when the sheet opened (whatever the user picked, or a cancel).
  /// False or a throw: it could not open.
  Future<bool> shareText(String text, {String? subject});
}

class SharePlusTempleSharer extends TempleSharer {
  const SharePlusTempleSharer();

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    // Any result (shared, dismissed, or unknown) means the sheet opened;
    // a failure to open throws.
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    return true;
  }
}

/// Direct WhatsApp hand-off. Tests pass a fake, or fake
/// `UrlLauncherPlatform` under [UrlLauncherWhatsAppLauncher].
abstract class WhatsAppLauncher {
  const WhatsAppLauncher();

  static WhatsAppLauncher instance = const UrlLauncherWhatsAppLauncher();

  /// Whether WhatsApp can take a `whatsapp://` link. Never throws.
  Future<bool> isInstalled();

  /// Opens WhatsApp with [text]. True when it opened. Never throws.
  Future<bool> open(String text);
}

class UrlLauncherWhatsAppLauncher extends WhatsAppLauncher {
  const UrlLauncherWhatsAppLauncher();

  static Uri appUri(String text) =>
      Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');

  static Uri webUri(String text) =>
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

  @override
  Future<bool> isInstalled() async {
    try {
      return await canLaunchUrl(appUri(''));
    } catch (e) {
      debugPrint('WhatsApp check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> open(String text) async {
    for (final uri in [appUri(text), webUri(text)]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (e) {
        debugPrint('WhatsApp launch failed (${uri.scheme}): $e');
      }
    }
    return false;
  }
}
