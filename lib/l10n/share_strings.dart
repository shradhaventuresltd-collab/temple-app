/// Copy for sharing a place from the detail screen.
///
/// Main does not yet ship generated l10n (the i18n work is on a separate
/// branch). These names are the future ARB keys and the values are the
/// English strings, following `pin_precision_strings.dart`, so the ARB pass
/// can swap these lookups for `AppLocalizations` without renaming.
abstract final class ShareStrings {
  /// l10n key: [templeDetailShareButtonLabel]
  static const templeDetailShareButtonLabel = 'Share';

  /// l10n key: [templeDetailShareTooltip]
  static const templeDetailShareTooltip = 'Share this place';

  /// l10n key: [templeDetailShareText]
  ///
  /// Future ICU message with `{name}`, `{town}`, `{state}` and `{playUrl}`
  /// placeholders. [playUrl] is passed through untranslated.
  ///
  /// A blank [town] or [state] is left out with its comma, so the place line
  /// never dangles ("Madurai, Tamil Nadu", "Madurai", "Tamil Nadu", or no
  /// place line at all). The ARB move needs a `select` (or a pre-joined
  /// place placeholder) to keep that behaviour.
  static String templeDetailShareText(
    String name,
    String town,
    String state,
    String playUrl,
  ) {
    final place = [
      town.trim(),
      state.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    final lines = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      if (place.isNotEmpty) place,
      '',
      "Explore India's sacred places on Temple Directory India:",
      playUrl,
    ];
    return lines.join('\n');
  }
}
