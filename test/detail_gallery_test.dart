import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/models/temple_index.dart';
import 'package:temple_app/models/temple_photo.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/utils/wikimedia_gallery.dart';
import 'package:temple_app/widgets/temple_image_placeholder.dart';

Temple _temple({
  required String original,
  String? galleryUrl,
  String? thumbUrl,
}) {
  return Temple(
    name: 'Shore Temple',
    state: 'Tamil Nadu',
    city: 'Mahabalipuram',
    deity: 'Shiva',
    imageUrl: original,
    images: [original],
    description: 'A place listed in the directory.',
    story: 'Notes are still being checked.',
    location: 'Temple Street',
    timings: '6:00 AM–8:00 PM daily.',
    specialities: const ['Stone gateway'],
    photos: [
      TemplePhoto(
        url: original,
        credit: 'Ada · CC BY 4.0',
        licence: PhotoLicence.ccBy,
        order: 0,
        thumbUrl: thumbUrl,
        galleryUrl: galleryUrl,
      ),
    ],
    latitude: 12.6,
    longitude: 80.2,
  );
}

void main() {
  const original = 'https://example.com/full.jpg';
  const gallery = 'https://example.com/full_1080_g2.jpg';
  const thumb = 'https://example.com/full_480_g2.jpg';

  test('detail frames use galleryUrl and credits stay on the original', () {
    final temple = _temple(
      original: original,
      galleryUrl: gallery,
      thumbUrl: thumb,
    );
    final frames = detailGalleryFrames(temple);
    expect(frames.single.displayUrl, gallery);
    expect(frames.single.sourceUrl, original);
    expect(
      detailGalleryFrames(temple, fullSizeIndexes: {0}).single.displayUrl,
      original,
    );
    expect(
      visiblePhotoCredit(temple.photos, frames.single.sourceUrl),
      'Ada · CC BY 4.0',
    );
    expect(detailGalleryZoomWantsOriginal(1.5), isFalse);
    expect(detailGalleryZoomWantsOriginal(1.51), isTrue);
    expect(
      coverThumbFor({
        'imageUrl': original,
        'images': [original],
        'photos': [
          {
            'url': original,
            'thumbUrl': thumb,
            'galleryUrl': gallery,
            'licence': 'CC0',
            'order': 0,
          },
        ],
      }),
      thumb,
    );
  });

  test('a missing or unusable galleryUrl falls back to the original', () {
    expect(
      detailGalleryFrames(_temple(original: original)).single.displayUrl,
      original,
    );
    expect(
      detailGalleryFrames(
        _temple(original: original, galleryUrl: 'http://example.com/g.jpg'),
      ).single.displayUrl,
      original,
    );
    expect(
      detailGalleryFrames(
        _temple(
          original: original,
          galleryUrl: 'https://picsum.photos/seed/a/800/600',
        ),
      ).single.displayUrl,
      original,
    );
  });

  testWidgets('the detail gallery requests galleryUrl', (tester) async {
    final temple = _temple(
      original: original,
      galleryUrl: gallery,
      thumbUrl: thumb,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: temple)),
      ),
    );
    await tester.pump();
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, gallery);
    expect(find.text('Ada · CC BY 4.0'), findsOneWidget);
  });

  testWidgets(
    'the detail gallery uses the original when galleryUrl is absent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TempleDetailBody(temple: _temple(original: original)),
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, original);
    },
  );

  testWidgets('a failed gallery image requests the original once', (
    tester,
  ) async {
    final temple = _temple(
      original: original,
      galleryUrl: gallery,
      thumbUrl: thumb,
    );
    final detailKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(key: detailKey, temple: temple),
        ),
      ),
    );
    await tester.pump();

    var image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, gallery);
    final failed = image.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      gallery,
      Exception('missing'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TempleDetailBody(key: detailKey, temple: temple),
              failed,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    image = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byKey(detailKey),
        matching: find.byType(CachedNetworkImage),
      ),
    );
    expect(image.imageUrl, original);

    final again = image.errorWidget!(
      tester.element(
        find.descendant(
          of: find.byKey(detailKey),
          matching: find.byType(CachedNetworkImage),
        ),
      ),
      original,
      Exception('missing'),
    );
    expect(again, isA<TempleImagePlaceholder>());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TempleDetailBody(key: detailKey, temple: temple),
              again,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final requested = tester
        .widgetList<CachedNetworkImage>(
          find.descendant(
            of: find.byKey(detailKey),
            matching: find.byType(CachedNetworkImage),
          ),
        )
        .map((widget) => widget.imageUrl)
        .toList();
    expect(requested, [original]);
  });

  testWidgets('a failed commons original requests that file once', (
    tester,
  ) async {
    const original =
        'https://upload.wikimedia.org/wikipedia/commons/a/a1/Keesara_gutta_main_temple_gate.jpg';
    final thumb = capLegacyWikimediaImageUrl(original);
    expect(thumb, contains('/1280px-'));
    expect(thumb, isNot(original));
    final temple = Temple(
      name: 'Keesaragutta Temple',
      state: 'Telangana',
      city: 'Keesara',
      deity: 'Shiva',
      imageUrl: original,
      images: const [original],
      description: 'A place listed in the directory.',
      story: 'Notes are still being checked.',
      location: 'Temple Street',
      timings: '6:00 AM–8:00 PM daily.',
      specialities: const ['Stone gateway'],
      latitude: 17.5,
      longitude: 78.6,
    );
    final detailKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(key: detailKey, temple: temple),
        ),
      ),
    );
    await tester.pump();

    var image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, thumb);
    final failed = image.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      thumb,
      Exception('missing'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TempleDetailBody(key: detailKey, temple: temple),
              failed,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    image = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byKey(detailKey),
        matching: find.byType(CachedNetworkImage),
      ),
    );
    expect(image.imageUrl, original);

    final again = image.errorWidget!(
      tester.element(
        find.descendant(
          of: find.byKey(detailKey),
          matching: find.byType(CachedNetworkImage),
        ),
      ),
      original,
      Exception('missing'),
    );
    expect(again, isA<TempleImagePlaceholder>());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TempleDetailBody(key: detailKey, temple: temple),
              again,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final requested = tester
        .widgetList<CachedNetworkImage>(
          find.descendant(
            of: find.byKey(detailKey),
            matching: find.byType(CachedNetworkImage),
          ),
        )
        .map((widget) => widget.imageUrl)
        .toList();
    expect(requested, [original]);
  });

  Temple twoPhotos() {
    return Temple(
      name: 'Shore Temple',
      state: 'Tamil Nadu',
      city: 'Mahabalipuram',
      deity: 'Shiva',
      imageUrl: 'https://example.com/a.jpg',
      images: const ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      description: 'A place listed in the directory.',
      story: 'Notes are still being checked.',
      location: 'Temple Street',
      timings: '6:00 AM–8:00 PM daily.',
      specialities: const ['Stone gateway'],
      photos: const [
        TemplePhoto(
          url: 'https://example.com/a.jpg',
          credit: 'Ada · CC BY 4.0',
          licence: PhotoLicence.ccBy,
          order: 0,
        ),
        TemplePhoto(
          url: 'https://example.com/b.jpg',
          credit: 'Ben · CC BY 4.0',
          licence: PhotoLicence.ccBy,
          order: 1,
        ),
      ],
      latitude: 12.6,
      longitude: 80.2,
    );
  }

  testWidgets('auto-advance pauses while the app is not visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: twoPhotos())),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('2 / 2'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5, milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('a user swipe restarts the auto-advance interval', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: twoPhotos())),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 / 2'), findsOneWidget);

    // The old 5s tick would land here and wrap back to the first photo.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 / 2'), findsOneWidget);

    // Auto-advance still resumes, one interval after the swipe settled.
    var resumed = false;
    for (var i = 0; i < 8 && !resumed; i++) {
      await tester.pump(const Duration(seconds: 1));
      resumed = find.text('1 / 2').evaluate().isNotEmpty;
    }
    expect(resumed, isTrue);
  });

  testWidgets('auto-advance pauses while another route covers the gallery', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(body: TempleDetailBody(temple: twoPhotos())),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('viewer')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('viewer'), findsOneWidget);
    expect(find.text('2 / 2', skipOffstage: false), findsNothing);
    expect(find.text('1 / 2', skipOffstage: false), findsOneWidget);

    navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 5, milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('auto-advance pauses when the gallery is scrolled off screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: twoPhotos())),
      ),
    );
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(find.text('1 / 2'), const Offset(0, -900));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('2 / 2'), findsNothing);
  });

  testWidgets('auto-advance resumes when a resize brings the gallery back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TempleDetailBody(temple: twoPhotos())),
      ),
    );
    await tester.pump();
    await tester.drag(find.text('1 / 2'), const Offset(0, -900));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 / 2'), findsOneWidget);

    tester.view.physicalSize = const Size(400, 8000);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5, milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('the photo credit clamps when the gallery shrinks', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(key: key, temple: twoPhotos()),
        ),
      ),
    );
    await tester.pump();
    // A chevron animation races the image error relayout in tests and snaps
    // back. Move to the second photo directly, which is the state that used
    // to index off the end when the gallery shrank.
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(1);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Ben · CC BY 4.0'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TempleDetailBody(
            key: key,
            temple: _temple(original: 'https://example.com/a.jpg'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ada · CC BY 4.0'), findsOneWidget);
    expect(find.text('Ben · CC BY 4.0'), findsNothing);
    expect(find.text('2 / 2'), findsNothing);
  });
}
