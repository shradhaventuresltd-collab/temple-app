import 'package:temple_app/models/photo_licence.dart';

/// Hard cap for `temples/{id}.photos`.
const int kMaxTemplePhotos = 12;

/// `image_picker` multi-select cap for one Add photo action.
const int kMaxPhotosPerPick = 10;

const int kMaxPhotoUrlLength = 2000;
const int kMaxPhotoCreditLength = 200;

/// One entry in `photos: [{url, credit, licence, order}]`.
///
/// [licence] is null only for an editor draft that still needs a choice.
/// Firestore writes always include a [PhotoLicence].
class TemplePhoto {
  const TemplePhoto({
    required this.url,
    required this.credit,
    required this.licence,
    required this.order,
  });

  final String url;
  final String credit;
  final PhotoLicence? licence;
  final int order;

  factory TemplePhoto.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    return TemplePhoto(
      url: json['url'] as String? ?? '',
      credit: json['credit'] as String? ?? '',
      licence: PhotoLicence.fromJson(json['licence']),
      order: orderRaw is int ? orderRaw : 0,
    );
  }

  Map<String, dynamic> toJson() {
    final chosen = licence;
    if (chosen == null) {
      throw StateError('Each photo needs a licence.');
    }
    return {
      'url': url,
      'credit': credit,
      'licence': chosen.toJson(),
      'order': order,
    };
  }

  TemplePhoto copyWith({
    String? url,
    String? credit,
    PhotoLicence? licence,
    int? order,
    bool clearLicence = false,
  }) {
    return TemplePhoto(
      url: url ?? this.url,
      credit: credit ?? this.credit,
      licence: clearLicence ? null : (licence ?? this.licence),
      order: order ?? this.order,
    );
  }
}

/// Why a photo cannot be written yet, or null when it is valid.
String? templePhotoValidationError(TemplePhoto photo) {
  final url = photo.url.trim();
  if (url.isEmpty) return 'Each photo needs an uploaded file.';
  if (url.length > kMaxPhotoUrlLength) {
    return 'Photo URL must be $kMaxPhotoUrlLength characters or fewer.';
  }
  final chosen = photo.licence;
  if (chosen == null) return 'Each photo needs a licence.';
  if (photo.credit.length > kMaxPhotoCreditLength) {
    return 'Photo credit must be $kMaxPhotoCreditLength characters or fewer.';
  }
  if (chosen.requiresCredit && photo.credit.trim().isEmpty) {
    return 'Credit is required for ${chosen.wireValue}.';
  }
  return null;
}

/// Mirrors written in the same payload as [photos].
class TemplePhotoMirror {
  const TemplePhotoMirror({
    required this.photos,
    required this.imageUrl,
    required this.images,
  });

  /// Sorted by [TemplePhoto.order], then reindexed from 0.
  final List<TemplePhoto> photos;

  /// Order-0 url, or empty when there are no photos.
  final String imageUrl;

  /// Urls in order. Empty when there are no photos.
  final List<String> images;
}

/// Sorts [photos] by [TemplePhoto.order], caps the list, and derives
/// `imageUrl` / `images` from that order. Order 0 is the cover.
TemplePhotoMirror deriveTemplePhotoMirror(List<TemplePhoto> photos) {
  if (photos.length > kMaxTemplePhotos) {
    throw StateError('A temple can have at most $kMaxTemplePhotos photos.');
  }

  final indexed = [for (var i = 0; i < photos.length; i++) i];
  indexed.sort((a, b) {
    final byOrder = photos[a].order.compareTo(photos[b].order);
    if (byOrder != 0) return byOrder;
    return a.compareTo(b);
  });

  final normalized = <TemplePhoto>[];
  for (var slot = 0; slot < indexed.length; slot++) {
    final source = photos[indexed[slot]];
    final photo = TemplePhoto(
      url: source.url.trim(),
      credit: source.credit.trim(),
      licence: source.licence,
      order: slot,
    );
    final error = templePhotoValidationError(photo);
    if (error != null) throw StateError(error);
    normalized.add(photo);
  }

  return TemplePhotoMirror(
    photos: normalized,
    imageUrl: normalized.isEmpty ? '' : normalized.first.url,
    images: [for (final photo in normalized) photo.url],
  );
}

/// Storage object path for an admin photo upload.
String templePhotoStoragePath({
  required String docId,
  required int timestamp,
  required String extension,
}) {
  final id = docId.trim();
  if (id.isEmpty || id.contains('/')) {
    throw StateError('Temple id is missing.');
  }
  final ext = extension.trim().toLowerCase().replaceAll(RegExp(r'^\.'), '');
  if (ext.isEmpty || !RegExp(r'^[a-z0-9]+$').hasMatch(ext)) {
    throw StateError('Photo file extension is not supported.');
  }
  return 'temples/$id/$timestamp.$ext';
}
