// KAN-203 places wording, hero, admin-unchanged, and §2.5 footer patterns.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/near_me/near_me_copy.dart';
import 'package:temple_app/utils/directory_filters.dart';
import 'package:temple_app/utils/place_sources.dart';
import 'package:temple_app/widgets/home_mosaic_collage.dart';
import 'package:temple_app/widgets/offline_banner.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets("hero is India's Sacred Places; app name unchanged", (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeMosaicCollage(temples: [])),
      ),
    );
    expect(find.text("India's Sacred Places"), findsOneWidget);
    expect(find.text("India's Sacred Temples"), findsNothing);
    expect(find.text('Temple Directory India'), findsNothing);
  });

  test('app name strings in §2.2 stay Temple Directory', () {
    const sources = [
      'lib/main.dart',
      'lib/release_error_widget.dart',
      'lib/screens/policy_acceptance_gate.dart',
      'lib/screens/force_update_screen.dart',
      'lib/screens/home_screen.dart',
      'lib/widgets/app_drawer.dart',
      'lib/screens/maintenance_screen.dart',
    ];
    for (final path in sources) {
      final text = File(path).readAsStringSync();
      expect(text.contains('Temple Directory'), isTrue, reason: path);
    }
    expect(
      File(
        'lib/main.dart',
      ).readAsStringSync().contains('Temple Directory India'),
      isTrue,
    );
  });

  test('admin CMS strings in §2.4 stay temple-worded', () {
    const required = {
      'lib/screens/admin_screen.dart': [
        'Add temple',
        'Create temple',
        'Create a temple',
        'Delete temple?',
      ],
      'lib/screens/admin_temple_form_screen.dart': [
        'Edit temple',
        'Create temple',
      ],
      'lib/services/admin_temple_service.dart': ['Deleted temple.'],
      'lib/widgets/seed_temples_control.dart': ['Seed sample temples'],
    };
    for (final entry in required.entries) {
      final text = File(entry.key).readAsStringSync();
      for (final phrase in entry.value) {
        expect(text.contains(phrase), isTrue, reason: '${entry.key}: $phrase');
      }
    }
  });

  test('§2.1 browse and filter copy uses places, not temples', () {
    expect(directoryBrowseTitle(), directoryTitleAllPlaces);
    expect(directoryBrowseTitle(tradition: 'sikh'), directoryTitleSikhPlaces);
    expect(directoryBrowseTitle(tradition: ''), directoryTitleAllPlaces);
    expect(
      directoryBrowseTitle(tradition: 'jain', state: 'Rajasthan'),
      'Rajasthan',
    );
    expect(directoryPlaceCountLabel(0), '0 places');
    expect(directoryPlaceCountLabel(1), '1 place');
    expect(directoryPlaceCountLabel(2), '2 places');
    expect(directoryFilterResultLabel(1), 'Show 1 place');
    expect(directoryFilterResultLabel(3), 'Show 3 places');
    expect(
      directoryEmptyFilterMessage(district: 'Madurai', tradition: 'jain'),
      'Nothing in the loaded directory fits these filters.',
    );
  });

  test('§2.1 shard load error uses places', () {
    expect(
      File(
        'lib/services/firestore_read_log.dart',
      ).readAsStringSync().contains("Could not load places in"),
      isTrue,
    );
    expect(
      File(
        'lib/services/firestore_read_log.dart',
      ).readAsStringSync().contains("Could not load temples in"),
      isFalse,
    );
  });

  test('§2.1 Near me and offline copy', () {
    expect(NearMeCopy.title, 'Places near me');
    expect(
      NearMeCopy.rationaleBody,
      'Used once on your phone to sort places by distance. Never stored or sent.',
    );
    expect(NearMeCopy.locating, 'Finding places near you…');
    expect(NearMeCopy.nearestHeading, 'Nearest places');
    expect(
      NearMeCopy.noAnchorMatch,
      'None of the listings in that area have a map point.',
    );
    expect(
      OfflineBanner.message,
      "You're offline. Showing places saved on this device.",
    );
  });

  test('§2.5 footer patterns', () {
    final wiki = Uri.parse('https://en.wikipedia.org/wiki/X');
    final osm = Uri.parse('https://www.openstreetmap.org/');
    final nic = Uri.parse('https://kurukshetra.gov.in/');
    final extra = Uri.parse('https://example.net/');
    expect(placeSourceFooterLayout(const []).text, compiledFromPublicSources);
    expect(
      placeSourceFooterLayout(placeSourcesFromUrls([wiki])).text,
      'Source: en.wikipedia.org',
    );
    expect(
      placeSourceFooterLayout(placeSourcesFromUrls([wiki, osm])).text,
      'Sources: en.wikipedia.org, openstreetmap.org',
    );
    expect(
      placeSourceFooterLayout(
        placeSourcesFromUrls([wiki, osm, nic, extra]),
      ).text,
      'Sources: en.wikipedia.org, openstreetmap.org, kurukshetra.gov.in +1 more',
    );
    expect(
      placeSourcesFromUrls([wiki], official: true).single.label,
      officialTempleWebsiteLabel,
    );
  });
}
