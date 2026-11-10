import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/admin_temple_service.dart';

Temple _temple({
  String id = '',
  String name = 'New Shore Temple',
  String location = 'Mahabalipuram',
}) {
  return Temple(
    id: id,
    name: name,
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: 'https://example.com/shore.jpg',
    description: 'Pallava sea-shore shrine',
    story: 'Built by Rajasimha',
    location: location,
    timings: '6:00 AM – 6:00 PM',
    specialities: const ['UNESCO'],
    images: const ['https://example.com/shore.jpg'],
    latitude: 12.616,
    longitude: 80.199,
  );
}

Map<String, dynamic> _photoEntry(String url, int order) => {
      'url': url,
      'licence': 'Own',
      'order': order,
      'credit': '',
    };

void main() {
  test('Temple.fromMap reads address (and location fallback)', () {
    final fromAddress = Temple.fromMap('id-1', {
      'name': 'A',
      'state': 'Tamil Nadu',
      'city': 'Madurai',
      'deity': 'Devi',
      'imageUrl': 'https://x',
      'description': 'd',
      'story': 's',
      'address': 'Street 1',
      'timings': 'open',
      'specialities': ['chip'],
      'images': ['https://x'],
      'latitude': 1.5,
      'longitude': 2.5,
    });
    expect(fromAddress.location, 'Street 1');
    expect(fromAddress.latitude, 1.5);

    final fromLocation = Temple.fromMap('id-2', {'location': 'Old field'});
    expect(fromLocation.location, 'Old field');
    expect(fromLocation.timings, '');
  });

  test('null timings stay null in Firestore data and sample constructors', () {
    final temple = Temple(
      name: 'Example Temple',
      state: 'Bihar',
      city: 'Patna',
      deity: 'Shiva',
      imageUrl: '',
      description: 'A temple.',
      story: 'A story.',
      location: 'Patna, Bihar',
      timings: null,
      specialities: const ['Stone'],
      latitude: 25.6,
      longitude: 85.1,
    );
    expect(temple.timings, '');
    expect(temple.toFirestoreData()['timings'], isNull);

    final fromDoc = Temple.fromMap('example-temple', {'timings': null});
    expect(fromDoc.toFirestoreData()['timings'], isNull);
  });

  test('toFirestoreData uses address, not a parallel schema', () {
    final data = _temple(id: 'new-shore-temple').toFirestoreData();
    expect(data['id'], 'new-shore-temple');
    expect(data['address'], 'Mahabalipuram');
    expect(data.containsKey('location'), isFalse);
    expect(data['name'], 'New Shore Temple');
    expect(data['specialities'], ['UNESCO']);
    expect(data['images'], ['https://example.com/shore.jpg']);
    expect(data.containsKey('createdAt'), isFalse);
  });

  test('createTemple writes slug id and core fields', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    final id = await service.createTemple(_temple());

    expect(id, 'new-shore-temple');
    final doc = store.docs[id]!;
    expect(doc['name'], 'New Shore Temple');
    expect(doc['state'], 'Tamil Nadu');
    expect(doc['deity'], 'Shiva');
    expect(doc['address'], 'Mahabalipuram');
    expect(doc['story'], 'Built by Rajasimha');
    expect(doc['timings'], '6:00 AM – 6:00 PM');
    expect(doc['specialities'], ['UNESCO']);
    expect(doc['imageUrl'], 'https://example.com/shore.jpg');
    expect(doc['createdAt'], 'server');
  });

  test('createTemple refuses duplicate slug', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {'name': 'Existing'},
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    expect(
      () => service.createTemple(_temple()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        ),
      ),
    );
  });

  test('updateTemple merges fields onto the existing document', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {
          'name': 'Old',
          'createdAt': 'kept',
          'address': 'Old address',
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    await service.updateTemple(
      _temple(id: 'new-shore-temple', location: 'Updated address'),
    );

    expect(store.docs['new-shore-temple']!['address'], 'Updated address');
    expect(store.docs['new-shore-temple']!['name'], 'New Shore Temple');
    expect(store.docs['new-shore-temple']!['createdAt'], 'kept');
  });

  test('deleteTemple removes Storage prefix then the document', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {'name': 'New Shore Temple'},
      },
      storageObjectCounts: {'new-shore-temple': 2},
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    final result = await service.deleteTemple('new-shore-temple');

    expect(store.deleteStorageCalls, 1);
    expect(store.docs.containsKey('new-shore-temple'), isFalse);
    expect(result.storageObjectsDeleted, 2);
    expect(result.successMessage, contains('2 uploaded image(s)'));
  });

  test('deleteTemple aborts Firestore delete if Storage cleanup fails',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {'name': 'New Shore Temple'},
      },
    )..deleteStorageError = Exception('permission-denied');
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    expect(
      () => service.deleteTemple('new-shore-temple'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Firestore document was not removed'),
        ),
      ),
    );
    expect(store.docs.containsKey('new-shore-temple'), isTrue);
  });

  test('writes are refused without admin claim', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => false,
      isDebug: true,
    );

    expect(
      () => service.createTemple(_temple()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('signed-in admin'),
        ),
      ),
    );
    expect(store.docs, isEmpty);
  });

  test('writes are refused outside debug', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: false,
    );

    expect(
      () => service.updateTemple(_temple(id: 'x')),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('debug builds'),
        ),
      ),
    );
  });

  test('adminWriteErrorMessage maps permission and network failures', () {
    final denied = adminWriteErrorMessage(
      FirebaseException(plugin: 'firestore', code: 'permission-denied'),
    );
    expect(denied, contains('Permission denied'));
    expect(denied, contains('custom claim admin: true'));
    expect(denied, contains('required fields'));
    expect(
      adminWriteErrorMessage(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      ),
      contains('Network error'),
    );
    expect(
      adminWriteErrorMessage(StateError('Name is required.')),
      'Name is required.',
    );
  });

  test('appendTempleImages writes a full payload, not images-only', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {
          'name': 'Old name',
          'createdAt': 'kept',
          'imageUrl': 'https://example.com/shore.jpg',
          'images': ['https://example.com/shore.jpg'],
          'photos': [_photoEntry('https://example.com/shore.jpg', 0)],
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    final updated = await service.appendTempleImages(
      _temple(id: 'new-shore-temple'),
      ['https://example.com/new.jpg'],
    );

    final doc = store.docs['new-shore-temple']!;
    expect(doc['id'], 'new-shore-temple');
    expect(doc['name'], 'New Shore Temple');
    expect(doc['state'], 'Tamil Nadu');
    expect(doc['city'], 'Mahabalipuram');
    expect(doc['deity'], 'Shiva');
    expect(doc['address'], 'Mahabalipuram');
    expect(doc['description'], 'Pallava sea-shore shrine');
    expect(doc['story'], 'Built by Rajasimha');
    expect(doc['timings'], '6:00 AM – 6:00 PM');
    expect(doc['specialities'], ['UNESCO']);
    expect(doc['imageUrl'], 'https://example.com/shore.jpg');
    expect(doc['latitude'], 12.616);
    expect(doc['longitude'], 80.199);
    expect(doc['images'], [
      'https://example.com/shore.jpg',
      'https://example.com/new.jpg',
    ]);
    expect(doc['createdAt'], 'kept');
    expect(doc.containsKey('location'), isFalse);
    expect(doc.keys.toSet(), isNot(equals({'images'})));
    expect(updated.images.length, 2);
    expect(store.photoCalls, hasLength(1));
    expect((store.photoCalls.single['photos'] as List).last['licence'], 'Own');
  });

  test('appendTempleImages fills sparse docs from the current Temple model',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'brihadeeswarar-temple': {
          'imageUrl': 'https://example.com/brihadeeswarar.jpg',
          'images': ['https://example.com/brihadeeswarar.jpg'],
          'photos': [_photoEntry('https://example.com/brihadeeswarar.jpg', 0)],
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    await service.appendTempleImages(
      _temple(
        id: 'brihadeeswarar-temple',
        name: 'Brihadeeswarar Temple',
        location: 'Thanjavur',
      ),
      ['https://storage.googleapis.com/bucket/temples/brihadeeswarar-temple/1.jpg'],
    );

    final doc = store.docs['brihadeeswarar-temple']!;
    expect(doc['id'], 'brihadeeswarar-temple');
    expect(doc['name'], 'Brihadeeswarar Temple');
    expect(doc['address'], 'Thanjavur');
    expect(doc['images'], [
      'https://example.com/brihadeeswarar.jpg',
      'https://storage.googleapis.com/bucket/temples/brihadeeswarar-temple/1.jpg',
    ]);
    expect(store.photoCalls, hasLength(1));
  });

  test('appendTempleImages skips duplicate URLs and sets cover if empty',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {
          'imageUrl': 'https://example.com/shore.jpg',
          'images': ['https://example.com/shore.jpg'],
          'photos': [_photoEntry('https://example.com/shore.jpg', 0)],
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    final updated = await service.appendTempleImages(
      _temple(id: 'new-shore-temple').copyWith(imageUrl: ''),
      [
        'https://example.com/added.jpg',
      ],
    );

    expect(updated.images, [
      'https://example.com/shore.jpg',
      'https://example.com/added.jpg',
    ]);
    expect(updated.imageUrl, 'https://example.com/shore.jpg');
  });

  test('appendTempleImages refuses legacy images without photos licences',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'legacy-temple': {
          'name': 'Legacy',
          'images': [
            'https://upload.wikimedia.org/wikipedia/commons/a.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/b.jpg',
          ],
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/a.jpg',
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );
    await expectLater(
      service.appendTempleImages(
        _temple(id: 'legacy-temple'),
        ['https://example.com/new-upload.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Add licences for the existing photos in the editor first'),
        ),
      ),
    );
    expect(store.photoCalls, isEmpty);
  });

  test('appendTempleImages refuses extra Firestore keys with a clear error',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {
          'name': 'New Shore Temple',
          'hacked': true,
        },
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    expect(
      () => service.appendTempleImages(
        _temple(id: 'new-shore-temple'),
        ['https://example.com/new.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('extra fields (hacked)'),
        ),
      ),
    );
  });

  test('appendTempleImages client-validates empty required fields', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'x': {'images': <String>[], 'imageUrl': ''},
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    await expectLater(
      service.appendTempleImages(
        _temple(id: 'x', name: '   ', location: '').copyWith(
          images: const [],
          imageUrl: '',
        ),
        ['https://example.com/new.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('empty'),
        ),
      ),
    );
    expect(store.docs['x']!['images'], isEmpty);
    expect(store.photoCalls, isEmpty);
  });

  test('appendTempleImages reports photos saved when the text save fails',
      () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {
          'name': 'New Shore Temple',
          'images': <String>[],
          'imageUrl': '',
        },
      },
    )..setError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    await expectLater(
      service.appendTempleImages(
        _temple(id: 'new-shore-temple').copyWith(images: const [], imageUrl: ''),
        ['https://example.com/new.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('Photos saved; details/directory not updated, save again'),
            contains('Permission denied'),
          ),
        ),
      ),
    );
    expect(store.photoCalls, hasLength(1));
    expect(store.docs['new-shore-temple']!['images'], [
      'https://example.com/new.jpg',
    ]);
  });

  test('appendTempleImages is refused without admin claim', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {'name': 'New Shore Temple'},
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => false,
      isDebug: true,
    );

    expect(
      () => service.appendTempleImages(
        _temple(id: 'new-shore-temple'),
        ['https://example.com/new.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('signed-in admin'),
        ),
      ),
    );
    expect(store.docs['new-shore-temple']!['images'], isNull);
  });

  test('appendTempleImages is refused outside debug', () async {
    final store = MemoryTempleWriteStore(
      docs: {
        'new-shore-temple': {'name': 'New Shore Temple'},
      },
    );
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: false,
    );

    expect(
      () => service.appendTempleImages(
        _temple(id: 'new-shore-temple'),
        ['https://example.com/new.jpg'],
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('debug builds'),
        ),
      ),
    );
  });
}
