class Temple {
  const Temple({
    required this.name,
    required this.state,
    required this.city,
    required this.deity,
    required this.imageUrl,
    required this.description,
    required this.story,
    required this.location,
    required this.timings,
    required this.specialities,
    required this.latitude,
    required this.longitude,
    this.id = '',
    this.images = const [],
  });

  final String id;
  final String name;
  final String state;
  final String city;
  final String deity;
  final String imageUrl;
  final String description;
  final String story;
  final String location;
  final String timings;
  final List<String> specialities;
  final List<String> images;
  final double latitude;
  final double longitude;

  bool get hasNetworkImage => imageUrl.trim().isNotEmpty;

  /// All available gallery images — [images] array, falling back to [imageUrl].
  List<String> get galleryImages {
    final all = images.where((u) => u.trim().isNotEmpty).toList();
    if (all.isEmpty && hasNetworkImage) return [imageUrl];
    return all;
  }
}
