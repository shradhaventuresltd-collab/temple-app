import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:temple_app/services/installed_build.dart';
import 'package:temple_app/services/update_nudge_store.dart';

void main() {
  test('build number compared with min and recommended', () {
    expect(
      updateRequirement(
        buildNumber: 4,
        minSupportedBuild: 5,
        recommendedBuild: 8,
      ),
      UpdateRequirement.hard,
    );
    expect(
      updateRequirement(
        buildNumber: 6,
        minSupportedBuild: 5,
        recommendedBuild: 8,
      ),
      UpdateRequirement.soft,
    );
    expect(
      updateRequirement(
        buildNumber: 8,
        minSupportedBuild: 5,
        recommendedBuild: 8,
      ),
      UpdateRequirement.none,
    );
    expect(
      updateRequirement(
        buildNumber: null,
        minSupportedBuild: 99,
        recommendedBuild: 99,
      ),
      UpdateRequirement.none,
    );
  });

  test('Play listing uses the demo application id when the suffix is on', () {
    expect(
      playStorePackageName(demoAppIdSuffix: false),
      'com.shradhaventures.temple',
    );
    expect(
      playStorePackageName(demoAppIdSuffix: true),
      'com.shradhaventures.temple.demo',
    );
    expect(
      playStoreMarketUri('com.shradhaventures.temple.demo'),
      Uri.parse('market://details?id=com.shradhaventures.temple.demo'),
    );
    expect(
      playStoreHttpsUri('com.shradhaventures.temple'),
      Uri.parse(
        'https://play.google.com/store/apps/details?id=com.shradhaventures.temple',
      ),
    );
  });

  test('market failure falls back to the https listing', () async {
    final opened = <Uri>[];
    final ok = await openPlayStoreListing(
      packageName: 'com.shradhaventures.temple.demo',
      launch: (uri) async {
        opened.add(uri);
        return uri.scheme == 'https';
      },
    );
    expect(ok, isTrue);
    expect(opened.map((uri) => uri.scheme), ['market', 'https']);
    expect(
      opened.last.queryParameters['id'],
      'com.shradhaventures.temple.demo',
    );
  });

  test('a nudge is shown at most once per session and once per day', () async {
    final store = MemoryUpdateNudgeStore();
    final now = DateTime.utc(2026, 10, 16, 9);
    final nudge = SoftUpdateNudge();
    expect(await nudge.claim(store, now), isTrue);
    expect(await nudge.claim(store, now), isFalse);

    final sameDay = SoftUpdateNudge();
    expect(
      await sameDay.claim(store, now.add(const Duration(hours: 3))),
      isFalse,
    );

    final nextDay = SoftUpdateNudge();
    expect(
      await nextDay.claim(store, now.add(const Duration(days: 1))),
      isTrue,
    );
  });

  test('package info failures fail open', () async {
    expect(
      await readInstalledBuildNumber(readBuildNumber: () async => '42'),
      42,
    );
    expect(
      await readInstalledBuildNumber(readBuildNumber: () async => '1.0'),
      isNull,
    );
    expect(
      await readInstalledBuildNumber(
        readBuildNumber: () async => throw StateError('plugin missing'),
      ),
      isNull,
    );
    expect(
      await readInstalledBuildNumber(
        readBuildNumber: () => Completer<String>().future,
        timeout: const Duration(milliseconds: 20),
      ),
      isNull,
    );
  });
}
