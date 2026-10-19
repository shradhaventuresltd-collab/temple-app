import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/detail_honesty.dart';

Temple _temple({
  required String original,
  String? galleryUrl,
  String? thumbUrl,
}) {
  return Temple(
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
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
        thumbUrl: thumbUrl,
        galleryUrl: galleryUrl,
      ),
    ],
    latitude: 12.6,
    longitude: 80.2,
  );
}

void main() {
  const original = 'https://example.com/full.jpg';
  const gallery = 'https://example.com/full_1080_g2.jpg';
  const thumb = 'https://example.com/full_480_g2.jpg';

  test('detail frames use galleryUrl and credits stay on the original', () {
    final temple = _temple(original: original, galleryUrl: gallery, thumbUrl: thumb);
    final frames = detailGalleryFrames(temple);
    expect(frames.single.displayUrl, gallery);
    expect(frames.single.sourceUrl, original);
    expect(
      detailGalleryFrames(temple, fullSizeIndexes: {0}).single.displayUrl,
      original,
    );
    expect(
      visiblePhotoCredit(temple.photos, frames.single.sourceUrl),
      'Ada · CC BY 4.0',
    );
    expect(detailGalleryZoomWantsOriginal(1.5), isFalse);
    expect(detailGalleryZoomWantsOriginal(1.51), isTrue);
    expect(
      coverThumbFor({
        'imageUrl': original,
        'images': [original],
        'photos': [
          {
            'url': original,
            'thumbUrl': thumb,
            'galleryUrl': gallery,
            'licence': 'CC0',
            'order': 0,
          },
        ],
      }),
      thumb,
    );
  });

  test('a missing or unusable galleryUrl falls back to the original', () {
    expect(
      detailGalleryFrames(_temple(original: original)).single.displayUrl,
      original,
    );
    expect(
      detailGalleryFrames(
        _temple(original: original, galleryUrl: 'http://example.com/g.jpg'),
      ).single.displayUrl,
      original,
    );
    expect(
      detailGalleryFrames(
        _temple(original: original, galleryUrl: 'https://picsum.photos/seed/a/800/600'),
      ).single.displayUrl,
      original,
    );
  });

  testWidgets('the detail gallery requests galleryUrl', (tester) async {
    final temple = _temple(original: original, galleryUrl: gallery, thumbUrl: thumb);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TempleDetailBody(temple: temple))),
    );
    await tester.pump();
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, gallery);
    expect(find.text('Ada · CC BY 4.0'), findsOneWidget);
  });

  testWidgets('the detail gallery uses the original when galleryUrl is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _temple(original: original))),
      ),
    );
    await tester.pump();
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, original);
  });
}
