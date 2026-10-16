import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/services/admin_temple_service.dart';

Temple _temple({
  List<TemplePhoto> photos = const [],
  bool writePhotos = false,
}) {
  return Temple(
    id: 'shore-temple',
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: 'https://example.com/old.jpg',
    description: 'Pallava shrine',
    story: 'Sea shore',
    location: 'Mahabalipuram',
    timings: '6:00 AM – 6:00 PM',
    specialities: const ['UNESCO'],
    images: const ['https://example.com/old.jpg'],
    photos: photos,
    writePhotos: writePhotos,
    latitude: 12.6,
    longitude: 80.2,
  );
}

TemplePhoto _photo({
  required String url,
  required int order,
  PhotoLicence? licence = PhotoLicence.cc0,
  String credit = '',
}) {
  return TemplePhoto(url: url, credit: credit, licence: licence, order: order);
}

void main() {
  test('PhotoLicence JSON round-trips CC0 and the other wire values', () {
    for (final licence in PhotoLicence.values) {
      expect(PhotoLicence.fromJson(licence.toJson()), licence);
      expect(PhotoLicence.wireValues, contains(licence.wireValue));
    }
    expect(PhotoLicence.cc0.toJson(), 'CC0');
    expect(PhotoLicence.fromJson('CC0'), PhotoLicence.cc0);
    expect(PhotoLicence.fromJson('PD'), isNull);
    expect(PhotoLicence.fromJson('Public domain'), isNull);
    expect(PhotoLicence.ccBy.requiresCredit, isTrue);
    expect(PhotoLicence.ccBySa.requiresCredit, isTrue);
    expect(PhotoLicence.cc0.requiresCredit, isFalse);
    expect(PhotoLicence.own.requiresCredit, isFalse);
    expect(PhotoLicence.permission.requiresCredit, isFalse);
  });

  test('TemplePhoto serialises url, credit, licence, and order', () {
    const photo = TemplePhoto(
      url: 'https://example.com/a.jpg',
      credit: 'Ada Lovelace',
      licence: PhotoLicence.ccBy,
      order: 2,
    );
    expect(photo.toJson(), {
      'url': 'https://example.com/a.jpg',
      'credit': 'Ada Lovelace',
      'licence': 'CC-BY',
      'order': 2,
    });
    final again = TemplePhoto.fromJson(photo.toJson());
    expect(again.url, photo.url);
    expect(again.credit, photo.credit);
    expect(again.licence, PhotoLicence.ccBy);
    expect(again.order, 2);

    final fromDoc = Temple.fromMap('shore-temple', {
      'photos': [
        photo.toJson(),
        {'url': 'https://example.com/b.jpg', 'licence': 'CC0', 'order': 0},
      ],
    });
    expect(fromDoc.photos, hasLength(2));
    expect(fromDoc.photos[1].licence, PhotoLicence.cc0);
    expect(fromDoc.photos[1].credit, isEmpty);
    expect(fromDoc.writePhotos, isFalse);
  });

  test('visible credit is only the CC-BY and CC-BY-SA line', () {
    const url = 'https://example.com/a.jpg';
    expect(
      visiblePhotoCredit(const [
        TemplePhoto(
          url: url,
          credit: 'Ada · CC BY 4.0',
          licence: PhotoLicence.ccBy,
          order: 0,
        ),
      ], url),
      'Ada · CC BY 4.0',
    );
    expect(
      visiblePhotoCredit(const [
        TemplePhoto(
          url: url,
          credit: 'Ada',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      isNull,
    );
    expect(
      visiblePhotoCredit(const [
        TemplePhoto(
          url: url,
          credit:
              '19th-century lithograph (1847 print). James Duffield Harding',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      '19th-century lithograph (1847 print). James Duffield Harding',
    );
    expect(
      visiblePhotoCredit(const [
        TemplePhoto(
          url: url,
          credit: '   ',
          licence: PhotoLicence.ccBySa,
          order: 0,
        ),
      ], url),
      isNull,
    );
    expect(visiblePhotoCredit(const [], url), isNull);
    expect(
      visiblePhotoCredit(const [
        TemplePhoto(
          url: url,
          credit: 'Skrsingh009 · Shows Punaura Dham',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Shows Punaura Dham',
    );
  });

  test('lithograph cover caption takes its year from the credit', () {
    const url = 'https://example.com/plate.jpg';
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit:
              '19th-century lithograph (1847 print). James Duffield Harding',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Lithograph, 1847',
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: 'Colour lithograph (1903 print)',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Lithograph, 1903',
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: 'A lithograph of the shrine',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Lithograph',
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: 'Rohit MDS · CC BY-SA 4.0',
          licence: PhotoLicence.ccBySa,
          order: 0,
        ),
      ], url),
      isNull,
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: 'A lithograph of the shrine. Catalogue 1847.',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Lithograph',
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: '1499 lithograph',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Lithograph',
    );
    expect(
      historicalCoverCaption(const [
        TemplePhoto(
          url: url,
          credit: 'Skrsingh009 · Shows Punaura Dham',
          licence: PhotoLicence.cc0,
          order: 0,
        ),
      ], url),
      'Shows Punaura Dham',
    );
  });

  test('credit is required for CC-BY and CC-BY-SA only', () {
    expect(
      templePhotoValidationError(
        _photo(url: 'https://example.com/a.jpg', order: 0, licence: null),
      ),
      'Each photo needs a licence.',
    );
    expect(
      templePhotoValidationError(
        _photo(
          url: 'https://example.com/a.jpg',
          order: 0,
          licence: PhotoLicence.ccBy,
        ),
      ),
      'Credit is required for CC-BY.',
    );
    expect(
      templePhotoValidationError(
        _photo(
          url: 'https://example.com/a.jpg',
          order: 0,
          licence: PhotoLicence.ccBySa,
          credit: '   ',
        ),
      ),
      'Credit is required for CC-BY-SA.',
    );
    expect(
      templePhotoValidationError(
        _photo(url: 'https://example.com/a.jpg', order: 0),
      ),
      isNull,
    );
    expect(
      templePhotoValidationError(
        _photo(url: 'http://example.com/a.jpg', order: 0),
      ),
      'Photo URL must start with https://.',
    );
    expect(
      templePhotoValidationError(
        _photo(url: 'https://example.com/a.jpg', order: 12),
      ),
      'Photo order must be between 0 and 11.',
    );
    expect(
      templePhotoValidationError(
        _photo(
          url: 'https://example.com/a.jpg',
          order: 0,
          licence: PhotoLicence.own,
        ),
      ),
      isNull,
    );
    expect(
      templePhotoValidationError(
        _photo(
          url: 'https://example.com/a.jpg',
          order: 0,
          licence: PhotoLicence.permission,
        ),
      ),
      isNull,
    );
  });

  test('mirror uses order 0 as the cover and sorts on write', () {
    final mirror = deriveTemplePhotoMirror([
      _photo(url: 'https://example.com/second.jpg', order: 5, credit: 'B'),
      _photo(
        url: 'https://example.com/cover.jpg',
        order: 0,
        licence: PhotoLicence.ccBySa,
        credit: 'A',
      ),
      _photo(url: 'https://example.com/mid.jpg', order: 2),
    ]);

    expect(mirror.imageUrl, 'https://example.com/cover.jpg');
    expect(mirror.images, [
      'https://example.com/cover.jpg',
      'https://example.com/mid.jpg',
      'https://example.com/second.jpg',
    ]);
    expect(mirror.photos.map((photo) => photo.order).toList(), [0, 1, 2]);
    expect(mirror.photos.first.licence, PhotoLicence.ccBySa);

    final data = _temple(
      photos: mirror.photos,
      writePhotos: true,
    ).toFirestoreData();
    expect(data['imageUrl'], 'https://example.com/cover.jpg');
    expect(data['images'], mirror.images);
    expect(data['photos'], [for (final photo in mirror.photos) photo.toJson()]);
    expect(data.containsKey('writePhotos'), isFalse);
  });

  test('writes without writePhotos do not backfill photos', () {
    final data = _temple(
      photos: [_photo(url: 'https://example.com/a.jpg', order: 0)],
    ).toFirestoreData();
    expect(data.containsKey('photos'), isFalse);
    expect(data['imageUrl'], 'https://example.com/old.jpg');
  });

  test('empty photo list mirrors a Photo pending temple', () {
    final mirror = deriveTemplePhotoMirror(const []);
    expect(mirror.imageUrl, isEmpty);
    expect(mirror.images, isEmpty);
    expect(mirror.photos, isEmpty);

    final data = _temple(writePhotos: true).toFirestoreData();
    expect(data['photos'], isEmpty);
    expect(data['imageUrl'], isEmpty);
    expect(data['images'], isEmpty);
  });

  test('storage path is temples/{docId}/{timestamp}.{ext}', () {
    expect(
      templePhotoStoragePath(
        docId: 'shore-temple',
        timestamp: 1710000000000,
        extension: 'jpg',
      ),
      'temples/shore-temple/1710000000000.jpg',
    );
  });

  test('more than 12 photos is rejected', () {
    final photos = [
      for (var i = 0; i < 13; i++)
        _photo(url: 'https://example.com/$i.jpg', order: i),
    ];
    expect(
      () => deriveTemplePhotoMirror(photos),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('12'),
        ),
      ),
    );
  });

  test('admin create writes photos and mirrors in one payload', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );
    final photos = [
      _photo(url: 'https://example.com/cover.jpg', order: 1),
      _photo(
        url: 'https://example.com/second.jpg',
        order: 0,
        licence: PhotoLicence.ccBy,
        credit: 'Photographer',
      ),
    ];

    await service.createTemple(
      _temple(photos: photos, writePhotos: true).copyWith(id: ''),
    );

    final doc = store.docs['shore-temple']!;
    expect(doc['imageUrl'], 'https://example.com/second.jpg');
    expect(doc['images'], [
      'https://example.com/second.jpg',
      'https://example.com/cover.jpg',
    ]);
    final stored = doc['photos'] as List;
    expect(stored, hasLength(2));
    expect((stored.first as Map)['licence'], 'CC-BY');
    expect((stored.first as Map)['order'], 0);
    expect((stored[1] as Map)['licence'], 'CC0');
    expect(doc.containsKey('writePhotos'), isFalse);
  });
}
