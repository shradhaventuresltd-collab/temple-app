import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/services/temple_write_store.dart';
import 'package:temple_app/utils/detail_honesty.dart';

/// Placeholder hosts and unlicensed stock hosts. Kept as literals so this
/// test still fails if [isDisallowedImageUrl] stops recognising one of them.
const stockPlaceholderHosts = <String>[
  'picsum.photos',
  'placeholder.com',
  'via.placeholder.com',
  'placehold.co',
  'placehold.it',
  'dummyimage.com',
  'lorempixel.com',
  'loremflickr.com',
  'placekitten.com',
  'fakeimg.pl',
  'placeimg.com',
  'source.unsplash.com',
  'unsplash.com',
  'images.unsplash.com',
  'shutterstock.com',
  'istockphoto.com',
  'istock.com',
  'pexels.com',
  'stock.adobe.com',
  'ftcdn.net',
  'alamy.com',
  'dreamstime.com',
  '123rf.com',
  'depositphotos.com',
  'freepik.com',
  'gettyimages',
];

/// Temples named in the placeholder-cover removal. None may use a stock host.
const checkedCovers = <String>[
  'Anjengo Sree Durga Devi Temple',
  'Kaleshwara Mukteswara Temple',
  'Akshardham Temple',
  'Mahamaya Temple',
  'Ranbireshwar Temple',
  'Purmandal Temple',
  'Sudh Mahadev Temple',
  'Chintaman Ganesh Temple',
  'Mangala Gauri Temple',
  'Ugratara Temple',
  'Janaki Temple Sitamarhi',
];

/// These four have no verified photograph. Empty imageUrl and images keep
/// the existing Photo pending state.
const photoPendingCovers = <String>[
  'Anjengo Sree Durga Devi Temple',
  'Mahamaya Temple',
  'Ranbireshwar Temple',
  'Sudh Mahadev Temple',
];

void main() {
  test(
    'sample data and seed data contain no stock placeholder hosts',
    () async {
      final source = File(
        'lib/data/sample_data.dart',
      ).readAsStringSync().toLowerCase();
      for (final host in stockPlaceholderHosts) {
        expect(
          source.contains(host),
          isFalse,
          reason: 'lib/data/sample_data.dart contains $host',
        );
      }

      for (final temple in sampleTemples) {
        _expectCleanUrl(temple.imageUrl, temple.name);
        for (final url in temple.images) {
          _expectCleanUrl(url, '${temple.name} images');
        }
        for (final photo in temple.photos) {
          _expectCleanUrl(photo.url, '${temple.name} photos');
        }
      }

      for (final name in checkedCovers) {
        final temple = sampleTemples.firstWhere(
          (temple) => temple.name == name,
        );
        _expectCleanUrl(temple.imageUrl, name);
        for (final url in temple.images) {
          _expectCleanUrl(url, name);
        }
        if (photoPendingCovers.contains(name)) {
          expect(temple.imageUrl, isEmpty, reason: name);
          expect(temple.images, isEmpty, reason: name);
        }
      }

      final store = MemoryTempleWriteStore();
      final result = await seedTempleData(
        store: store,
        existingDocs: const {},
        isAdmin: () async => true,
      );
      expect(result.writtenCount, sampleTemples.length);
      _expectCleanTree(store.docs, 'seed document');
      _expectCleanTree(store.shards, 'seed index');
    },
  );
}

void _expectCleanUrl(String url, String reason) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  expect(isDisallowedImageUrl(trimmed), isFalse, reason: reason);
  final lower = trimmed.toLowerCase();
  for (final host in stockPlaceholderHosts) {
    expect(lower.contains(host), isFalse, reason: '$reason contains $host');
  }
}

void _expectCleanTree(Object? value, String reason) {
  if (value is String) {
    final lower = value.toLowerCase();
    for (final host in stockPlaceholderHosts) {
      expect(lower.contains(host), isFalse, reason: '$reason contains $host');
    }
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      _expectCleanTree(entry.value, reason);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _expectCleanTree(item, reason);
    }
  }
}
