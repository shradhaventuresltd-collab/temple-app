import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/data/sample_data.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/temple_search.dart';

void main() {
  Temple temple({
    required String name,
    String deity = 'Devi',
    String city = 'Madurai',
    String state = 'Tamil Nadu',
    String location = 'Temple Street',
  }) {
    return Temple(
      name: name,
      state: state,
      city: city,
      deity: deity,
      imageUrl: '',
      description: '',
      story: '',
      location: location,
      timings: '',
      specialities: const [],
      latitude: 0,
      longitude: 0,
    );
  }

  List<String> names(List<Temple> temples, String query) {
    return filterTemples(temples, query: query).map((t) => t.name).toList();
  }

  test('vishnu finds Balaji temples and balaji skips a plain Perumal', () {
    final balaji = temple(name: 'Balaji Shrine', deity: 'Venkateswara');
    final perumal = temple(name: 'Perumal Koil', deity: 'Perumal');

    expect(names([balaji, perumal], 'vishnu'), [
      'Perumal Koil',
      'Balaji Shrine',
    ]);
    expect(names([perumal, balaji], 'balaji'), ['Balaji Shrine']);
  });

  test('krishna stays ahead of a one-way Jagannath hit', () {
    final jagannath = temple(name: 'Jagannath Shrine', deity: 'Jagannath');
    final krishna = temple(name: 'Krishna Shrine', deity: 'Krishna');

    expect(names([jagannath, krishna], 'krishna'), [
      'Krishna Shrine',
      'Jagannath Shrine',
    ]);
    expect(names([krishna, jagannath], 'jagannath'), ['Jagannath Shrine']);
  });

  test('durga skips Kali-only temples and devi returns both', () {
    final kali = temple(name: 'Kali Shrine', deity: 'Kali');
    final durga = temple(name: 'Durga Shrine', deity: 'Durga');
    final amman = temple(name: 'Amman Shrine', deity: 'Amman');

    expect(names([kali, durga], 'durga'), ['Durga Shrine']);
    expect(names([kali, durga], 'devi'), ['Kali Shrine', 'Durga Shrine']);
    expect(names([kali, amman], 'devi').first, 'Amman Shrine');
  });

  test('murugan does not return an Ayyappa-only temple', () {
    final ayyappa = temple(name: 'Ayyappa Shrine', deity: 'Ayyappa');
    final murugan = temple(name: 'Murugan Shrine', deity: 'Murugan');

    expect(names([ayyappa, murugan], 'murugan'), ['Murugan Shrine']);
    expect(names([ayyappa], 'subramanya'), isEmpty);
    expect(
      filterTemples(sampleTemples, query: 'murugan').map((t) => t.name),
      isNot(contains('Sabarimala Ayyappan Temple')),
    );
  });

  test('govinda reaches Krishna and Venkateswara, not every Vishnu', () {
    final krishna = temple(name: 'Krishna Shrine', deity: 'Krishna');
    final balaji = temple(name: 'Balaji Shrine', deity: 'Venkateswara');
    final perumal = temple(name: 'Perumal Koil', deity: 'Perumal');

    expect(names([perumal, krishna, balaji], 'govinda'), [
      'Krishna Shrine',
      'Balaji Shrine',
    ]);
  });

  test('short deity tokens do not match inside a longer word', () {
    final sivakasi = temple(
      name: 'Sivakasi Temple',
      city: 'Sivakasi',
      deity: 'Murugan',
    );
    final kalina = temple(
      name: 'Kalina Temple',
      city: 'Kalina',
      deity: 'Ganesha',
    );
    final ramanathapuram = temple(
      name: 'Coast Temple',
      city: 'Ramanathapuram',
      deity: 'Shiva',
    );
    final kumaraswamy = temple(name: 'Kumaraswamy Temple', deity: 'Murugan');
    final maathru = temple(name: 'Maathru Hall', deity: 'Shiva');
    final lingaraj = temple(name: 'Lingaraj Hall', deity: 'Surya');
    final linga = temple(name: 'Linga Shrine', deity: 'Linga');

    expect(names([sivakasi], 'shiv'), isEmpty);
    expect(names([kalina], 'kali'), isEmpty);
    expect(names([ramanathapuram], 'rama'), isEmpty);
    expect(names([kumaraswamy], 'uma'), isEmpty);
    expect(names([maathru], 'maa'), isEmpty);
    expect(names([lingaraj], 'linga'), isEmpty);
    expect(names([linga], 'linga'), ['Linga Shrine']);
    expect(
      filterTemples(sampleTemples, query: 'rama').map((t) => t.name),
      isNot(contains('Ramanathaswamy Temple')),
    );
  });
}
