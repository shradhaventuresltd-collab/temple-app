import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/temple_form_validation.dart';

void main() {
  TempleDraft draft({
    String name = 'Meenakshi Amman Temple',
    String state = 'Tamil Nadu',
    String city = 'Madurai',
    String deity = 'Devi',
    String location = 'Madurai Main',
    String description = 'Historic temple',
    String story = 'Legend',
    String timings = '5:00 AM – 10:00 PM',
    String specialitiesText = 'Golden lotus tank\nThousand Pillar Hall',
    String imageUrl = 'https://example.com/cover.jpg',
    String imagesText = '',
    String latitudeText = '9.9195',
    String longitudeText = '78.1193',
    String id = '',
  }) {
    return TempleDraft(
      id: id,
      name: name,
      state: state,
      city: city,
      deity: deity,
      location: location,
      description: description,
      story: story,
      timings: timings,
      specialitiesText: specialitiesText,
      imageUrl: imageUrl,
      imagesText: imagesText,
      latitudeText: latitudeText,
      longitudeText: longitudeText,
    );
  }

  test('valid draft maps onto Temple fields the directory already uses', () {
    final result = validateTempleDraft(draft());

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    final temple = result.temple!;
    expect(temple.name, 'Meenakshi Amman Temple');
    expect(temple.state, 'Tamil Nadu');
    expect(temple.city, 'Madurai');
    expect(temple.deity, 'Devi');
    expect(temple.location, 'Madurai Main');
    expect(temple.story, 'Legend');
    expect(temple.description, 'Historic temple');
    expect(temple.timings, '5:00 AM – 10:00 PM');
    expect(temple.specialities, ['Golden lotus tank', 'Thousand Pillar Hall']);
    expect(temple.imageUrl, 'https://example.com/cover.jpg');
    expect(temple.images, ['https://example.com/cover.jpg']);
    expect(temple.latitude, 9.9195);
    expect(temple.longitude, 78.1193);
  });

  test('empty required fields produce per-field errors and no Temple', () {
    final result = validateTempleDraft(
      draft(name: '  ', state: '', city: '', deity: '', location: ' '),
    );

    expect(result.isValid, isFalse);
    expect(result.temple, isNull);
    expect(result.errors['name'], 'Name is required.');
    expect(result.errors['state'], 'State is required.');
    expect(result.errors['city'], 'City is required.');
    expect(result.errors['deity'], 'Deity is required.');
    expect(result.errors['location'], 'Location / address is required.');
  });

  test('empty coordinates stay null on the temple and in the write', () {
    final result = validateTempleDraft(
      draft(latitudeText: '', longitudeText: '  '),
    );
    expect(result.isValid, isTrue);
    expect(result.temple!.latitude, isNull);
    expect(result.temple!.longitude, isNull);
    final data = result.temple!.toFirestoreData();
    expect(data['latitude'], isNull);
    expect(data['longitude'], isNull);
  });

  test('invalid coordinates are rejected', () {
    expect(
      validateTempleDraft(draft(latitudeText: 'north')).errors['latitude'],
      'Enter a valid latitude.',
    );
    expect(
      validateTempleDraft(draft(longitudeText: '200')).errors['longitude'],
      'longitude must be between -180 and 180.',
    );
  });

  test('parseTempleStringList splits mixed separators', () {
    expect(parseTempleStringList('one, two;\nthree'), ['one', 'two', 'three']);
    expect(parseTempleStringList('  \n , '), isEmpty);
  });

  test('gallery URLs stay as listed when provided', () {
    final result = validateTempleDraft(
      draft(
        imageUrl: 'https://example.com/cover.jpg',
        imagesText: 'https://example.com/a.jpg\nhttps://example.com/b.jpg',
      ),
    );
    expect(result.temple!.images, [
      'https://example.com/a.jpg',
      'https://example.com/b.jpg',
    ]);
  });

  test('placeholder hosts are rejected on the cover and the gallery', () {
    final cover = validateTempleDraft(
      draft(imageUrl: 'https://picsum.photos/seed/anjengo/800/600'),
    );
    expect(cover.isValid, isFalse);
    expect(cover.temple, isNull);
    expect(
      cover.errors['imageUrl'],
      'Use a photograph URL. Placeholder hosts are not saved.',
    );

    final gallery = validateTempleDraft(
      draft(
        imageUrl: 'https://example.com/cover.jpg',
        imagesText:
            'https://example.com/cover.jpg\nhttps://source.unsplash.com/random\nhttps://dummyimage.com/600x400',
      ),
    );
    expect(gallery.isValid, isFalse);
    expect(
      gallery.errors['images'],
      'Use photograph URLs. Placeholder hosts are not saved.',
    );

    final stock = validateTempleDraft(
      draft(imageUrl: 'https://www.shutterstock.com/image-photo/temple'),
    );
    expect(stock.isValid, isFalse);
    expect(
      stock.errors['imageUrl'],
      'Use a photograph URL. Unlicensed stock hosts are not saved.',
    );

    final places = validateTempleDraft(
      draft(
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/temple-directory-india.firebasestorage.app/o/temples%2Fshore-temple%2Fimage_1.jpg?alt=media&token=secret',
      ),
    );
    expect(places.isValid, isFalse);
    expect(
      places.errors['imageUrl'],
      'Use a credited photograph. Google Places mirrors are not saved.',
    );
    final otherBucket = validateTempleDraft(
      draft(
        imageUrl:
            'https://storage.googleapis.com/other-bucket/temples/shore-temple/image_1.jpg',
      ),
    );
    expect(otherBucket.isValid, isTrue);

    final unsplash = validateTempleDraft(
      draft(imageUrl: 'https://images.unsplash.com/photo-1'),
    );
    expect(unsplash.isValid, isTrue);
    expect(unsplash.temple!.imageUrl, 'https://images.unsplash.com/photo-1');

    final adobe = validateTempleDraft(
      draft(imageUrl: 'https://www.adobe.com/image/temple.jpg'),
    );
    expect(adobe.isValid, isTrue);

    final pending = validateTempleDraft(draft(imageUrl: '', imagesText: ''));
    expect(pending.isValid, isTrue);
    expect(pending.temple!.imageUrl, isEmpty);
    expect(pending.temple!.images, isEmpty);
  });
}
