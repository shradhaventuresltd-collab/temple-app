import 'package:temple_app/models/photo_licence.dart';

/// Hard cap for `temples/{id}.photos`.
const int kMaxTemplePhotos = 12;

/// `image_picker` multi-select cap for one Add photo action.
const int kMaxPhotosPerPick = 10;

const int kMaxPhotoUrlLength = 2000;
const int kMaxPhotoCreditLength = 200;

/// One entry in `photos: [{url, credit, licence, order, thumbUrl?}]`.
///
/// [licence] is null only for an editor draft that still needs a choice.
/// Firestore writes always include a [PhotoLicence]. [thumbUrl] is the
/// download URL of the `_480` object, stored after upload. It is omitted
/// when this photo has no thumb yet.
class TemplePhoto {
  const TemplePhoto({
    required this.url,
    required this.credit,
    required this.licence,
    required this.order,
    this.thumbUrl,
  });

  final String url;
  final String credit;
  final PhotoLicence? licence;
  final int order;

  /// Real download URL of the list thumb. Null until one has been stored.
  final String? thumbUrl;

  factory TemplePhoto.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    final thumb = json['thumbUrl'];
    return TemplePhoto(
      url: json['url'] as String? ?? '',
      credit: json['credit'] as String? ?? '',
      licence: PhotoLicence.fromJson(json['licence']),
      order: orderRaw is int ? orderRaw : 0,
      thumbUrl: thumb is String && thumb.trim().isNotEmpty
          ? thumb.trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final chosen = licence;
    if (chosen == null) {
      throw StateError('Each photo needs a licence.');
    }
    final thumb = thumbUrl?.trim() ?? '';
    return {
      'url': url,
      'credit': credit,
      'licence': chosen.toJson(),
      'order': order,
      if (thumb.isNotEmpty) 'thumbUrl': thumb,
    };
  }

  TemplePhoto copyWith({
    String? url,
    String? credit,
    PhotoLicence? licence,
    int? order,
    String? thumbUrl,
    bool clearLicence = false,
    bool clearThumbUrl = false,
  }) {
    return TemplePhoto(
      url: url ?? this.url,
      credit: credit ?? this.credit,
      licence: clearLicence ? null : (licence ?? this.licence),
      order: order ?? this.order,
      thumbUrl: clearThumbUrl ? null : (thumbUrl ?? this.thumbUrl),
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
  if (!url.startsWith('https://')) {
    return 'Photo URL must start with https://.';
  }
  if (photo.order < 0 || photo.order > 11) {
    return 'Photo order must be between 0 and 11.';
  }
  final chosen = photo.licence;
  if (chosen == null) return 'Each photo needs a licence.';
  if (photo.credit.length > kMaxPhotoCreditLength) {
    return 'Photo credit must be $kMaxPhotoCreditLength characters or fewer.';
  }
  if (chosen.requiresCredit && photo.credit.trim().isEmpty) {
    return 'Credit is required for ${chosen.wireValue}.';
  }
  final thumb = photo.thumbUrl?.trim() ?? '';
  if (thumb.isNotEmpty) {
    if (thumb.length > kMaxPhotoUrlLength) {
      return 'Photo thumbnail URL must be $kMaxPhotoUrlLength characters or fewer.';
    }
    if (!thumb.startsWith('https://')) {
      return 'Photo thumbnail URL must start with https://.';
    }
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
      thumbUrl: source.thumbUrl?.trim(),
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

/// Credit or caption shown under a gallery frame.
///
/// CC-BY and CC-BY-SA show their attribution. A stored credit that records
/// the frame as a historical print is also shown, so a public-domain
/// lithograph is not presented as a photograph. Other CC0, Own, and
/// Permission credits, a blank credit, and a URL with no matching photo
/// stay silent. The detail screen calls this with the visible frame URL.
String? visiblePhotoCredit(List<TemplePhoto> photos, String url) {
  for (final photo in photos) {
    if (photo.url != url) continue;
    final credit = photo.credit.trim();
    if (credit.isEmpty) return null;
    if (photo.licence?.requiresCredit == true) return credit;
    if (_isHistoricalPrintCaption(credit)) return credit;
    return null;
  }
  return null;
}

bool _isHistoricalPrintCaption(String credit) {
  final lower = credit.toLowerCase();
  return lower.contains('lithograph') || lower.contains('1847 print');
}

/// Year 1500–2099 sitting next to lithograph or print wording.
///
/// An unrelated 4-digit number in the credit, such as an accession or a
/// catalogue id, is not a caption year.
String? _printYear(String credit) {
  final match = RegExp(
    r'\b(1[5-9]\d{2}|20\d{2})\b\s*(?:lithographs?|lithographic|prints?)\b'
    r'|'
    r'\b(?:lithographs?|lithographic|prints?)\b'
    r'(?:\s*[\(,:\-–]|\s+(?:of|from|circa|c\.|ca\.|dated|in)\s+)'
    r'\s*(1[5-9]\d{2}|20\d{2})\b',
    caseSensitive: false,
  ).firstMatch(credit);
  final year = match?.group(1) ?? match?.group(2);
  if (year == null) return null;
  final value = int.tryParse(year);
  if (value == null || value < 1500 || value > 2099) return null;
  return year;
}

/// Short label for a cover that is a historical print, not a photograph.
///
/// Browse cards and the home collage use this so a lithograph is not shown
/// as a photo of the temple. The year comes from the credit text. A
/// lithograph credit with no year is labelled "Lithograph".
String? historicalCoverCaption(List<TemplePhoto> photos, String url) {
  for (final photo in photos) {
    if (photo.url != url) continue;
    final credit = photo.credit.trim();
    if (!_isHistoricalPrintCaption(credit)) return null;
    final year = _printYear(credit);
    if (year == null) return 'Lithograph';
    return 'Lithograph, $year';
  }
  return null;
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
