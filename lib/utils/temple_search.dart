import 'package:temple_app/models/temple.dart';

/// How long a typed query waits before the temple grid refreshes.
const Duration templeSearchDebounce = Duration(milliseconds: 300);

/// Case-insensitive partial match of [query] against public directory text.
///
/// An empty or whitespace-only query matches every temple. Otherwise the query
/// is trimmed, lowercased, and split on whitespace. Each word must occur in the
/// combined name, city, state, deity, and address ([Temple.location]). Story
/// and description are not searched.
bool templeMatchesQuery(Temple temple, String query) {
  final words = _queryWords(query);
  if (words.isEmpty) return true;
  final haystack = _haystack(temple);
  return words.every(haystack.contains);
}

/// Temples that match [state], [deity], and [query] together.
///
/// A null [state] or [deity] does not constrain that field (exact match when
/// set, same as the drawer chips). [query] uses [templeMatchesQuery]. The
/// order of [temples] is preserved.
List<Temple> filterTemples(
  List<Temple> temples, {
  String? state,
  String? deity,
  String query = '',
}) {
  return [
    for (final temple in temples)
      if ((state == null || temple.state == state) &&
          (deity == null || temple.deity == deity) &&
          templeMatchesQuery(temple, query))
        temple,
  ];
}

List<String> _queryWords(String query) {
  final normalized = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return const [];
  return normalized.split(' ');
}

String _haystack(Temple temple) {
  return [temple.name, temple.city, temple.state, temple.deity, temple.location]
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
