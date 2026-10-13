/// Licence stored on each `temples/{id}.photos[]` entry.
///
/// Wire values are exact: `CC-BY`, `CC-BY-SA`, `CC0`, `Own`, `Permission`.
/// `CC0` is only the Creative Commons Zero dedication. Generic public-domain
/// text is not this value.
enum PhotoLicence {
  ccBy('CC-BY'),
  ccBySa('CC-BY-SA'),
  cc0('CC0'),
  own('Own'),
  permission('Permission');

  const PhotoLicence(this.wireValue);

  /// Firestore / JSON string.
  final String wireValue;

  /// CC-BY and CC-BY-SA require a non-empty credit. CC0, Own, and Permission
  /// may omit it.
  bool get requiresCredit =>
      this == PhotoLicence.ccBy || this == PhotoLicence.ccBySa;

  String toJson() => wireValue;

  static PhotoLicence? fromJson(Object? raw) {
    if (raw is! String) return null;
    for (final value in PhotoLicence.values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }

  static const List<String> wireValues = [
    'CC-BY',
    'CC-BY-SA',
    'CC0',
    'Own',
    'Permission',
  ];
}
