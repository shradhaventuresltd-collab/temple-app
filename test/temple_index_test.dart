import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/services/admin_temple_service.dart';

Temple _temple({
  String id = '',
  String name = 'New Shore Temple',
  String state = 'Tamil Nadu',
  String location = 'Mahabalipuram',
  double latitude = 12.616,
  double longitude = 80.199,
  String imageUrl = 'https://example.com/shore.jpg',
}) {
  return Temple(
    id: id,
    name: name,
    state: state,
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: imageUrl,
    description: 'Pallava sea-shore shrine',
    story: 'Built by Rajasimha',
    location: location,
    timings: '6:00 AM – 6:00 PM',
    specialities: const ['UNESCO'],
    images: [imageUrl],
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  test('flag fixture matches DetailHonesty', () {
    final rows =
        jsonDecode(
              File(
                'scripts/fixtures/temple_index_flags.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final specialities = [
        for (final item in row['specialities'] as List) item.toString(),
      ];
      final temple = Temple(
        name: row['name'] as String,
        state: 'Tamil Nadu',
        city: 'Madurai',
        deity: row['deity'] as String,
        imageUrl: '',
        description: row['description'] as String? ?? '',
        story: row['story'] as String? ?? '',
        location: 'Madurai',
        timings: row['timings'] as String?,
        specialities: specialities,
        latitude: 9.9,
        longitude: 78.1,
      );
      final flags = templeIndexFlagsFor(temple);
      expect(flags.tradition, row['tradition'], reason: row['id'] as String);
      expect(flags.living, row['living'], reason: row['id'] as String);
      expect(flags.framing, row['framing'], reason: row['id'] as String);
    }
  });

  test('entry keeps browse fields and drops the heavy document', () {
    const thumb =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg';
    final entry = templeIndexEntryFromMap('meenakshi-amman-temple', {
      'name': 'Meenakshi Amman Temple',
      'state': 'Tamil Nadu',
      'city': 'Madurai',
      'deity': 'Devi',
      'address': 'Madurai Main, Madurai, Tamil Nadu 625001',
      'imageUrl': thumb,
      'images': [thumb],
      'description': 'The shrine holds daily pooja for devotees. ' * 20,
      'story': 'A long story. ' * 50,
      'timings': '5:00 AM – 10:00 PM',
      'specialities': ['Gopuram'],
      'photos': [
        {'url': thumb, 'licence': 'CC-BY', 'order': 0, 'credit': 'A'},
      ],
      'latitude': 9.9195,
      'longitude': 78.1193,
    });

    expect(entry['id'], 'meenakshi-amman-temple');
    expect(entry['slug'], 'meenakshi-amman-temple');
    expect(entry['address'], 'Madurai Main, Madurai, Tamil Nadu 625001');
    expect(
      entry['coverThumb'],
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/480px-File.jpg',
    );
    expect(entry['lat'], 9.9195);
    expect(entry['lng'], 78.1193);
    expect(entry['v'], kTempleIndexEntryVersion);
    expect(entry['updatedAt'], isNull);
    expect(entry.containsKey('imageUrl'), isFalse);
    expect(entry.containsKey('description'), isFalse);
    expect(entry.containsKey('story'), isFalse);
    expect(entry.containsKey('timings'), isFalse);
    expect(entry.containsKey('photos'), isFalse);
    expect(entry.containsKey('images'), isFalse);
    expect(entry.containsKey('specialities'), isFalse);
    expect(utf8.encode(jsonEncode(entry)).length, lessThan(800));
  });

  test('lat and lng are null when missing or exactly 0,0', () {
    final missing = templeIndexCoordinates({'latitude': null, 'longitude': 78});
    expect(missing.lat, isNull);
    expect(missing.lng, isNull);

    final zero = templeIndexCoordinates({'latitude': 0, 'longitude': 0.0});
    expect(zero.lat, isNull);
    expect(zero.lng, isNull);

    final axis = templeIndexCoordinates({'latitude': 0, 'longitude': 80});
    expect(axis.lat, 0);
    expect(axis.lng, 80);
  });

  test('cover prefers photos[0] thumb, then imageUrl, and caps at 500', () {
    const thumb = 'https://cdn.example/photos/shore_480.jpg';
    const full = 'https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg';
    expect(
      coverThumbFor({
        'photos': [
          {'url': full, 'thumbUrl': thumb, 'licence': 'CC0', 'order': 0},
        ],
        'imageUrl': 'https://example.com/cover.jpg',
        'images': ['https://example.com/gallery.jpg'],
      }),
      thumb,
    );
    const wide =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg';
    expect(
      coverThumbFor({
        'photos': [
          {'url': wide, 'licence': 'CC0', 'order': 0},
        ],
        'imageUrl': wide,
      }),
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/480px-File.jpg',
    );
    // TODO(KAN-146): this full URL is a stand-in until thumbnails exist.
    expect(coverThumbFor({'imageUrl': full}), full);
    expect(
      coverThumbFor({
        'imageUrl': 'https://picsum.photos/seed/temple/800/600',
        'images': ['https://example.com/gallery.jpg'],
      }),
      'https://example.com/gallery.jpg',
    );
    expect(
      coverThumbFor({'imageUrl': 'https://picsum.photos/seed/temple/800/600'}),
      isNull,
    );
    final tooLong = 'https://example.com/${'a' * 500}.jpg';
    expect(tooLong.length, greaterThan(kTempleIndexCoverThumbMax));
    expect(
      coverThumbFor({
        'imageUrl': tooLong,
        'images': [full],
      }),
      full,
    );
  });

  test('short address stops at 120 characters', () {
    final long = '${'Gate, ' * 40}Madurai';
    final short = shortTempleAddress(long);
    expect(short.length, lessThanOrEqualTo(kTempleIndexShortAddressMax));
    expect(short.endsWith(','), isFalse);
  });

  test('altNames, published, and hidden are copied only when present', () {
    final plain = templeIndexEntryFromMap('plain-temple', {
      'name': 'Plain',
      'state': 'Goa',
      'city': 'Panaji',
      'deity': 'Shiva',
      'address': 'Panaji',
      'latitude': 15.5,
      'longitude': 73.8,
    });
    expect(plain.containsKey('altNames'), isFalse);
    expect(plain.containsKey('published'), isFalse);
    expect(plain.containsKey('hidden'), isFalse);

    final flagged = templeIndexEntryFromMap('flagged-temple', {
      'name': 'Flagged',
      'state': 'Goa',
      'city': 'Panaji',
      'deity': 'Shiva',
      'address': 'Panaji',
      'latitude': 15.5,
      'longitude': 73.8,
      'altNames': ['Alt Shrine', ''],
      'published': false,
      'hidden': 'yes',
    });
    expect(flagged['altNames'], ['Alt Shrine']);
    expect(flagged['published'], isFalse);
    expect(flagged.containsKey('hidden'), isFalse);
  });

  test('state slug matches the shared fixture', () {
    final rows =
        jsonDecode(
              File(
                'scripts/fixtures/temple_index_slugs.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    expect(rows, isNotEmpty);
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      expect(
        templeIndexStateSlug(row['state'] as String),
        row['slug'],
        reason: row['state'] as String,
      );
    }
    expect(() => assertTempleIndexId('bad.id'), throwsA(isA<StateError>()));
  });

  test('hidden and published flags filter the index entry', () {
    expect(templeIndexEntryListed({'id': 'a'}), isTrue);
    expect(templeIndexEntryListed({'id': 'a', 'published': true}), isTrue);
    expect(templeIndexEntryListed({'id': 'a', 'hidden': false}), isTrue);
    expect(templeIndexEntryListed({'id': 'a', 'published': false}), isFalse);
    expect(templeIndexEntryListed({'id': 'a', 'hidden': true}), isFalse);
  });

  test('a state move plans one new field and a delete on the old shard', () {
    final plan = planTempleIndex(
      id: 'new-shore-temple',
      previous: {
        'state': 'Tamil Nadu',
        'altNames': ['Shore Temple'],
      },
      next: {
        'name': 'New Shore Temple',
        'state': 'Kerala',
        'city': 'Mahabalipuram',
        'deity': 'Shiva',
        'address': 'Mahabalipuram',
        'latitude': 12.6,
        'longitude': 80.2,
      },
    );
    expect(plan.upsertShard, 'kerala');
    expect(plan.removeShard, 'tamil-nadu');
    expect(plan.entry!['altNames'], ['Shore Temple']);
    expect(plan.entry!.containsKey('description'), isFalse);
    expect(plan.metaShards, ['kerala', 'tamil-nadu']);
  });

  test('create writes one entry field and does not wipe a sibling', () async {
    final store = MemoryTempleWriteStore();
    store.shards['tamil-nadu'] = {
      'other-temple': {'id': 'other-temple', 'name': 'Other'},
    };
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );

    await service.createTemple(_temple());

    expect(store.shards['tamil-nadu']!['other-temple']!['name'], 'Other');
    final entry = store.shards['tamil-nadu']!['new-shore-temple']!;
    expect(entry['name'], 'New Shore Temple');
    expect(entry['state'], 'Tamil Nadu');
    expect(entry['lat'], 12.616);
    expect(entry['lng'], 80.199);
    expect(entry['coverThumb'], 'https://example.com/shore.jpg');
    expect(entry['updatedAt'], 'server');
    expect(entry.containsKey('description'), isFalse);
    expect(store.indexVersion, 1);
    expect(store.shardStamps['tamil-nadu'], 'server');
    expect(store.lastIndexFieldPaths, [
      'temple_index/tamil-nadu/entries/new-shore-temple',
      'meta/temple_index',
    ]);
  });

  test('moving state removes only that entry from the old shard', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );
    await service.createTemple(_temple());
    store.shards['tamil-nadu']!['other-temple'] = {'id': 'other-temple'};

    await service.updateTemple(
      _temple(id: 'new-shore-temple', state: 'Kerala'),
    );

    expect(
      store.shards['tamil-nadu']!.containsKey('new-shore-temple'),
      isFalse,
    );
    expect(store.shards['tamil-nadu']!['other-temple']!['id'], 'other-temple');
    expect(store.shards['kerala']!['new-shore-temple']!['state'], 'Kerala');
    expect(store.indexVersion, 2);
    expect(store.shardStamps['kerala'], 'server');
    expect(store.shardStamps['tamil-nadu'], 'server');
    expect(
      store.lastIndexFieldPaths,
      contains('temple_index/tamil-nadu/entries/new-shore-temple delete'),
    );
  });

  test(
    'a state change before the index exists still writes the new shard',
    () async {
      final store = MemoryTempleWriteStore(
        docs: {
          'new-shore-temple': {
            'name': 'New Shore Temple',
            'state': 'Tamil Nadu',
            'city': 'Mahabalipuram',
            'deity': 'Shiva',
            'address': 'Mahabalipuram',
            'description': 'Pallava sea-shore shrine',
            'story': 'Built by Rajasimha',
            'timings': '6:00 AM – 6:00 PM',
            'specialities': ['UNESCO'],
            'imageUrl': 'https://example.com/shore.jpg',
            'images': ['https://example.com/shore.jpg'],
            'latitude': 12.616,
            'longitude': 80.199,
            'altNames': ['Shore Temple'],
            'published': true,
          },
        },
      );
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );

      await service.updateTemple(
        _temple(id: 'new-shore-temple', state: 'Kerala'),
      );

      expect(store.shards.containsKey('tamil-nadu'), isFalse);
      final entry = store.shards['kerala']!['new-shore-temple']!;
      expect(entry['altNames'], ['Shore Temple']);
      expect(entry['published'], isTrue);
      expect(entry.containsKey('hidden'), isFalse);
      expect(
        store.lastIndexFieldPaths.any((path) => path.endsWith(' delete')),
        isFalse,
      );
    },
  );

  test('delete removes the index entry in the same commit', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );
    await service.createTemple(_temple());

    await service.deleteTemple('new-shore-temple');

    expect(store.docs.containsKey('new-shore-temple'), isFalse);
    expect(
      store.shards['tamil-nadu']!.containsKey('new-shore-temple'),
      isFalse,
    );
    expect(store.indexVersion, 2);
  });

  test('0,0 from the admin form is stored as null lat/lng', () async {
    final store = MemoryTempleWriteStore();
    final service = AdminTempleService(
      store: store,
      isAdmin: () async => true,
      isDebug: true,
    );
    await service.createTemple(_temple(latitude: 0, longitude: 0));
    final entry = store.shards['tamil-nadu']!['new-shore-temple']!;
    expect(entry['lat'], isNull);
    expect(entry['lng'], isNull);
  });

  test('Firebase writer uses one batch and a single entry field path', () {
    final source = File(
      'lib/services/temple_write_store.dart',
    ).readAsStringSync();
    expect(source, contains('batch.commit()'));
    expect(source, contains("FieldPath(['entries', id])"));
    expect(source, contains('current is int ? current + 1 : 1'));
    expect(source, contains('FieldValue.delete()'));
    expect(source, contains('mergeFields'));
    expect(source, contains('collection(kTempleIndexCollection)'));
    expect(source, contains('kTempleIndexMetaDocId'));
    expect(source, contains('oldSnap.exists'));
    expect(source, isNot(contains('oldSnap.data()')));
    expect(source, isNot(contains('FieldValue.increment')));
  });

  test('browse still reads temples, not the index', () {
    final source = File('lib/services/temple_service.dart').readAsStringSync();
    expect(source, contains("collection('temples')"));
    expect(source, isNot(contains('temple_index')));
  });
}
