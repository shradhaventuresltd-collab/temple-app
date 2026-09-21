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
    expect(
      adminWriteErrorMessage(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      ),
      contains('Permission denied'),
    );
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
}
