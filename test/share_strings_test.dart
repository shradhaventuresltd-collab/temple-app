import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/temple_share.dart';

const _play =
    'https://play.google.com/store/apps/details?id=com.shradhaventures.temple';

Temple _temple({
  String name = 'Kadri Manjunath Temple',
  String city = 'Mangaluru',
  String state = 'Karnataka',
}) {
  return Temple(
    name: name,
    state: state,
    city: city,
    deity: 'Shiva',
    imageUrl: '',
    description: '',
    story: '',
    location: '',
    timings: null,
    specialities: const [],
  );
}

void main() {
  test('ARB-named constants', () {
    expect(ShareStrings.templeDetailShareButtonLabel, 'Share');
    expect(ShareStrings.templeDetailShareOnWhatsAppLabel, 'Share on WhatsApp');
    expect(
      ShareStrings.templeDetailShareTooltip,
      "Shares this place's name and an app link",
    );
    expect(
      ShareStrings.templeDetailShareUnavailable,
      "Couldn't open sharing on this device.",
    );
  });

  test('Play link is the production listing, no deep link', () {
    expect(kTempleSharePlayUrl, _play);
  });

  test('full: the spec example, three lines', () {
    expect(
      templeShareText(_temple()),
      'Kadri Manjunath Temple\n'
      'Mangaluru, Karnataka\n'
      'Found on Temple Directory India: $_play',
    );
  });

  test('missing town: state only, no stray comma', () {
    final text = templeShareText(_temple(city: '  '));
    expect(text.split('\n'), [
      'Kadri Manjunath Temple',
      'Karnataka',
      'Found on Temple Directory India: $_play',
    ]);
    expect(text, isNot(contains(', Karnataka')));
  });

  test('town equal to state is left out', () {
    expect(
      templeShareText(_temple(city: 'delhi', state: 'Delhi')).split('\n')[1],
      'Delhi',
    );
  });

  test('missing state: town only, no trailing comma', () {
    final text = templeShareText(_temple(state: ''));
    expect(text.split('\n')[1], 'Mangaluru');
    expect(text, isNot(contains('Mangaluru,')));
  });

  test('missing town and state: no place line, no comma before the link', () {
    final text = templeShareText(_temple(city: '', state: ''));
    expect(text.split('\n'), [
      'Kadri Manjunath Temple',
      'Found on Temple Directory India: $_play',
    ]);
    expect(text.split(_play).first, isNot(contains(',')));
  });

  test('padding is trimmed and the URL is left untouched', () {
    final text = ShareStrings.templeDetailShareText(
      '  Harmandir Sahib ',
      ' Amritsar ',
      ' Punjab',
      _play,
    );
    expect(text, startsWith('Harmandir Sahib\nAmritsar, Punjab\n'));
    expect(text, endsWith(_play));
  });

  test('neutral text for every tradition: no darshan, timings or claims', () {
    for (final name in [
      'Harmandir Sahib',
      'Dilwara Temples',
      'Mahabodhi Temple',
      'Meenakshi Amman Temple',
    ]) {
      final text = templeShareText(_temple(name: name)).toLowerCase();
      for (final word in ['darshan', 'puja', 'open now', 'timings', 'rating']) {
        expect(text, isNot(contains(word)), reason: '$name: $word');
      }
    }
  });
}
