import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:flutter/material.dart';

Temple _named(String name) {
  return sampleTemples.firstWhere((temple) => temple.name == name);
}

Temple _draft({
  String name = 'Draft Temple',
  String deity = 'Shiva',
  String imageUrl = '',
  List<String> images = const [],
  String description = 'A place listed in the directory.',
  String story = 'Notes are still being checked.',
  String timings = '6:00 AM–8:00 PM daily.',
  List<String> specialities = const ['Stone gateway'],
}) {
  return Temple(
    name: name,
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: deity,
    imageUrl: imageUrl,
    description: description,
    story: story,
    location: 'Temple Street',
    timings: timings,
    specialities: specialities,
    images: images,
    latitude: 9.9,
    longitude: 78.1,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('placeholder and empty image URLs are not treated as photographs', () {
    expect(isPlaceholderImageUrl(''), isTrue);
    expect(isPlaceholderImageUrl('   '), isTrue);
    expect(
      isPlaceholderImageUrl('https://picsum.photos/seed/meenakshi/800/600'),
      isTrue,
    );
    expect(
      isPlaceholderImageUrl('https://fastly.picsum.photos/id/1/800/600'),
      isTrue,
    );
    expect(
      isPlaceholderImageUrl('https://i.picsum.photos/id/1/800/600'),
      isTrue,
    );
    expect(isPlaceholderImageUrl('https://loremflickr.com/800/600'), isTrue);
    expect(
      isPlaceholderImageUrl('https://www.loremflickr.com/800/600'),
      isTrue,
    );
    expect(isPlaceholderImageUrl('https://placekitten.com/800/600'), isTrue);
    expect(isPlaceholderImageUrl('https://fakeimg.pl/800x600'), isTrue);
    expect(isPlaceholderImageUrl('https://placeimg.com/800/600'), isTrue);
    expect(isPlaceholderImageUrl('https://notpicsum.photos/800'), isFalse);
    expect(
      isPlaceholderImageUrl('https://cdn.source.unsplash.com/random'),
      isFalse,
    );
    expect(
      isPlaceholderImageUrl('https://images.unsplash.com/photo-1'),
      isFalse,
    );
    expect(
      isUnlicensedStockImageUrl('https://images.unsplash.com/photo-1'),
      isFalse,
    );
    expect(
      isPlaceholderImageUrl('https://www.shutterstock.com/image-photo/temple'),
      isFalse,
    );
    expect(isUnlicensedStockImageUrl(''), isFalse);
    expect(isUnlicensedStockImageUrl('not-a-url'), isFalse);
    for (final url in [
      'https://www.shutterstock.com/image-photo/temple',
      'https://www.istockphoto.com/photo/temple',
      'https://media.gettyimages.com/id/1/photo.jpg',
      'https://www.gettyimages.co.uk/detail/photo/temple',
      'https://www.pexels.com/photo/temple',
      'https://stock.adobe.com/images/temple',
      'https://www.alamy.com/temple.jpg',
      'https://www.dreamstime.com/temple',
      'https://www.123rf.com/photo_1.html',
      'https://depositphotos.com/photo/temple.html',
      'https://www.freepik.com/free-photo/temple',
      'https://cdn.istock.com/photo/temple',
    ]) {
      expect(isUnlicensedStockImageUrl(url), isTrue, reason: url);
      expect(isDisallowedImageUrl(url), isTrue, reason: url);
    }
    expect(
      isUnlicensedStockImageUrl('https://www.adobe.com/image/temple.jpg'),
      isFalse,
    );
    expect(
      isUnlicensedStockImageUrl(
        'https://example.com/photos/shutterstock-temple.jpg',
      ),
      isFalse,
    );
    expect(
      verifiedGalleryUrls(
        _draft(imageUrl: 'https://www.shutterstock.com/image-photo/temple'),
      ),
      isEmpty,
    );
    expect(
      verifiedGalleryUrls(
        _draft(imageUrl: 'https://images.unsplash.com/photo-1'),
      ),
      ['https://images.unsplash.com/photo-1'],
    );
    const wide =
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/File.jpg/1280px-File.jpg';
    expect(verifiedGalleryUrls(_draft(imageUrl: wide)), [wide]);
    expect(
      isPlaceholderImageUrl(
        'https://upload.wikimedia.org/wikipedia/commons/x/xx/Placeholder_temple.jpg',
      ),
      isFalse,
    );
    expect(
      isPlaceholderImageUrl(
        'https://storage.googleapis.com/bucket/temples/placeholder-x.jpg',
      ),
      isFalse,
    );
    expect(isPlaceholderImageUrl('https://placehold.co/800x600'), isTrue);
    expect(isPlaceholderImageUrl('https://placehold.it/800x600'), isTrue);
    expect(isPlaceholderImageUrl('https://dummyimage.com/800x600'), isTrue);
    expect(isPlaceholderImageUrl('https://lorempixel.com/800/600'), isTrue);
    expect(isPlaceholderImageUrl('https://source.unsplash.com/random'), isTrue);
    expect(isPlaceholderImageUrl('https://placeholder.com/800'), isTrue);
    expect(
      isPlaceholderImageUrl('https://via.placeholder.com/800x600'),
      isTrue,
    );
    expect(isPlaceholderImageUrl('not-a-url'), isTrue);
    expect(
      isPlaceholderImageUrl(
        'https://firebasestorage.googleapis.com/v0/b/app/o/temple.jpg?alt=media',
      ),
      isFalse,
    );
  });

  test('picsum covers and empty galleries are photo pending', () {
    // KAN-77: #19 packs, Wave B Karnataka, and Wave A TN/KL Commons thumbs,
    // including Thiruchendur. KAN-76 Wave C adds 93 all-India packs.
    var verifiedCount = 0;
    for (final temple in sampleTemples) {
      final urls = verifiedGalleryUrls(temple);
      if (urls.isEmpty) {
        expect(
          DetailHonesty.of(temple).photoPending,
          isTrue,
          reason: temple.name,
        );
        expect(verifiedCoverUrl(temple), isNull, reason: temple.name);
      } else {
        verifiedCount++;
        expect(
          DetailHonesty.of(temple).photoPending,
          isFalse,
          reason: temple.name,
        );
        expect(
          temple.imageUrl.contains('picsum'),
          isFalse,
          reason: temple.name,
        );
        expect(
          temple.imageUrl.contains('firebasestorage'),
          isFalse,
          reason: temple.name,
        );
      }
    }
    final expectedVerified = sampleTemples
        .where((temple) => verifiedGalleryUrls(temple).isNotEmpty)
        .length;
    expect(verifiedCount, expectedVerified);

    final mixed = _draft(
      imageUrl: 'https://picsum.photos/seed/cover/800/600',
      images: const [
        'https://picsum.photos/seed/other/800/600',
        'https://example.com/temple.jpg',
      ],
    );
    expect(verifiedGalleryUrls(mixed), ['https://example.com/temple.jpg']);
    expect(verifiedCoverUrl(mixed), 'https://example.com/temple.jpg');

    final realCover = _draft(imageUrl: 'https://example.com/cover.jpg');
    expect(DetailHonesty.of(realCover).photoPending, isFalse);
    expect(verifiedGalleryUrls(realCover), ['https://example.com/cover.jpg']);
    expect(verifiedCoverUrl(realCover), 'https://example.com/cover.jpg');
  });

  test('mosaic URLs drop placeholder hosts across temples', () {
    final temples = [
      _draft(imageUrl: 'https://picsum.photos/seed/a/800/600'),
      _draft(
        name: 'With real photo',
        imageUrl: 'https://picsum.photos/seed/b/800/600',
        images: const [
          'https://picsum.photos/seed/c/800/600',
          'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
        ],
      ),
      _draft(name: 'Empty', imageUrl: ''),
    ];

    expect(verifiedMosaicUrls(temples), [
      'https://firebasestorage.googleapis.com/v0/b/app/o/a.jpg?alt=media',
    ]);
  });

  test(
    'KAN-77 verified Commons packs clear Photo pending and keep framing',
    () {
      final mahabodhi = DetailHonesty.of(_named('Mahabodhi Temple'));
      expect(_named('Mahabodhi Temple').imageUrl.contains('picsum'), isFalse);
      expect(mahabodhi.photoPending, isFalse);
      expect(mahabodhi.verifiedImages, hasLength(7));
      expect(mahabodhi.tradition, SiteTradition.buddhist);

      final dilwara = DetailHonesty.of(_named('Dilwara Temples'));
      expect(_named('Dilwara Temples').imageUrl.contains('picsum'), isFalse);
      expect(dilwara.photoPending, isFalse);
      expect(dilwara.verifiedImages, hasLength(6));
      expect(dilwara.tradition, SiteTradition.jain);
      // "Active Jain tirtha" is a legacy living phrase. Tradition still wins,
      // so the listing is not framed as a living temple.
      expect(dilwara.framing, SiteFraming.neutral);

      final martand = DetailHonesty.of(_named('Martand Sun Temple'));
      expect(_named('Martand Sun Temple').imageUrl.contains('picsum'), isFalse);
      expect(martand.photoPending, isFalse);
      expect(martand.verifiedImages, hasLength(6));
      expect(martand.framing, SiteFraming.monumentVisit);
      expect(martand.framingLabel, 'Heritage visit');

      final shore = DetailHonesty.of(_named('Shore Temple'));
      expect(_named('Shore Temple').imageUrl.contains('picsum'), isFalse);
      expect(shore.photoPending, isFalse);
      expect(shore.verifiedImages, hasLength(6));
      expect(shore.framing, SiteFraming.monumentVisit);

      final meenakshi = DetailHonesty.of(_named('Meenakshi Amman Temple'));
      expect(
        _named('Meenakshi Amman Temple').imageUrl.contains('picsum'),
        isFalse,
      );
      expect(meenakshi.photoPending, isFalse);
      expect(meenakshi.verifiedImages, hasLength(6));
      expect(meenakshi.framing, SiteFraming.livingTemple);
      expect(meenakshi.tradition, SiteTradition.unspecified);

      final sabarimala = DetailHonesty.of(_named('Sabarimala Ayyappan Temple'));
      expect(
        _named('Sabarimala Ayyappan Temple').imageUrl.contains('picsum'),
        isFalse,
      );
      expect(sabarimala.photoPending, isFalse);
      expect(sabarimala.verifiedImages, hasLength(5));
      expect(sabarimala.framing, SiteFraming.livingTemple);
      expect(sabarimala.framingLabel, 'Living temple');
      expect(sabarimala.tradition, SiteTradition.unspecified);
      expect(sabarimala.timingsCaveat, TimingsCaveatKind.seasonal);

      final padmanabha = DetailHonesty.of(
        _named('Sree Padmanabhaswamy Temple'),
      );
      expect(
        _named('Sree Padmanabhaswamy Temple').imageUrl.contains('picsum'),
        isFalse,
      );
      expect(padmanabha.photoPending, isFalse);
      expect(padmanabha.verifiedImages, hasLength(6));
      // Official timings name darshan windows, so this is a living temple.
      expect(padmanabha.framing, SiteFraming.livingTemple);
      expect(padmanabha.framingLabel, 'Living temple');

      final brihad = DetailHonesty.of(_named('Brihadeeswarar Temple'));
      expect(brihad.photoPending, isFalse);
      expect(brihad.verifiedImages, hasLength(6));
      expect(brihad.framing, SiteFraming.livingTemple);
      expect(brihad.framingLabel, 'Living temple');

      final thiruchendur = DetailHonesty.of(_named('Subramanya Swamy Temple'));
      expect(thiruchendur.photoPending, isFalse);
      expect(
        _named('Subramanya Swamy Temple').imageUrl,
        contains('wikimedia.org'),
      );
      expect(thiruchendur.verifiedImages, hasLength(8));
      expect(thiruchendur.framing, SiteFraming.livingTemple);
    },
  );

  test(
    'timings stay free text and flag thin, seasonal, or multi-window notes',
    () {
      final amarnath = DetailHonesty.of(_named('Amarnath Cave Temple'));
      expect(amarnath.timingsCaveat, TimingsCaveatKind.seasonal);
      expect(amarnath.timingsCaveatText, contains('Provisional / seasonal'));
      expect(amarnath.timingsCaveatText, contains('always-open'));

      final meenakshi = DetailHonesty.of(_named('Meenakshi Amman Temple'));
      expect(meenakshi.timingsCaveat, TimingsCaveatKind.multiWindow);
      expect(meenakshi.timingsCaveatText, contains('always-open'));

      final sabarimala = DetailHonesty.of(_named('Sabarimala Ayyappan Temple'));
      expect(sabarimala.timingsCaveat, TimingsCaveatKind.seasonal);

      final shore = DetailHonesty.of(_named('Shore Temple'));
      expect(shore.timingsCaveat, TimingsCaveatKind.none);
      expect(shore.timingsCaveatText, isNull);

      final missing = DetailHonesty.of(_draft(timings: '   '));
      expect(missing.timingsCaveat, TimingsCaveatKind.missing);
      expect(missing.timingsCaveatText, contains('No visiting hours'));

      final thin = DetailHonesty.of(
        _draft(timings: 'Thin official clock. Confirm locally.'),
      );
      expect(thin.timingsCaveat, TimingsCaveatKind.provisional);

      final single = DetailHonesty.of(
        _draft(timings: 'Open daily 6:00 AM–9:00 PM.'),
      );
      expect(single.timingsCaveat, TimingsCaveatKind.none);
    },
  );

  test('site framing uses existing copy and stays neutral when unsure', () {
    final martand = DetailHonesty.of(_named('Martand Sun Temple'));
    expect(martand.framing, SiteFraming.monumentVisit);
    expect(martand.framingLabel, 'Heritage visit');
    expect(martand.timingsHeading, 'Visiting hours');
    expect(martand.storyHeading, 'Site history');

    final kandariya = DetailHonesty.of(_named('Kandariya Mahadeva Temple'));
    expect(kandariya.framing, SiteFraming.monumentVisit);

    final rajarani = DetailHonesty.of(_named('Rajarani Temple'));
    expect(rajarani.framing, SiteFraming.monumentVisit);

    final shore = DetailHonesty.of(_named('Shore Temple'));
    expect(shore.framing, SiteFraming.monumentVisit);

    final brihad = DetailHonesty.of(_named('Brihadeeswarar Temple'));
    expect(brihad.framing, SiteFraming.livingTemple);
    expect(brihad.framingLabel, 'Living temple');

    final virupaksha = DetailHonesty.of(_named('Virupaksha Temple'));
    expect(virupaksha.framing, SiteFraming.livingTemple);

    final meenakshi = DetailHonesty.of(_named('Meenakshi Amman Temple'));
    expect(meenakshi.framing, SiteFraming.livingTemple);

    final unsure = DetailHonesty.of(_draft());
    expect(unsure.framing, SiteFraming.neutral);
    expect(unsure.framingLabel, isNull);
    expect(unsure.tradition, SiteTradition.unspecified);
    expect(unsure.storyHeading, 'Background');
    expect(unsure.framingNote, contains('do not say clearly'));
  });

  test('KAN-103 worship words mark living temples and heritage still wins', () {
    final jejuri = DetailHonesty.of(_named('Jejuri Khandoba Temple'));
    expect(jejuri.tradition, SiteTradition.unspecified);
    expect(jejuri.traditionLabel, isNull);
    expect(jejuri.framing, SiteFraming.livingTemple);
    expect(jejuri.framingLabel, 'Living temple');
    expect(
      jejuri.framingLabel,
      DetailHonesty.of(_named('Meenakshi Amman Temple')).framingLabel,
    );
    expect(jejuri.storyHeading, 'Temple story');
    expect(jejuri.framingNote, contains('living temple'));

    final shoreTemple = _named('Shore Temple');
    final shore = DetailHonesty.of(shoreTemple);
    expect(shoreTemple.timings.toLowerCase(), contains('darshan'));
    expect(shoreTemple.timings.toLowerCase(), contains('pooja'));
    expect(shore.framing, SiteFraming.monumentVisit);
    expect(shore.framingLabel, 'Heritage visit');
    expect(shore.timingsHeading, 'Visiting hours');

    final martandTemple = _named('Martand Sun Temple');
    final martand = DetailHonesty.of(martandTemple);
    expect(martandTemple.timings.toLowerCase(), contains('darshan'));
    expect(martandTemple.timings.toLowerCase(), contains('aarti'));
    expect(martand.framing, SiteFraming.monumentVisit);
    expect(martand.framingLabel, 'Heritage visit');

    final hoursOnly = DetailHonesty.of(
      _draft(
        description: 'A stone temple in the directory.',
        story: 'Visitors walk the courtyard.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
        specialities: const ['Stone gateway'],
      ),
    );
    expect(hoursOnly.framing, SiteFraming.neutral);
    expect(hoursOnly.framingLabel, isNull);

    final jainDarshan = DetailHonesty.of(
      _draft(
        deity: 'Jain Tirthankara',
        description: 'A Jain pilgrimage site.',
        timings: 'Darshan time 6:00 AM–8:00 PM.',
      ),
    );
    expect(jainDarshan.tradition, SiteTradition.jain);
    expect(jainDarshan.traditionLabel, 'Jain');
    expect(jainDarshan.framing, SiteFraming.neutral);
    expect(jainDarshan.framingLabel, isNull);
  });

  test('negated worship phrases stay neutral, including past 48 characters', () {
    const negated = <String>[
      'The old puja discontinued after the shrine closed.',
      'Puja has been discontinued and the sanctum is empty.',
      'This courtyard was once worshipped.',
      'This courtyard was once widely worshipped.',
      'A historic puja is all the notes record.',
      'A historical aarti is mentioned only as a past custom.',
      'The former puja is no longer held.',
      'There is no surviving inscription or local memory of a daily puja on this site.',
    ];
    for (final description in negated) {
      final honesty = DetailHonesty.of(
        _draft(
          description: description,
          timings: 'Open daily 6:00 AM–8:00 PM.',
        ),
      );
      expect(honesty.framing, SiteFraming.neutral, reason: description);
      expect(honesty.framingLabel, isNull, reason: description);
    }

    final living = DetailHonesty.of(
      _draft(
        description: 'Darshan begins after dawn and the puja is current.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(living.framing, SiteFraming.livingTemple);
    expect(living.framingLabel, 'Living temple');
  });

  test('worship words are whole words, so Darshana is not darshan', () {
    final darshana = DetailHonesty.of(
      _draft(
        deity: 'Darshana',
        description:
            'The listing uses the name Darshana and no worship schedule.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(darshana.framing, SiteFraming.neutral);
    expect(darshana.framingLabel, isNull);

    final pujari = DetailHonesty.of(
      _draft(
        description: 'Pujari families live on the street beside the gate.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(pujari.framing, SiteFraming.neutral);

    final artisanal = DetailHonesty.of(
      _draft(
        description: 'Artisanal stonework covers the doorway.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(artisanal.framing, SiteFraming.neutral);
  });

  test('Buddhist and Sikh tradition wins over worship words', () {
    final buddhist = DetailHonesty.of(
      _draft(
        deity: 'Buddha',
        description: 'A Buddhist pilgrimage shrine.',
        timings: 'Darshan time 8:00 AM–5:00 PM.',
      ),
    );
    expect(buddhist.tradition, SiteTradition.buddhist);
    expect(buddhist.traditionLabel, 'Buddhist');
    expect(buddhist.framing, SiteFraming.neutral);
    expect(buddhist.framingLabel, isNull);

    final sikh = DetailHonesty.of(
      _draft(
        name: 'Example Gurdwara',
        deity: 'Guru Nanak',
        description: 'A gurdwara listed in the directory.',
        timings: 'Darshan time 4:00 AM–10:00 PM.',
      ),
    );
    expect(sikh.tradition, SiteTradition.sikh);
    expect(sikh.traditionLabel, 'Sikh');
    expect(sikh.framing, SiteFraming.neutral);
    expect(sikh.framingLabel, isNull);
  });

  test('KAN-103 comment 10395 tightens living-worship claims', () {
    final noVip = DetailHonesty.of(
      _draft(
        description: 'No-VIP darshan for all.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(noVip.framing, SiteFraming.livingTemple, reason: 'No-VIP darshan');
    expect(noVip.framingLabel, 'Living temple');

    final semicolon = DetailHonesty.of(
      _draft(
        description: 'No photography; darshan 6am to noon.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(
      semicolon.framing,
      SiteFraming.livingTemple,
      reason: 'semicolon starts a new clause',
    );

    final unrelatedNot = DetailHonesty.of(
      _draft(
        description: 'Not crowded on weekdays and darshan runs till 9pm.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(
      unrelatedNot.framing,
      SiteFraming.livingTemple,
      reason: 'not before and does not cancel darshan',
    );

    final traditionCases = <(String, String)>[
      ('A Buddhist temple with daily puja.', 'Shiva'),
      ('A Jain temple with daily puja.', 'Shiva'),
      ('A gurdwara with daily puja.', 'Guru Nanak'),
    ];
    for (final (description, deity) in traditionCases) {
      final honesty = DetailHonesty.of(
        _draft(
          deity: deity,
          description: description,
          timings: 'Open daily 6:00 AM–8:00 PM.',
        ),
      );
      expect(honesty.framing, SiteFraming.neutral, reason: description);
      expect(honesty.framingLabel, isNull, reason: description);
    }

    final comma = DetailHonesty.of(
      _draft(
        description: 'No entry fee, 5.30 am darshan.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(comma.framing, SiteFraming.livingTemple, reason: 'comma clause');

    for (final description in const [
      'No darshan, puja or aarti today.',
      'No aarti, darshan or puja is held.',
    ]) {
      final listed = DetailHonesty.of(
        _draft(
          description: description,
          timings: 'Open daily 6:00 AM–8:00 PM.',
        ),
      );
      expect(listed.framing, SiteFraming.neutral, reason: description);
      expect(listed.framingLabel, isNull, reason: description);
    }

    final wasOnce = DetailHonesty.of(
      _draft(
        description: 'Ruined temple where puja was once performed.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(wasOnce.framing, SiteFraming.monumentVisit, reason: 'was once');

    final noMore = DetailHonesty.of(
      _draft(
        description:
            'Ruins of a temple, once worshipped, now a puja site no more.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(noMore.framing, SiteFraming.monumentVisit, reason: 'no more');

    final deniedAfter = DetailHonesty.of(
      _draft(
        description: 'Closed to worship, darshan not allowed.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(deniedAfter.framing, SiteFraming.neutral, reason: 'not allowed');
    expect(deniedAfter.framingLabel, isNull);

    final ruinedCeased = DetailHonesty.of(
      _draft(
        description: 'The shrine is in ruins. The former puja discontinued.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(ruinedCeased.framing, SiteFraming.monumentVisit);

    final asiMonument = DetailHonesty.of(
      _draft(
        description: 'ASI protected monument.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(asiMonument.framing, SiteFraming.neutral);
    expect(asiMonument.framingLabel, isNull);

    expect(
      DetailHonesty.of(_named('Biraja Temple')).framing,
      SiteFraming.neutral,
    );
    expect(
      DetailHonesty.of(_named('Patan Devi Temple')).framing,
      SiteFraming.neutral,
    );

    for (final description in const [
      'No St. darshan is offered.',
      'No A.D. puja is recorded.',
      'No 5.30 darshan slot is published.',
    ]) {
      final honesty = DetailHonesty.of(
        _draft(
          description: description,
          timings: 'Open daily 6:00 AM–8:00 PM.',
        ),
      );
      expect(honesty.framing, SiteFraming.neutral, reason: description);
    }

    final afterAbbreviation = DetailHonesty.of(
      _draft(
        description: 'Closed in A.D. 800. Darshan begins at dawn.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(afterAbbreviation.framing, SiteFraming.livingTemple);

    // Kiriteswari is a living Shakti Peetha, but the heuristic misses it.
    // "worshipped" is not a worship-word hit, and Durga Puja / Kali Puja are
    // festival titles in the "No official daily clock" timings. That miss is
    // not a regression. Do not special-case this temple by name.
    final kiriteswari = DetailHonesty.of(_named('Kiriteswari Temple'));
    expect(kiriteswari.framing, SiteFraming.neutral);
    expect(kiriteswari.framingLabel, isNull);

    expect(
      DetailHonesty.of(_named('Martand Sun Temple')).framing,
      SiteFraming.monumentVisit,
    );
    expect(
      DetailHonesty.of(_named('Shore Temple')).framing,
      SiteFraming.monumentVisit,
    );
  });

  test('Vadakkunnathan stays living on the pooja board', () {
    // Usha, Ucha, and Athazha Pooja on the daily_pooja board are present-tense
    // worship. "India-protected monument" does not force heritage.
    final honesty = DetailHonesty.of(_named('Vadakkunnathan Temple'));
    expect(honesty.framing, SiteFraming.livingTemple);
    expect(honesty.framingLabel, 'Living temple');
  });

  test('Sringeri stays living on official darshan hours', () {
    // sringeri.net lists Sharadamba darshan and Chandramoulishwara puja.
    // "ASI heritage interest" does not force heritage.
    final honesty = DetailHonesty.of(_named('Sringeri Sharada Peetham'));
    expect(honesty.framing, SiteFraming.livingTemple);
    expect(honesty.framingLabel, 'Living temple');
  });

  test('Panchvaktra stays living because daily worship continues', () {
    // "Daily worship continues" is present tense even when the clock is
    // provisional. ASI protection alone does not force heritage.
    final honesty = DetailHonesty.of(_named('Panchvaktra Temple'));
    expect(honesty.framing, SiteFraming.livingTemple);
    expect(honesty.framingLabel, 'Living temple');
  });

  test('Jogulamba stays living on restored Peetha worship', () {
    // "monument visiting" is the Navabrahma note, not "monument visit".
    // "living Peetha" is the restored worship.
    final honesty = DetailHonesty.of(_named('Jogulamba Temple'));
    expect(honesty.framing, SiteFraming.livingTemple);
    expect(honesty.framingLabel, 'Living temple');
  });

  test('Keesaragutta stays living when ruins name the hill archaeology', () {
    // "Excavations have revealed ... ruins" describes the hill dig, not the
    // shrine. Morning and evening darshan and abhishekam stay living.
    final honesty = DetailHonesty.of(_named('Keesaragutta Temple'));
    expect(honesty.framing, SiteFraming.livingTemple);
    expect(honesty.framingLabel, 'Living temple');
  });

  test(
    'present-tense darshan or puja wins over ASI, protection, and ruins',
    () {
      const probes = <String>[
        'ASI protected temple. Darshan 6 am to 12 noon and 4 pm to 8 pm daily.',
        'Protected monument with daily puja and darshan 6am to 8pm.',
        'Ruins of a temple; puja held daily at the shrine.',
      ];
      for (final description in probes) {
        final honesty = DetailHonesty.of(
          _draft(
            description: description,
            timings: 'Open daily 6:00 AM–8:00 PM.',
          ),
        );
        expect(honesty.framing, SiteFraming.livingTemple, reason: description);
        expect(honesty.framingLabel, 'Living temple', reason: description);
      }
    },
  );

  test('Sikh precedence keeps present-tense puja non-living', () {
    final sikh = DetailHonesty.of(
      _draft(
        deity: 'Guru Nanak',
        description: 'Daily puja and darshan 6am to 8pm.',
        timings: 'Open daily 6:00 AM–8:00 PM.',
      ),
    );
    expect(sikh.tradition, SiteTradition.sikh);
    expect(sikh.traditionLabel, 'Sikh');
    expect(sikh.framing, SiteFraming.neutral);
    expect(sikh.framingLabel, isNull);
  });

  test('Jain and Buddhist sites are labeled without a Hindu-only chip', () {
    final dilwara = DetailHonesty.of(_named('Dilwara Temples'));
    expect(dilwara.tradition, SiteTradition.jain);
    expect(dilwara.traditionLabel, 'Jain');
    expect(dilwara.framingLabel, isNull);
    expect(dilwara.framing, SiteFraming.neutral);
    expect(dilwara.storyHeading, 'About this place');
    expect(dilwara.framingNote, contains('Jain pilgrimage site'));

    final mahabodhi = DetailHonesty.of(_named('Mahabodhi Temple'));
    expect(mahabodhi.tradition, SiteTradition.buddhist);
    expect(mahabodhi.traditionLabel, 'Buddhist');
    expect(mahabodhi.framing, SiteFraming.neutral);
    expect(mahabodhi.framingLabel, isNull);
    expect(mahabodhi.framingNote, contains('Buddhist pilgrimage site'));
    expect(mahabodhi.storyHeading, 'About this place');

    expect(
      DetailHonesty.of(_named('Sri Manjunatha Temple, Dharmasthala')).tradition,
      SiteTradition.unspecified,
    );
    expect(
      DetailHonesty.of(_named('Keesaragutta Temple')).tradition,
      SiteTradition.unspecified,
    );
    expect(
      DetailHonesty.of(_named('Manikaran Shiva Temple')).tradition,
      SiteTradition.unspecified,
    );
  });

  testWidgets('detail honesty UI shows Jain framing without Photo pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Dilwara Temples')),
        ),
      ),
    );
    await tester.pump();

    // KAN-77: Commons gallery clears Photo pending.
    expect(find.text('Photo pending'), findsNothing);
    expect(find.text('No verified photograph is on file.'), findsNothing);
    expect(find.byKey(const Key('detail-tradition-chip')), findsOneWidget);
    expect(find.text('Jain'), findsWidgets);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.text('About this place'), findsOneWidget);
    expect(find.text('Temple story'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(find.text('Get Directions'), findsOneWidget);
    expect(find.byKey(const Key('detail-timings-body')), findsOneWidget);
    expect(find.textContaining('06:00 AM'), findsWidgets);
    expect(find.text('Admin Panel'), findsNothing);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('monument visit and missing hours stay honest', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Martand Sun Temple')),
        ),
      ),
    );
    await tester.pump();

    // KAN-77: Commons gallery clears Photo pending; heritage framing remains.
    expect(find.text('Photo pending'), findsNothing);
    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.text('Visiting hours'), findsOneWidget);
    expect(find.text('Site history'), findsOneWidget);
    expect(find.text('Temple story'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
    expect(find.textContaining('picsum.photos'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: _draft(
              timings: '',
              description: 'Listed place with no further classification.',
              story: 'Background notes only.',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo pending'), findsOneWidget);
    expect(find.byKey(const Key('timings-caveat')), findsOneWidget);
    expect(find.textContaining('No visiting hours'), findsOneWidget);
    expect(find.text('Not listed in this entry.'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Living temple'), findsNothing);
    expect(find.text('Heritage visit'), findsNothing);
    expect(find.byKey(const Key('get-directions-button')), findsOneWidget);
  });

  testWidgets(
    'phone width lays out living-temple caveat without Photo pending',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TempleDetailBody(temple: _named('Meenakshi Amman Temple')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Photo pending'), findsNothing);
      expect(find.text('Living temple'), findsOneWidget);
      expect(find.byKey(const Key('timings-caveat')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scrolled detail title stays behind the status-bar scrim', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(temple: _named('Martand Sun Temple')),
        ),
      ),
    );
    await tester.pump();

    final scrim = find.byKey(const Key('detail-status-bar-scrim'));
    expect(scrim, findsOneWidget);
    expect(tester.getRect(scrim), const Rect.fromLTWH(0, 0, 390, 48));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -520),
    );
    await tester.pump();

    final titleTop = tester.getRect(find.text('Martand Sun Temple')).top;
    expect(titleTop, lessThan(48));
    expect(tester.getRect(scrim).bottom, greaterThan(titleTop));
    expect(tester.takeException(), isNull);
  });

  test('imageUrl matches images[0] for every gallery', () {
    for (final temple in sampleTemples) {
      if (temple.images.isEmpty) {
        expect(temple.imageUrl, isEmpty, reason: temple.name);
        continue;
      }
      expect(temple.imageUrl, temple.images.first, reason: temple.name);
    }
  });

  test('Amarnath timings are the SASB seasonal note verbatim', () {
    const expected =
        'SEASONAL ONLY — open only during the annual summer Shri Amarnathji Yatra (roughly July–August; 2026: 3 July–28 August, per SASB). Closed and inaccessible the rest of the year. Dates change every year — check jksasb.nic.in before planning.';
    expect(_named('Amarnath Cave Temple').timings, expected);
    expect(expected, isNot(contains('6:00 AM')));
    expect(expected, isNot(contains('Baltal')));
  });

  test('Pashupatinath Mandsaur uses the category pack once each', () {
    final temple = _named('Pashupatinath Temple');
    expect(temple.city, 'Mandsaur');
    expect(temple.images, hasLength(6));
    expect(temple.images.toSet(), hasLength(6));
    expect(temple.photos, hasLength(6));
    expect(temple.imageUrl, temple.images.first);
    expect(temple.images.join('\n'), isNot(contains('Madhya_Pradesh_001')));
    expect(temple.photos[0].credit, 'Rohit MDS · CC BY-SA 4.0');
    expect(temple.photos[0].licence, PhotoLicence.ccBySa);
    expect(temple.photos[0].order, 0);
    expect(temple.photos[4].url, contains('Statue_of_Pashupatinath_Mandsaur'));
    expect(temple.photos[4].credit, 'Rohit MDS · CC BY-SA 4.0');
    expect(temple.photos[4].licence, PhotoLicence.ccBySa);
    expect(temple.photos[4].order, 4);
    expect(
      temple.imageUrl,
      'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/76/Pashupatinath_Temple_Mandsaur.jpg/1280px-Pashupatinath_Temple_Mandsaur.jpg',
    );
    for (final url in temple.images) {
      expect(url, isNot(contains('utm_')));
      expect(url, isNot(contains('The_Pashupatinath_Temple_27')));
      expect(url, isNot(contains('Sadhu_Giving_Blessings')));
      expect(url, isNot(contains('Kathmandu')));
    }
  });

  test('promoted photos keep full CC credits beside each URL', () {
    const promoted = {
      'Chintaman Ganesh Temple': 2,
      'Janaki Temple Sitamarhi': 2,
      'Kaleshwara Mukteswara Temple': 2,
      'Mangala Gauri Temple': 1,
      'Purmandal Temple': 1,
      'Ugratara Temple': 3,
      'Akshardham Temple': 2,
    };
    for (final entry in promoted.entries) {
      final temple = _named(entry.key);
      expect(temple.images, hasLength(entry.value), reason: entry.key);
      expect(temple.photos, hasLength(entry.value), reason: entry.key);
      expect(temple.imageUrl, contains('wikimedia.org'), reason: entry.key);
      for (var i = 0; i < temple.photos.length; i++) {
        final photo = temple.photos[i];
        expect(photo.url, temple.images[i], reason: entry.key);
        expect(photo.order, i, reason: entry.key);
        expect(photo.credit, isNot(contains('…')), reason: entry.key);
        expect(photo.credit, isNot(contains('...')), reason: entry.key);
        if (photo.licence!.requiresCredit) {
          expect(photo.credit.trim(), isNotEmpty, reason: entry.key);
        }
      }
    }
    final chintaman = _named('Chintaman Ganesh Temple');
    expect(
      chintaman.photos.every(
        (photo) => photo.credit == 'Gyanendra Singh Chauhan · CC BY 3.0',
      ),
      isTrue,
    );
    expect(chintaman.photos.first.licence, PhotoLicence.ccBy);
    final purmandal = _named('Purmandal Temple');
    expect(
      purmandal.photos.single.credit,
      contains('19th-century lithograph (1847 print)'),
    );
    expect(
      visiblePhotoCredit(purmandal.photos, purmandal.imageUrl),
      contains('1847 print'),
    );
    expect(
      historicalCoverCaption(purmandal.photos, purmandal.imageUrl),
      'Lithograph, 1847',
    );
    final janaki = _named('Janaki Temple Sitamarhi');
    expect(janaki.images.join('\n'), isNot(contains('Punaura_Sitamarhi')));
    expect(janaki.images.join('\n'), isNot(contains('Punaura.gif')));
    expect(janaki.images.first, contains('Punaura_Dham.jpg'));
    expect(janaki.images.last, contains('Janaki_kund'));
  });

  test('gallery URLs do not carry utm query parameters', () {
    for (final temple in sampleTemples) {
      expect(temple.imageUrl, isNot(contains('utm_')), reason: temple.name);
      for (final url in temple.images) {
        expect(url, isNot(contains('utm_')), reason: temple.name);
      }
      for (final photo in temple.photos) {
        expect(photo.url, isNot(contains('utm_')), reason: temple.name);
      }
    }
  });

  testWidgets('CC-BY gallery credit is visible and CC0 is not', (tester) async {
    const url = 'https://upload.wikimedia.org/wikipedia/commons/example.jpg';
    Temple credited(PhotoLicence licence, String credit) {
      return Temple(
        name: 'Credit Temple',
        state: 'Gujarat',
        city: 'Gandhinagar',
        deity: 'Shiva',
        imageUrl: url,
        images: const [url],
        description: 'A place listed in the directory.',
        story: 'Notes are still being checked.',
        location: 'Temple Street',
        timings: '6:00 AM–8:00 PM daily.',
        specialities: const ['Stone gateway'],
        photos: [
          TemplePhoto(url: url, credit: credit, licence: licence, order: 0),
        ],
        latitude: 23.2,
        longitude: 72.6,
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: credited(PhotoLicence.ccBy, 'Ada Lovelace · CC BY 4.0'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('detail-photo-credit')), findsOneWidget);
    expect(find.text('Ada Lovelace · CC BY 4.0'), findsOneWidget);
    expect(find.text('Photo pending'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            temple: credited(PhotoLicence.cc0, 'Ada Lovelace'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('detail-photo-credit')), findsNothing);
  });

  testWidgets('a single stated window does not add a timings caveat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: _named('Shore Temple'))),
      ),
    );
    await tester.pump();

    expect(find.text('Heritage visit'), findsOneWidget);
    expect(find.byKey(const Key('timings-caveat')), findsNothing);
    expect(find.textContaining('6:00 AM–6:00 PM'), findsOneWidget);
    expect(find.text('Get Directions'), findsOneWidget);
  });
}
