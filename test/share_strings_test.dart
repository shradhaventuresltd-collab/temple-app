import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/l10n/share_strings.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/services/temple_share.dart';

const _play =
    'https://play.google.com/store/apps/details?id=com.shradhaventures.temple';

Temple _temple({String city = 'Madurai', String state = 'Tamil Nadu'}) {
  return Temple(
    name: 'Meenakshi Amman Temple',
    state: state,
    city: city,
    deity: 'Devi',
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
    expect(ShareStrings.templeDetailShareTooltip, 'Share this place');
  });

  test('Play link is the production listing, no deep link', () {
    expect(kTempleSharePlayUrl, _play);
  });

  test('full: name, town and state, then the Play link', () {
    expect(
      ShareStrings.templeDetailShareText(
        'Meenakshi Amman Temple',
        'Madurai',
        'Tamil Nadu',
        _play,
      ),
      'Meenakshi Amman Temple\n'
      'Madurai, Tamil Nadu\n'
      '\n'
      "Explore India's sacred places on Temple Directory India:\n"
      '$_play',
    );
  });

  test('missing town: state only, no leading comma', () {
    final text = templeShareText(_temple(city: '  '));
    expect(text.split('\n')[1], 'Tamil Nadu');
    expect(text, isNot(contains(', Tamil Nadu')));
    expect(text, isNot(contains(',,')));
  });

  test('missing state: town only, no trailing comma', () {
    final text = templeShareText(_temple(state: ''));
    expect(text.split('\n')[1], 'Madurai');
    expect(text, isNot(contains('Madurai,')));
  });

  test('missing town and state: no place line and no comma', () {
    final text = templeShareText(_temple(city: '', state: ''));
    expect(text.split('\n').take(2).toList(), ['Meenakshi Amman Temple', '']);
    expect(text, isNot(contains(',')));
    expect(text, endsWith(_play));
  });

  test('padding is trimmed and the URL is left untouched', () {
    final text = ShareStrings.templeDetailShareText(
      '  Golden Temple ',
      ' Amritsar ',
      ' Punjab',
      _play,
    );
    expect(text, startsWith('Golden Temple\nAmritsar, Punjab\n'));
    expect(text.split('\n').last, _play);
  });
}
