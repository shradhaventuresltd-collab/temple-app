import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/services/seed_service.dart';

void main() {
  test('templeDocumentId slugs names stably', () {
    expect(
      templeDocumentId('Meenakshi Amman Temple'),
      'meenakshi-amman-temple',
    );
    expect(
      templeDocumentId('Sri Krishna Matha (Udupi)'),
      'sri-krishna-matha-udupi',
    );
    expect(
      templeDocumentId('Murugan Temple, Thirupparankundram'),
      'murugan-temple-thirupparankundram',
    );
  });

  test('sample temple slugs are unique (seed will not collide)', () {
    final slugs = sampleTemples.map((t) => templeDocumentId(t.name)).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(slugs.length, 180);
  });

  test('SeedResult.successMessage covers create and update cases', () {
    expect(
      const SeedResult(
        writtenCount: 30,
        createdCount: 30,
        updatedCount: 0,
      ).successMessage,
      'Seeded 30 temples into Firestore.',
    );
    expect(
      const SeedResult(
        writtenCount: 30,
        createdCount: 0,
        updatedCount: 30,
      ).successMessage,
      'Updated 30 existing sample temples. No duplicates created.',
    );
    expect(
      const SeedResult(
        writtenCount: 30,
        createdCount: 5,
        updatedCount: 25,
      ).successMessage,
      'Seeded 30 temples (5 new, 25 updated).',
    );
  });
}
