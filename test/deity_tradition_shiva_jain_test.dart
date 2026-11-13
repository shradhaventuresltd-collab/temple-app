// Ux bug on main 6257f3ffadcbd6b3b2f5551ef9c3bdcb51bd5221: the Deity sheet's
// "Shiva" row carried a "Jain" tag and the chip read "Shiva · Jain".
//
// Cause: traditionFromDeityText matched "Tirthankaras" / "Jain" anywhere in
// the deity text, so mixed or Hindu-led listings such as Badami Cave Temples
// ("Shiva, Vishnu and Tirthankaras") resolved Jain. They group under
// "Shiva", and one Jain member was enough to label the whole group.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/utils/deity_groups.dart';
import 'package:temple_app/utils/detail_honesty.dart';
import 'package:temple_app/utils/directory_filters.dart';

import 'filter_sheet_support.dart';

Temple _listing(String name, String deity, {String? tradition}) {
  return filterTemple(
    name: name,
    state: 'Karnataka',
    city: 'Badami',
    deity: deity,
    tradition: tradition,
  );
}

void main() {
  group('traditionFromDeityText', () {
    test('Hindu-led and mixed deity text is not Jain/Buddhist', () {
      for (final deity in [
        'Shiva',
        'Shiva (Sikharagiriswara)',
        'Shiva, Vishnu and Tirthankaras',
        'Shiva, with historic Vishnu and Jain associations on the same hill',
        'Shiva lingas; Hindu, Buddhist and Jain images (archaeological)',
        'Hindu and Buddhist images (archaeological)',
        'Deities of a rock-cut Hindu shrine with a Jain past',
        'Vishnu (Ananthapadmanabha), with Jain tirthankara reliefs',
        'Devi — Jain-era cave reused',
        'Hanuman',
        'Ganesha; Buddha image in the museum',
      ]) {
        expect(
          traditionFromDeityText(deity),
          SiteTradition.unspecified,
          reason: deity,
        );
        expect(listedDeityTraditionLabel(deity), isNull, reason: deity);
      }
    });

    test('true Jain deities still resolve Jain', () {
      for (final deity in [
        'Mahavira (Jain Tirthankara)',
        'Mahavira (Jain)',
        'Parshvanatha (Jain Tirthankara)',
        'Parshvanatha — Jain',
        'Parshvanatha; Nakoda Bhairava (Jain)',
        'Rishabhanatha — Jain',
        'Adinath (Rishabhanatha), Jain Tirthankara; Chakreshvari Devi',
        'Padmaprabha (6th Tirthankara); Ghantakarna Mahavir',
        'Jain Tirthankaras',
        'Tirthankaras',
        'Jain tirthankaras in the rock-cut shrine, with a later Hindu '
            'Bhagavati temple beside it',
      ]) {
        expect(
          traditionFromDeityText(deity),
          SiteTradition.jain,
          reason: deity,
        );
      }
    });

    test('Buddhist and Sikh deity text is unchanged', () {
      expect(traditionFromDeityText('Buddha'), SiteTradition.buddhist);
      expect(
        traditionFromDeityText('Buddhist — Maitreya (Chamba)'),
        SiteTradition.buddhist,
      );
      expect(
        traditionFromDeityText('Guru Granth Sahib (Sikh gurdwara)'),
        SiteTradition.sikh,
      );
      // The tradition in the lead wins over a later name.
      expect(
        traditionFromDeityText(
          'Sikh gurdwara - Guru Granth Sahib (associated with Baba Buddha)',
        ),
        SiteTradition.sikh,
      );
    });

    test('a bare "Mahavir" is not read as Jain (Hanuman is also Mahavir)', () {
      expect(traditionFromDeityText('Mahavir'), SiteTradition.unspecified);
      // A stored field still makes a Jain listing Jain.
      expect(
        directoryTraditionKey(
          _listing('Mahavir Jain Mandir', 'Mahavir', tradition: 'jain'),
        ),
        'jain',
      );
    });
  });

  group('deity groups', () {
    final somnath = _listing('Somnath Temple', 'Shiva');
    final badami = _listing(
      'Badami Cave Temples',
      'Shiva, Vishnu and Tirthankaras',
    );
    final jainCave = _listing(
      'Jain Cave Shrine',
      'Shiva (later image in a Jain cave)',
      tradition: 'jain',
    );
    final dilwara = _listing(
      'Dilwara Temples',
      'Rishabhanatha',
      tradition: 'jain',
    );
    final ranakpur = _listing(
      'Ranakpur Jain Temple',
      'Rishabhanatha (Adinatha, Jain Tirthankara)',
    );

    test('the Shiva group has no tradition label', () {
      final listed = [somnath, badami, dilwara];
      final groups = groupDeityNames(
        directoryDeitiesFrom(listed),
        traditionOf: traditionOfLoadedTemples(listed),
      );
      final byLabel = {for (final g in groups) g.label: g.tradition};
      expect(byLabel['Shiva'], isNull);
      expect(byLabel['Rishabhanatha'], 'Jain');
      expect(
        directoryDeityChipLabel('Shiva', tradition: byLabel['Shiva']),
        'Shiva',
      );
    });

    test('one stored-Jain listing does not label a mixed group', () {
      final listed = [somnath, jainCave];
      expect(traditionOfLoadedTemples(listed)('Shiva'), isNull);
      final groups = groupDeityNames(
        directoryDeitiesFrom(listed),
        traditionOf: traditionOfLoadedTemples(listed),
      );
      expect(groups.single.tradition, isNull);
    });

    test('a group whose every listing is Jain keeps the Jain label', () {
      final listed = [dilwara, ranakpur];
      expect(traditionOfLoadedTemples(listed)('Rishabhanatha'), 'Jain');
      expect(
        groupDeityNames(
          directoryDeitiesFrom(listed),
          traditionOf: traditionOfLoadedTemples(listed),
        ).single.tradition,
        'Jain',
      );
    });

    test('text fallback needs every spelling to agree', () {
      expect(
        groupDeityNames([
          'Shiva',
          'Shiva, Vishnu and Tirthankaras',
        ]).single.tradition,
        isNull,
      );
      expect(
        groupDeityNames([
          'Parshvanatha (Jain Tirthankara)',
          'Parshvanatha — Jain',
        ]).single.tradition,
        'Jain',
      );
    });
  });

  group('Deity sheet', () {
    final listed = [
      _listing('Somnath Temple', 'Shiva'),
      _listing('Badami Cave Temples', 'Shiva, Vishnu and Tirthankaras'),
      _listing(
        'Vijayalaya Choleeswaram',
        'Shiva, with historic Vishnu and Jain associations on the same hill',
      ),
      _listing(
        'Jain Cave Shrine',
        'Shiva (later image in a Jain cave)',
        tradition: 'jain',
      ),
      _listing('Dilwara Temples', 'Rishabhanatha', tradition: 'jain'),
      _listing('Meenakshi Amman Temple', 'Devi'),
    ];

    Finder deityRow(String label) =>
        find.byKey(Key('filter-option-deity-$label'));
    Finder inRow(String label, String text) =>
        find.descendant(of: deityRow(label), matching: find.text(text));
    Finder chipText(String text) => find.descendant(
      of: find.byKey(const Key('filter-chip-deity')),
      matching: find.text(text),
    );

    testWidgets(
      'Shiva row has no Jain tag; pick, reopen, and combine with Tradition',
      (tester) async {
        await pumpFilterBar(tester, temples: listed);

        // Open the sheet: Shiva is untagged, a real Jain deity keeps its tag.
        await openFilterChip(tester, 'deity');
        expect(deityRow('Shiva'), findsOneWidget);
        expect(inRow('Shiva', 'Jain'), findsNothing);
        expect(inRow('Rishabhanatha', 'Jain'), findsOneWidget);

        // Pick Shiva: the chip reads just "Shiva".
        await chooseAndApply(tester, const Key('filter-option-deity-Shiva'));
        expect(chipText('Shiva'), findsOneWidget);
        expect(find.text('Shiva · Jain'), findsNothing);
        expect(find.textContaining('· Jain'), findsNothing);
        expect(find.text('Somnath Temple'), findsOneWidget);
        expect(find.text('Badami Cave Temples'), findsOneWidget);
        expect(find.text('Jain Cave Shrine'), findsOneWidget);
        expect(find.text('Dilwara Temples'), findsNothing);

        // Reopen: still selected, still untagged.
        await openFilterChip(tester, 'deity');
        expect(deityRow('Shiva'), findsOneWidget);
        expect(inRow('Shiva', 'Jain'), findsNothing);
        await applyFilterSheet(tester);
        expect(chipText('Shiva'), findsOneWidget);

        // Combine with Tradition = Hindu: mixed-text Shiva sites stay Hindu.
        await openFilterChip(tester, 'tradition');
        await chooseAndApply(
          tester,
          const Key('filter-option-tradition-hindu'),
        );
        expect(chipText('Shiva'), findsOneWidget);
        expect(find.text('Somnath Temple'), findsOneWidget);
        expect(find.text('Badami Cave Temples'), findsOneWidget);
        expect(find.text('Vijayalaya Choleeswaram'), findsOneWidget);
        expect(find.text('Jain Cave Shrine'), findsNothing);

        // Tradition = Jain: only the stored-Jain listing; chip unchanged.
        await openFilterChip(tester, 'tradition');
        await chooseAndApply(tester, const Key('filter-option-tradition-jain'));
        expect(chipText('Shiva'), findsOneWidget);
        expect(find.text('Shiva · Jain'), findsNothing);
        expect(find.text('Jain Cave Shrine'), findsOneWidget);
        expect(find.text('Badami Cave Temples'), findsNothing);
        expect(find.text('Somnath Temple'), findsNothing);
      },
    );
  });
}
