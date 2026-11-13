import 'package:share_plus/share_plus.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/app_update.dart';

/// Play listing linked from a shared place. Always the production listing,
/// also from the demo build, so a recipient lands on the public app.
const String kTempleSharePlayUrl =
    'https://play.google.com/store/apps/details?id=$kPlayStorePackageName';

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

  Future<void> shareText(String text, {String? subject});
}

class SharePlusTempleSharer extends TempleSharer {
  const SharePlusTempleSharer();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}
