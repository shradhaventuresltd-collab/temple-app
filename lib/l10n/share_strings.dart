/// Copy for sharing a place from the detail screen (Ux SHARE-SPEC.md).
///
/// These stay English on purpose. Only the share-unavailable snackbar is
/// in the ARBs. The button label, tooltip, and share text are a later pass.
abstract final class ShareStrings {
  /// l10n key: [templeDetailShareButtonLabel]
  ///
  /// The label when sharing goes through the system share sheet.
  static const templeDetailShareButtonLabel = 'Share';

  /// l10n key: [templeDetailShareOnWhatsAppLabel]
  ///
  /// The label when the button opens WhatsApp directly (only with
  /// `kShareDirectToWhatsApp` on and WhatsApp installed). "WhatsApp" is a
  /// product name; keep it untranslated.
  static const templeDetailShareOnWhatsAppLabel = 'Share on WhatsApp';

  /// l10n key: [templeDetailShareTooltip]
  ///
  /// Long-press tooltip and the TalkBack hint.
  static const templeDetailShareTooltip =
      "Shares this place's name and an app link";

  /// l10n key: [templeDetailShareUnavailable]
  ///
  /// SnackBar when neither WhatsApp nor the share sheet could open.
  static const templeDetailShareUnavailable =
      "Couldn't open sharing on this device.";

  /// l10n key: [templeDetailShareText]
  ///
  /// Future ICU message with `{name}`, `{town}`, `{state}` and `{playUrl}`
  /// placeholders. [playUrl] is passed through untranslated.
  ///
  /// ```
  /// {name}
  /// {town}, {state}
  /// Found on Temple Directory India: {playUrl}
  /// ```
  /// A blank [town], or a town equal to [state], is left out with its comma;
  /// a blank [state] leaves just the town; both blank drop the line. The ARB
  /// move needs a `select` (or a pre-joined place placeholder) for that.
  /// The same neutral template is used for every tradition.
  static String templeDetailShareText(
    String name,
    String town,
    String state,
    String playUrl,
  ) {
    final cleanTown = town.trim();
    final cleanState = state.trim();
    final place = [
      if (cleanTown.isNotEmpty &&
          cleanTown.toLowerCase() != cleanState.toLowerCase())
        cleanTown,
      if (cleanState.isNotEmpty) cleanState,
    ].join(', ');
    return [
      if (name.trim().isNotEmpty) name.trim(),
      if (place.isNotEmpty) place,
      'Found on Temple Directory India: $playUrl',
    ].join('\n');
  }
}
