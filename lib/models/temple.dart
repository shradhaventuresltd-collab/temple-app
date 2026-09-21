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

  /// Reads a `temples/{id}` document using the same field names as Seed.
  ///
  /// Location is stored as `address` (with a `location` fallback for older docs).
  factory Temple.fromMap(String id, Map<String, dynamic> data) {
    return Temple(
      id: id,
      name: data['name'] as String? ?? '',
      state: data['state'] as String? ?? '',
      city: data['city'] as String? ?? '',
      deity: data['deity'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      story: data['story'] as String? ?? '',
      location: data['address'] as String? ?? data['location'] as String? ?? '',
      timings: data['timings'] as String? ?? '',
      specialities: _stringList(data['specialities']),
      images: _stringList(data['images']),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Firestore fields used by Seed, Admin CMS, and [TempleService] reads.
  ///
  /// Does not write `createdAt` — that is a server timestamp on create only.
  Map<String, dynamic> toFirestoreData({
    String? documentId,
    bool includeImages = true,
  }) {
    final docId = documentId ?? id;
    final data = <String, dynamic>{
      if (docId.isNotEmpty) 'id': docId,
      'name': name,
      'state': state,
      'city': city,
      'deity': deity,
      'description': description,
      'story': story,
      'imageUrl': imageUrl,
      'address': location,
      'latitude': latitude,
      'longitude': longitude,
      'timings': timings,
      'specialities': specialities,
    };
    if (includeImages) {
      data['images'] = images.where((u) => u.trim().isNotEmpty).toList();
    }
    return data;
  }

  Temple copyWith({
    String? id,
    String? name,
    String? state,
    String? city,
    String? deity,
    String? imageUrl,
    String? description,
    String? story,
    String? location,
    String? timings,
    List<String>? specialities,
    List<String>? images,
    double? latitude,
    double? longitude,
  }) {
    return Temple(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      city: city ?? this.city,
      deity: deity ?? this.deity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      story: story ?? this.story,
      location: location ?? this.location,
      timings: timings ?? this.timings,
      specialities: specialities ?? this.specialities,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
