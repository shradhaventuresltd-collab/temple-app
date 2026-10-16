import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/utils/cover_thumb.dart';
import 'package:temple_app/widgets/temple_browse_card.dart';
import 'package:temple_app/services/admin_temple_service.dart';
import 'package:temple_app/services/seed_service.dart';

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
        tradition: const {'jain', 'buddhist', 'sikh'}.contains(row['tradition'])
            ? row['tradition'] as String
            : null,
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
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/800px-File.jpg';
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
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/500px-File.jpg',
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

    final nan = templeIndexCoordinates({
      'latitude': double.nan,
      'longitude': 78,
    });
    expect(nan.lat, isNull);
    expect(nan.lng, isNull);

    final infinite = templeIndexCoordinates({
      'latitude': 12.6,
      'longitude': double.infinity,
    });
    expect(infinite.lat, isNull);
    expect(infinite.lng, isNull);
  });

  test('cover matches the first verified gallery image and caps at 500', () {
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
      'https://example.com/gallery.jpg',
    );
    const wide =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/800px-File.jpg';
    expect(
      coverThumbFor({
        'photos': [
          {'url': wide, 'licence': 'CC0', 'order': 0},
        ],
        'imageUrl': wide,
      }),
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/500px-File.jpg',
    );
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

  test('cover thumb fixture matches the JS builder', () {
    final cases =
        jsonDecode(
              File(
                'scripts/fixtures/cover_thumb_cases.json',
              ).readAsStringSync(),
            )
            as List;
    for (final raw in cases) {
      final row = Map<String, dynamic>.from(raw as Map);
      final data = Map<String, dynamic>.from(row['data'] as Map);
      expect(coverThumbFor(data), row['expect'], reason: row['name'] as String);
    }
    final names =
        jsonDecode(
              File('scripts/fixtures/thumb_name_cases.json').readAsStringSync(),
            )
            as List;
    for (final raw in names) {
      final row = Map<String, dynamic>.from(raw as Map);
      expect(
        thumbObjectPath(
          row['objectPath'] as String,
          generation: row['generation'] as String,
        ),
        row['thumbPath'],
      );
      expect(fullCoverUrlFromThumb(row['thumbUrl'] as String), row['fullUrl']);
    }
    expect(
      fullCoverUrlFromThumb(
        'https://storage.googleapis.com/bucket/temples/shore/01_480.jpg',
      ),
      'https://storage.googleapis.com/bucket/temples/shore/01.jpg',
    );
    expect(
      thumbObjectPath('temples/shore/01_480.jpg', generation: '1'),
      isNull,
    );
    expect(
      wikimediaOriginalUrl(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/500px-File.jpg',
      ),
      'https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg',
    );
    expect(
      wikimediaOriginalUrl(
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/File.jpg/1280px-File.jpg',
      ),
      'https://upload.wikimedia.org/wikipedia/commons/7/76/File.jpg',
    );
    expect(
      wikimediaOriginalUrl(
        'https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg',
      ),
      isNull,
    );
    expect(
      wikimediaOriginalUrl(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Example.svg/480px-Example.svg.png',
      ),
      'https://upload.wikimedia.org/wikipedia/commons/8/84/Example.svg',
    );
    expect(
      fullCoverUrlFromThumb('https://cdn.example/photos/shore.jpg'),
      isNull,
    );
    final stored =
        jsonDecode(
              File(
                'scripts/fixtures/storage_url_cases.json',
              ).readAsStringSync(),
            )
            as List;
    for (final raw in stored) {
      final row = Map<String, dynamic>.from(raw as Map);
      final located = storageObjectFromUrl(row['url'] as String);
      expect(located, isNotNull, reason: row['name'] as String);
      expect(located!.kind, row['kind'], reason: row['name'] as String);
      expect(located.bucket, row['bucket'], reason: row['name'] as String);
      expect(
        located.objectPath,
        row['objectPath'],
        reason: row['name'] as String,
      );
    }
    expect(
      storageObjectFromUrl(
        'https://upload.wikimedia.org/wikipedia/commons/2/20/File.jpg',
      ),
      isNull,
    );
    expect(
      storageObjectFromUrl(
        'https://evil.example/v0/b/bucket/o/temples%2Fshore%2F01.jpg',
      ),
      isNull,
    );
    expect(
      storageObjectFromUrl(
        'https://bucket.firebasestorage.app.evil.com/o/temples%2Fshore%2F01.jpg',
      ),
      isNull,
    );
  });

  test('short address keeps a search word that follows a comma', () {
    const marker = 'DevakRiverbank';
    final address = '${'a' * 50}, $marker ${'tail ' * 80}';
    final short = shortTempleAddress(address);
    expect(short.length, lessThanOrEqualTo(kTempleIndexShortAddressMax));
    expect(short, contains(marker));
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
    final doc = store.docs['new-shore-temple']!;
    expect(doc['latitude'], isNull);
    expect(doc['longitude'], isNull);
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
    expect(source, contains('FieldValue.increment(1)'));
    expect(source, contains('SetOptions(merge: true)'));
    expect(source, contains('FieldValue.delete()'));
    expect(source, contains('mergeFields'));
    expect(source, contains('collection(kTempleIndexCollection)'));
    expect(source, contains('kTempleIndexMetaDocId'));
    expect(source, contains('oldSnap.exists'));
    expect(source, isNot(contains('oldSnap.data()')));
  });

  test('a whole-degree longitude is a double and text fields are trimmed', () {
    final entry = templeIndexEntryFromMap('whole-degree', {
      'name': 'N' * 200,
      'state': 'Tamil Nadu',
      'city': 'C' * 80,
      'deity': 'D' * 90,
      'address': 'Mahabalipuram, Tamil Nadu',
      'latitude': 12,
      'longitude': 80,
    });
    expect(entry['lng'], isA<double>());
    expect(entry['lat'], isA<double>());
    expect(entry['lng'], 80.0);
    expect(entry['lat'], 12.0);
    expect((entry['name'] as String).length, kTempleIndexNameMax);
    expect((entry['city'] as String).length, kTempleIndexCityMax);
    expect((entry['deity'] as String).length, kTempleIndexDeityMax);
    expect(
      estimateTempleIndexShardBytes(),
      lessThan(kTempleIndexDocumentByteLimit),
    );
  });

  test(
    'the 401st temple in a state is refused with a readable error',
    () async {
      final store = MemoryTempleWriteStore();
      final shard = <String, Map<String, dynamic>>{};
      for (var i = 0; i < kTempleIndexMaxEntries; i++) {
        shard['temple-$i'] = {'id': 'temple-$i'};
      }
      store.shards['tamil-nadu'] = shard;
      final service = AdminTempleService(
        store: store,
        isAdmin: () async => true,
        isDebug: true,
      );
      await expectLater(
        () => service.createTemple(_temple(name: 'One More Temple')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('This save was not written'),
          ),
        ),
      );
      expect(store.docs, isEmpty);
      expect(
        templeIndexShardFullMessage(state: 'Tamil Nadu', count: 400),
        contains(
          'Splitting one state across more than one shard is a later change',
        ),
      );
    },
  );

  test('a living shrine beside fort ruins is not a monument', () {
    final flags = templeIndexFlagsFor(
      Temple(
        name: 'Fort Side Shrine',
        state: 'Kerala',
        city: 'Anchuthengu',
        deity: 'Devi',
        imageUrl: '',
        description:
            'Daily puja at the shrine beside the fort ruins. The former factory ceased.',
        story: 'Historic fort ruins stand next to the temple.',
        location: 'Anchuthengu',
        timings: '5:00 AM – 8:00 PM',
        specialities: const [],
        latitude: 8.6,
        longitude: 76.7,
      ),
    );
    expect(flags.framing, 'living');
    expect(flags.living, isTrue);
  });

  test('Dart and JS index entries agree for every sample temple', () async {
    final payload = [
      for (final temple in sampleTemples)
        {
          'id': templeDocumentId(temple.name),
          'name': temple.name,
          'state': temple.state,
          'city': temple.city,
          'deity': temple.deity,
          'description': temple.description,
          'story': temple.story,
          'timings': temple.timings,
          'specialities': temple.specialities,
          'imageUrl': temple.imageUrl,
          'images': temple.images,
          'photos': [for (final photo in temple.photos) photo.toJson()],
          'address': temple.location,
          'latitude': temple.latitude,
          'longitude': temple.longitude,
        },
    ];
    final dir = await Directory.systemTemp.createTemp('temple-index-parity');
    final file = File('${dir.path}/temples.json');
    await file.writeAsString(jsonEncode(payload));
    final result = await Process.run('node', [
      'scripts/index_parity.js',
      file.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final jsRows = jsonDecode(result.stdout as String) as List<dynamic>;
    expect(jsRows, hasLength(sampleTemples.length));
    for (var i = 0; i < sampleTemples.length; i++) {
      final id = payload[i]['id'] as String;
      final dartEntry = templeIndexEntryFromMap(id, payload[i]);
      final js = Map<String, dynamic>.from(jsRows[i] as Map);
      expect(js['id'], id, reason: id);
      expect(js['framing'], dartEntry['framing'], reason: id);
      expect(js['tradition'], dartEntry['tradition'], reason: id);
      expect(js['living'], dartEntry['living'], reason: id);
      expect(js['name'], dartEntry['name'], reason: id);
      expect(js['city'], dartEntry['city'], reason: id);
      expect(js['state'], dartEntry['state'], reason: id);
      expect(js['deity'], dartEntry['deity'], reason: id);
      expect(js['address'], dartEntry['address'], reason: id);
      expect(js['coverThumb'], dartEntry['coverThumb'], reason: id);
      expect(js['coverCaption'], dartEntry['coverCaption'], reason: id);
      final lng = dartEntry['lng'];
      final lat = dartEntry['lat'];
      expect(lng == null || lng is double, isTrue, reason: id);
      expect(lat == null || lat is double, isTrue, reason: id);
      expect(lng, isNot(isA<int>()), reason: id);
      expect(lat, isNot(isA<int>()), reason: id);
      if (lng == null) {
        expect(js['lng'], isNull, reason: id);
      } else {
        expect((js['lng'] as num).toDouble(), lng, reason: id);
      }
      if (lat == null) {
        expect(js['lat'], isNull, reason: id);
      } else {
        expect((js['lat'] as num).toDouble(), lat, reason: id);
      }
      if (dartEntry['living'] == true) {
        expect(dartEntry['framing'], 'living', reason: id);
      }
    }
    final anjengo = templeIndexEntryFromMap(
      'anjengo-sree-durga-devi-temple',
      payload.firstWhere(
        (row) => row['id'] == 'anjengo-sree-durga-devi-temple',
      ),
    );
    expect(anjengo['framing'], 'neutral');
    await dir.delete(recursive: true);
  });

  test('an index entry becomes a browse temple with stored honesty', () {
    final temple = templeFromIndexEntry({
      'id': 'shore-temple',
      'name': 'Shore Temple',
      'state': 'Tamil Nadu',
      'city': 'Mahabalipuram',
      'deity': 'Shiva',
      'address': 'Mahabalipuram, Tamil Nadu',
      'coverThumb': 'https://example.com/shore.jpg',
      'coverCaption': 'Lithograph, 1847',
      'lat': 12.616,
      'lng': 80.199,
      'tradition': 'unspecified',
      'framing': 'monument',
    });
    expect(temple.isIndexSummary, isTrue);
    expect(temple.description, isEmpty);
    expect(temple.imageUrl, 'https://example.com/shore.jpg');
    expect(temple.location, 'Mahabalipuram, Tamil Nadu');
    expect(temple.latitude, 12.616);
    expect(temple.longitude, 80.199);
    expect(temple.hasCoordinates, isTrue);
    final missingPoint = templeFromIndexEntry({
      'id': 'no-point',
      'name': 'No Point',
      'state': 'Goa',
    });
    expect(missingPoint.latitude, isNull);
    expect(missingPoint.longitude, isNull);
    expect(missingPoint.hasCoordinates, isFalse);
    expect(templeBrowseHonestyLabels(temple), ['Heritage visit']);
    expect(temple.coverCaption, 'Lithograph, 1847');
  });

  test('unchanged applied stamps stay on cache and a new stamp is fetched', () {
    final stamp = DateTime.utc(2026, 1, 2);
    final plan = planIndexShardReads(
      appliedStamps: {
        'bihar': stamp.millisecondsSinceEpoch,
        'kerala': stamp.millisecondsSinceEpoch,
      },
      serverStamps: {'kerala': stamp, 'bihar': DateTime.utc(2026, 2, 2)},
    );
    expect(plan.map((read) => read.slug), ['bihar', 'kerala']);
    expect(plan[0].fromCache, isFalse);
    expect(plan[1].fromCache, isTrue);
  });

  test('browse reads the index and falls back to temples', () {
    final source = File('lib/services/temple_service.dart').readAsStringSync();
    expect(source, contains("collection('temples')"));
    expect(source, contains('kTempleIndexCollection'));
    expect(source, contains('Source.cache'));
    expect(source, contains('Source.server'));
  });
}
