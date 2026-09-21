import 'package:temple_app/models/temple.dart';

/// Raw Admin CMS form values before they are mapped onto [Temple].
class TempleDraft {
  const TempleDraft({
    required this.name,
    required this.state,
    required this.city,
    required this.deity,
    required this.location,
    required this.description,
    required this.story,
    required this.timings,
    required this.specialitiesText,
    required this.imageUrl,
    required this.imagesText,
    required this.latitudeText,
    required this.longitudeText,
    this.id = '',
  });

  final String id;
  final String name;
  final String state;
  final String city;
  final String deity;
  final String location;
  final String description;
  final String story;
  final String timings;
  final String specialitiesText;
  final String imageUrl;
  final String imagesText;
  final String latitudeText;
  final String longitudeText;
}

/// Outcome of [validateTempleDraft].
class TempleFormValidation {
  const TempleFormValidation({this.temple, this.errors = const {}});

  /// Set when [isValid] is true.
  final Temple? temple;

  /// Field key → message. Keys match the Admin form (`name`, `state`, …).
  final Map<String, String> errors;

  bool get isValid => errors.isEmpty && temple != null;
}

/// Splits specialities / extra image URLs on newlines, commas, or semicolons.
List<String> parseTempleStringList(String raw) {
  return raw
      .split(RegExp(r'[\n,;]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Validates core temple fields used by the app. Empty optional fields are
/// stored as empty strings / `0.0` coordinates, matching bundled sample docs.
TempleFormValidation validateTempleDraft(TempleDraft draft) {
  final errors = <String, String>{};

  final name = draft.name.trim();
  final state = draft.state.trim();
  final city = draft.city.trim();
  final deity = draft.deity.trim();
  final location = draft.location.trim();

  if (name.isEmpty) errors['name'] = 'Name is required.';
  if (state.isEmpty) errors['state'] = 'State is required.';
  if (city.isEmpty) errors['city'] = 'City is required.';
  if (deity.isEmpty) errors['deity'] = 'Deity is required.';
  if (location.isEmpty) errors['location'] = 'Location / address is required.';

  final latitude = _parseCoordinate(
    draft.latitudeText,
    errors: errors,
    field: 'latitude',
    label: 'latitude',
    min: -90,
    max: 90,
  );
  final longitude = _parseCoordinate(
    draft.longitudeText,
    errors: errors,
    field: 'longitude',
    label: 'longitude',
    min: -180,
    max: 180,
  );

  if (errors.isNotEmpty) {
    return TempleFormValidation(errors: errors);
  }

  final imageUrl = draft.imageUrl.trim();
  var images = parseTempleStringList(draft.imagesText);
  if (images.isEmpty && imageUrl.isNotEmpty) {
    images = [imageUrl];
  }

  return TempleFormValidation(
    temple: Temple(
      id: draft.id.trim(),
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: imageUrl,
      description: draft.description.trim(),
      story: draft.story.trim(),
      location: location,
      timings: draft.timings.trim(),
      specialities: parseTempleStringList(draft.specialitiesText),
      images: images,
      latitude: latitude,
      longitude: longitude,
    ),
  );
}

double _parseCoordinate(
  String raw, {
  required Map<String, String> errors,
  required String field,
  required String label,
  required double min,
  required double max,
}) {
  final text = raw.trim();
  if (text.isEmpty) return 0;

  final value = double.tryParse(text);
  if (value == null) {
    errors[field] = 'Enter a valid $label.';
    return 0;
  }
  if (value < min || value > max) {
    errors[field] =
        '$label must be between ${min.toInt()} and ${max.toInt()}.';
    return 0;
  }
  return value;
}
