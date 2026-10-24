import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/app_locale.dart';
import 'package:temple_app/models/photo_licence.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/admin_temple_form_screen.dart';
import 'package:temple_app/services/photo_thumb_encoder.dart';
import 'package:temple_app/services/temple_photo_upload.dart';
import 'package:temple_app/widgets/admin_photo_grid.dart';

import 'helpers/fake_admin_temple_service.dart';

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Temple _temple() {
  return const Temple(
    id: 'test-temple',
    name: 'Test Temple',
    state: 'Tamil Nadu',
    city: 'Madurai',
    deity: 'Devi',
    imageUrl: '',
    description: 'A test shrine',
    story: 'Story',
    location: 'Madurai Main',
    timings: '6:00 AM – 8:00 PM',
    specialities: ['Test chip'],
    latitude: 9.9,
    longitude: 78.1,
  );
}

AdminPhotoDraft _draft({
  required String id,
  PhotoLicence? licence,
  String credit = '',
  int order = 0,
}) {
  return AdminPhotoDraft(
    id: id,
    url: 'https://example.com/$id.jpg',
    bytes: _png,
    credit: credit,
    licence: licence,
    order: order,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeAdminTempleService api,
  required List<AdminPhotoDraft> drafts,
  Size surface = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      home: AdminTempleFormScreen(
        adminTemples: api,
        existing: _temple(),
        initialDrafts: drafts,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('needs-licence badge, cover chip, and Save stays disabled', (
    tester,
  ) async {
    final api = FakeAdminTempleService();
    await _pump(
      tester,
      api: api,
      surface: const Size(360, 800),
      drafts: [
        _draft(id: 'cover'),
        _draft(id: 'second', licence: PhotoLicence.cc0, order: 1),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Needs licence'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);
    expect(find.text('+ Add photo'), findsOneWidget);
    expect(find.byKey(const Key('admin-photo-save-blocked')), findsOneWidget);

    final save = tester.widget<FilledButton>(
      find.byKey(const Key('admin-temple-save-button')),
    );
    expect(save.onPressed, isNull);

    final remove = tester.getSize(
      find.byKey(const Key('admin-photo-remove-0')),
    );
    expect(remove.width, greaterThanOrEqualTo(48));
    expect(remove.height, greaterThanOrEqualTo(48));

    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();
    expect(api.updateCalls, 0);
  });

  testWidgets('a picsum cover is not a tile and save stays photo pending', (
    tester,
  ) async {
    final api = FakeAdminTempleService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: AdminTempleFormScreen(
          adminTemples: api,
          existing: _temple().copyWith(
            imageUrl: 'https://picsum.photos/seed/desk/800/600',
            images: const ['https://picsum.photos/seed/desk/800/600'],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Needs licence'), findsNothing);
    expect(find.textContaining('Photo pending'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(api.updateCalls, 1);
    expect(api.lastUpdated!.imageUrl, isEmpty);
    expect(api.lastUpdated!.images, isEmpty);
    expect(api.lastUpdated!.photos, isEmpty);
    expect(api.lastUpdated!.writePhotos, isTrue);
  });

  testWidgets('a failed upload shows Retry and blocks Save', (tester) async {
    final failed = _draft(id: 'cover', licence: PhotoLicence.cc0)
      ..failed = true
      ..uploading = false;
    await _pump(tester, api: FakeAdminTempleService(), drafts: [failed]);

    expect(find.text('Retry'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('admin-temple-save-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.getSize(find.byKey(const Key('admin-photo-retry-0'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('CC-BY without credit keeps Save disabled', (tester) async {
    await _pump(
      tester,
      api: FakeAdminTempleService(),
      drafts: [_draft(id: 'cover', licence: PhotoLicence.ccBy)],
    );

    expect(find.text('Needs credit'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.byKey(const Key('admin-temple-save-button')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('CC0 without credit enables Save and mirrors the cover', (
    tester,
  ) async {
    final api = FakeAdminTempleService();
    await _pump(
      tester,
      api: api,
      drafts: [
        _draft(id: 'second', licence: PhotoLicence.own, order: 1),
        _draft(id: 'cover', licence: PhotoLicence.cc0, order: 0),
      ],
    );

    expect(find.text('Needs licence'), findsNothing);
    expect(find.text('Cover'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('admin-temple-save-button')),
    );
    await tester.tap(find.byKey(const Key('admin-temple-save-button')));
    await tester.pump();

    expect(api.updateCalls, 1);
    final saved = api.lastUpdated!;
    expect(saved.writePhotos, isTrue);
    expect(saved.imageUrl, 'https://example.com/cover.jpg');
    expect(saved.images, [
      'https://example.com/cover.jpg',
      'https://example.com/second.jpg',
    ]);
    expect(saved.photos.map((photo) => photo.licence).toList(), [
      PhotoLicence.cc0,
      PhotoLicence.own,
    ]);
    expect(saved.photos.map((photo) => photo.order).toList(), [0, 1]);
  });

  testWidgets('licence sheet lists five options and requires CC-BY credit', (
    tester,
  ) async {
    await _pump(
      tester,
      api: FakeAdminTempleService(),
      drafts: [_draft(id: 'cover')],
    );

    await tester.ensureVisible(find.byKey(const Key('admin-photo-licence-0')));
    await tester.tap(find.byKey(const Key('admin-photo-licence-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('admin-photo-licence-sheet')), findsOneWidget);
    for (final wire in PhotoLicence.wireValues) {
      expect(
        find.byKey(Key('admin-photo-licence-option-$wire')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const Key('admin-photo-licence-option-CC-BY')));
    await tester.pump();
    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('admin-photo-licence-apply')),
    );
    expect(apply.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('admin-photo-licence-credit')),
      'Temple photographer',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('admin-photo-licence-apply')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('admin-photo-licence-apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Needs licence'), findsNothing);
    expect(find.text('CC-BY'), findsWidgets);
  });

  testWidgets('re-upload clears a stale galleryUrl and stores the new thumb', (
    tester,
  ) async {
    const oldGallery = 'https://example.com/old_1080.jpg';
    const oldThumb = 'https://example.com/old_480.jpg';
    final draft = AdminPhotoDraft(
      id: 'cover',
      url: 'https://example.com/old.jpg',
      thumbUrl: oldThumb,
      galleryUrl: oldGallery,
      bytes: _png,
      licence: PhotoLicence.cc0,
      failed: true,
    );
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: AdminTempleFormScreen(
          adminTemples: FakeAdminTempleService(),
          existing: _temple(),
          initialDrafts: [draft],
          uploader: _ReplaceUploader(),
          thumbEncoder: _IdentityEncoder(),
        ),
      ),
    );
    await tester.pump();

    expect(draft.galleryUrl, oldGallery);
    await tester.ensureVisible(find.byKey(const Key('admin-photo-retry-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-photo-retry-0')));
    await tester.pump();
    await tester.pump();

    expect(draft.url, 'https://example.com/replaced.jpg');
    expect(draft.thumbUrl, 'https://example.com/replaced_480.jpg');
    expect(draft.galleryUrl, isNull);
    expect(draft.failed, isFalse);
    final saved = draft.toTemplePhoto().toJson();
    expect(saved.containsKey('galleryUrl'), isFalse);
    expect(saved['thumbUrl'], 'https://example.com/replaced_480.jpg');
    expect(saved['url'], 'https://example.com/replaced.jpg');
  });
}

class _IdentityEncoder implements TemplePhotoThumbEncoder {
  @override
  Future<Uint8List> encode({
    required Uint8List bytes,
    required String extension,
  }) async {
    return bytes;
  }

  @override
  Future<Uint8List> encodeFull({
    required Uint8List bytes,
    required String extension,
  }) async {
    return bytes;
  }
}

class _ReplaceUploader implements TemplePhotoUploader {
  @override
  Future<TemplePhotoUpload> upload({
    required String docId,
    required Uint8List bytes,
    required Uint8List thumbBytes,
    required String extension,
    required void Function(double progress) onProgress,
  }) async {
    onProgress(1);
    return const TemplePhotoUpload(
      url: 'https://example.com/replaced.jpg',
      thumbUrl: 'https://example.com/replaced_480.jpg',
    );
  }
}
