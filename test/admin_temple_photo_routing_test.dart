// KAN-200: photo changes go through the setTemplePhotos callable; text
// edits stay a direct Firestore save.
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/services/admin_temple_service.dart';

const _id = 'shore-temple';

TemplePhoto _photo(int i, {String? credit}) => TemplePhoto(
  url: 'https://firebasestorage.googleapis.com/v0/b/app/o/p$i.jpg',
  credit: credit ?? 'Contributor $i',
  licence: PhotoLicence.ccBySa,
  order: i,
  thumbUrl: 'https://firebasestorage.googleapis.com/v0/b/app/o/p${i}_480.jpg',
);

Temple _temple(
  List<TemplePhoto> photos, {
  String story = 'Built by Rajasimha',
}) => Temple(
  id: _id,
  name: 'Shore Temple',
  state: 'Tamil Nadu',
  city: 'Mahabalipuram',
  deity: 'Shiva',
  imageUrl: '',
  description: 'Pallava sea-shore shrine',
  story: story,
  location: 'Mahabalipuram',
  timings: '6:00 AM – 6:00 PM',
  specialities: const ['UNESCO'],
  images: const [],
  latitude: 12.616,
  longitude: 80.199,
  photos: photos,
  writePhotos: true,
);

MemoryTempleWriteStore _seeded(List<TemplePhoto> photos) {
  final data = _temple(photos).toFirestoreData(documentId: _id);
  return MemoryTempleWriteStore(docs: {_id: data});
}

AdminTempleService _service(MemoryTempleWriteStore store) => AdminTempleService(
  store: store,
  isAdmin: () async => true,
  isDebug: true,
  watch: () => const Stream.empty(),
);

List<TemplePhoto> _nine() => [for (var i = 0; i < 9; i++) _photo(i)];

void main() {
  test('a text-only edit does not call the photo callable', () async {
    final store = _seeded(_nine());
    await _service(store).updateTemple(_temple(_nine(), story: 'Edited.'));
    expect(store.photoCalls, isEmpty);
    expect(store.docs[_id]!['story'], 'Edited.');
    expect((store.docs[_id]!['photos'] as List).length, 9);
  });

  test(
    'an edit of a temple saved without writePhotos does not call it',
    () async {
      final store = _seeded(_nine());
      final plain = Temple.fromMap(
        _id,
        store.docs[_id]!,
      ).copyWith(story: 'Plain.');
      await _service(store).updateTemple(plain);
      expect(store.photoCalls, isEmpty);
      expect(store.docs[_id]!['story'], 'Plain.');
    },
  );

  final changes = <String, List<TemplePhoto> Function()>{
    'add a 10th photo': () => [..._nine(), _photo(9)],
    'reorder': () => [
      for (final (i, p) in _nine().reversed.indexed)
        TemplePhoto(
          url: p.url,
          credit: p.credit,
          licence: p.licence,
          order: i,
          thumbUrl: p.thumbUrl,
        ),
    ],
    'delete one': () => _nine().sublist(0, 8),
    'delete all': () => const [],
    'cover change': () => [
      for (final (i, p) in [
        _nine()[4],
        ..._nine().where((p) => p.order != 4),
      ].indexed)
        TemplePhoto(
          url: p.url,
          credit: p.credit,
          licence: p.licence,
          order: i,
          thumbUrl: p.thumbUrl,
        ),
    ],
    'credit edit': () => [
      ..._nine().sublist(0, 8),
      _photo(8, credit: 'New credit'),
    ],
    'fill to 12': () => [for (var i = 0; i < 12; i++) _photo(i)],
  };

  for (final MapEntry(key: name, value: next) in changes.entries) {
    test('$name goes through the callable, then the text save', () async {
      final store = _seeded(_nine());
      final want = next();
      await _service(store).updateTemple(_temple(want, story: 'With $name.'));

      expect(store.photoCalls, hasLength(1));
      final call = store.photoCalls.single;
      expect(call['templeId'], _id);
      final sent = call['photos'] as List;
      final mirror = deriveTemplePhotoMirror(want);
      expect(sent, [for (final p in mirror.photos) p.toJson()]);

      final doc = store.docs[_id]!;
      expect(templeDataDeepEquals(doc['photos'], sent), isTrue);
      expect(doc['imageUrl'], mirror.imageUrl);
      expect(doc['images'], mirror.images);
      expect(doc['story'], 'With $name.');
    });
  }

  test('a failed callable stops before the text save', () async {
    final store = _seeded(_nine())..setPhotosError = StateError('denied');
    final before = Map<String, dynamic>.from(store.docs[_id]!);
    await expectLater(
      _service(
        store,
      ).updateTemple(_temple([..._nine(), _photo(9)], story: 'Lost.')),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Photos may not have been saved; retry'),
        ),
      ),
    );
    expect(store.docs[_id], before);
  });

  test('createTemple stays a direct write; appendTempleImages uses the callable',
      () async {
    final store = MemoryTempleWriteStore();
    final service = _service(store);
    await service.createTemple(_temple(_nine()));
    expect(store.photoCalls, isEmpty);
    expect((store.docs[_id]!['photos'] as List).length, 9);

    final stored = Temple.fromMap(_id, store.docs[_id]!);
    await service.appendTempleImages(stored, [
      'https://firebasestorage.googleapis.com/v0/b/app/o/extra.jpg',
    ]);
    expect(store.photoCalls, hasLength(1));
    final sent = store.photoCalls.single['photos'] as List;
    expect(sent, hasLength(10));
    expect(sent.last['url'], contains('extra.jpg'));
    expect(sent.last['licence'], 'Own');
    expect(sent.last['order'], 9);
    expect((store.docs[_id]!['images'] as List).length, 10);
  });

  test('text save failure after a photo callable still reports photos saved',
      () async {
    final store = _seeded(_nine())
      ..setError = StateError('index shard full');
    await expectLater(
      _service(store).updateTemple(
        _temple([..._nine(), _photo(9)], story: 'Lost text.'),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Photos saved; details/directory not updated, save again'),
        ),
      ),
    );
    expect(store.photoCalls, hasLength(1));
    expect((store.docs[_id]!['photos'] as List).length, 10);
  });

  test('templeDataDeepEquals ignores map key order, not list order', () {
    expect(
      templeDataDeepEquals(
        {
          'a': 1,
          'b': [1, 2],
        },
        {
          'b': [1, 2],
          'a': 1.0,
        },
      ),
      isTrue,
    );
    expect(templeDataDeepEquals([1, 2], [2, 1]), isFalse);
    expect(templeDataDeepEquals({'a': 1}, {'a': 1, 'b': null}), isFalse);
    expect(templeDataDeepEquals(null, const []), isFalse);
  });
}
