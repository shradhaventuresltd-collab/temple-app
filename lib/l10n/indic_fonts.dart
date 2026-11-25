import 'package:flutter/material.dart';

/// System Noto families for the seven Indic scripts. Poppins stays the
/// primary family for Latin. Nothing is downloaded at runtime.
const indicFontFamilyFallback = <String>[
  'Noto Sans Devanagari',
  'Noto Sans Kannada',
  'Noto Sans Malayalam',
  'Noto Sans Tamil',
  'Noto Sans Telugu',
  'Noto Sans Bengali',
  'Noto Sans Oriya',
  'Noto Sans',
];

TextTheme withIndicFallback(TextTheme theme) {
  return theme.apply(fontFamilyFallback: indicFontFamilyFallback);
}
