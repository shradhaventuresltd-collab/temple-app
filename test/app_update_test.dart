import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:temple_app/services/installed_build.dart';
import 'package:temple_app/services/store_platform.dart';
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
    final ok = await openStoreListing(
      platform: StorePlatform.android,
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

  test('iOS opens the App Store and then the https listing', () async {
    final opened = <Uri>[];
    final ok = await openStoreListing(
      platform: StorePlatform.ios,
      packageName: 'com.shradhaventures.temple',
      appStoreId: '1234567890',
      launch: (uri) async {
        opened.add(uri);
        return uri.scheme == 'https';
      },
    );
    expect(ok, isTrue);
    expect(opened, [
      Uri.parse('itms-apps://apps.apple.com/app/id1234567890'),
      Uri.parse('https://apps.apple.com/app/id1234567890'),
    ]);
  });

  test('an itms success does not also open https', () async {
    final opened = <Uri>[];
    final ok = await openStoreListing(
      platform: StorePlatform.ios,
      packageName: 'com.shradhaventures.temple',
      appStoreId: '1234567890',
      launch: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    expect(ok, isTrue);
    expect(opened, [Uri.parse('itms-apps://apps.apple.com/app/id1234567890')]);
  });

  test('an unset App Store id does not open Play on iOS', () async {
    final opened = <Uri>[];
    Future<bool> launch(Uri uri) async {
      opened.add(uri);
      return true;
    }

    expect(kAppStoreId, kAppStoreIdPlaceholder);
    expect(appStoreIdIsSet(kAppStoreId), isFalse);
    expect(
      await openStoreListing(
        platform: StorePlatform.ios,
        packageName: 'com.shradhaventures.temple',
        launch: launch,
      ),
      isFalse,
    );
    expect(
      await openStoreListing(
        platform: StorePlatform.ios,
        packageName: 'com.shradhaventures.temple',
        appStoreId: '',
        launch: launch,
      ),
      isFalse,
    );
    expect(
      await openStoreListing(
        platform: StorePlatform.ios,
        packageName: 'com.shradhaventures.temple',
        appStoreId: 'APP_STORE_ID',
        launch: launch,
      ),
      isFalse,
    );
    expect(opened, isEmpty);
  });

  test('update copy names the store for each platform', () {
    expect(storeListingName(StorePlatform.android), 'Play Store');
    expect(storeListingName(StorePlatform.ios), 'App Store');
    expect(
      forceUpdateBody(StorePlatform.android),
      'This version of Temple Directory India is no longer supported. '
      'Install the latest version from the Play Store to continue.',
    );
    expect(
      forceUpdateBody(StorePlatform.ios),
      'This version of Temple Directory India is no longer supported. '
      'Install the latest version from the App Store to continue.',
    );
    expect(
      forceUpdateButtonLabel(StorePlatform.android),
      'Update on Play Store',
    );
    expect(forceUpdateButtonLabel(StorePlatform.ios), 'Update on App Store');
    expect(
      forceUpdateOpenFailed(StorePlatform.android),
      'Could not open the Play Store.',
    );
    expect(
      forceUpdateOpenFailed(StorePlatform.ios),
      'Could not open the App Store.',
    );
    expect(
      softUpdateMessage(StorePlatform.android),
      'A newer version is ready on the Play Store.',
    );
    expect(
      softUpdateMessage(StorePlatform.ios),
      'A newer version is ready on the App Store.',
    );
    expect(forceUpdateBody(StorePlatform.ios), isNot(contains('Play Store')));
    expect(
      softUpdateMessage(StorePlatform.android),
      isNot(contains('App Store')),
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
