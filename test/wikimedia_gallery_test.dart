import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/utils/wikimedia_gallery.dart';

void main() {
  test('legacy commons images[] map to a 1280px thumb', () {
    final cases =
        jsonDecode(
              File(
                'scripts/fixtures/wikimedia_gallery_cap_cases.json',
              ).readAsStringSync(),
            )
            as List;
    expect(cases, isNotEmpty);
    for (final raw in cases) {
      final row = Map<String, dynamic>.from(raw as Map);
      final name = row['name'] as String;
      final capped = capLegacyWikimediaImage(row['url'] as String);
      expect(capped.url, row['expect'], reason: name);
      expect(capped.reason, row['reason'], reason: name);
      expect(
        capLegacyWikimediaImageUrl(row['url'] as String),
        row['expect'],
        reason: name,
      );
      if (row['reason'] == null) {
        expect(capped.url, contains('/1280px-'), reason: name);
      }
    }
    expect(kWikimediaGalleryCapPx, 1280);
  });

  test('detail frames cap a commons original and keep the stored url', () {
    const original =
        'https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg';
    const thumb =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Keesara_gutta_main_temple_gate.jpg/1280px-Keesara_gutta_main_temple_gate.jpg';
    const gallery = 'https://example.com/keesara_1080_g2.jpg';
    final temple = _temple(original);
    final frame = detailGalleryFrames(temple).single;
    expect(frame.sourceUrl, original);
    expect(frame.displayUrl, thumb);
    expect(
      detailGalleryFrames(temple, fullSizeIndexes: {0}).single.displayUrl,
      original,
    );
    expect(
      visiblePhotoCredit(temple.photos, frame.sourceUrl),
      'Ada · CC BY 4.0',
    );

    final withGallery = _temple(original, galleryUrl: gallery);
    expect(detailGalleryFrames(withGallery).single.displayUrl, gallery);
    expect(detailGalleryFrames(withGallery).single.sourceUrl, original);

    const wide =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Keesara_gutta_main_temple_gate.jpg/1920px-Keesara_gutta_main_temple_gate.jpg';
    expect(detailGalleryFrames(_temple(wide)).single.displayUrl, thumb);
    expect(
      detailGalleryFrames(
        _temple(wide),
        fullSizeIndexes: {0},
      ).single.displayUrl,
      wide,
    );

    const svg =
        'https://upload.wikimedia.org/wikipedia/commons/8/84/Example.svg';
    expect(detailGalleryFrames(_temple(svg)).single.displayUrl, svg);

    const small =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Keesara_gutta_main_temple_gate.jpg/500px-Keesara_gutta_main_temple_gate.jpg';
    expect(detailGalleryFrames(_temple(small)).single.displayUrl, small);

    const storage =
        'https://storage.googleapis.com/bucket/temples/shore/01.jpg';
    expect(detailGalleryFrames(_temple(storage)).single.displayUrl, storage);
  });
}

Temple _temple(String original, {String? galleryUrl}) {
  return Temple(
    name: 'Keesaragutta Temple',
    state: 'Telangana',
    city: 'Keesara',
    deity: 'Shiva',
    imageUrl: original,
    images: [original],
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Temple Street',
    timings: '6:00 AM–8:00 PM daily.',
    specialities: const ['Stone gateway'],
    photos: [
      TemplePhoto(
        url: original,
        credit: 'Ada · CC BY 4.0',
        licence: PhotoLicence.ccBy,
        order: 0,
        galleryUrl: galleryUrl,
      ),
    ],
    latitude: 17.5,
    longitude: 78.6,
  );
}
