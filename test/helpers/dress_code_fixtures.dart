// Shared KAN-197 fixtures. Synthetic data only: no real emails, tokens,
// device ids, or tracking parameters.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/temple_detail_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const kDressSection = Key('detail-dress-code');
const kDressHeading = Key('detail-dress-code-heading');
const kDressBody = Key('detail-dress-code-body');
const kDressSource = Key('detail-dress-code-source');
const kDressMore = Key('detail-dress-code-more');
const kDressChip = Key('dress-code-unverified-chip');
const kDressLink = Key('dress-code-source-link');
const kTimingsChip = Key('timings-unverified-chip');
const kTimingsLink = Key('timings-source-link');

const kDressRule = 'Men: dhoti. Women: saree or salwar with dupatta.';
const kDressSrc = 'https://example.org/dress';
const kTimingsSrc = 'https://example.org/t';

const kDressFields = {
  'dressCode',
  'dressCodeSourceUrl',
  'dressCodeSourceType',
  'dressCodeVerified',
};

Map<String, dynamic> dressDoc({
  Object? dressCode = kDressRule,
  Object? url = kDressSrc,
  Object? type = 'secondary',
  Object? verified = false,
  bool timingsUnverified = false,
}) {
  return {
    'id': 'shore-temple',
    'name': 'Shore Temple',
    'state': 'Tamil Nadu',
    'city': 'Mahabalipuram',
    'deity': 'Shiva',
    'imageUrl': '',
    'description': 'Pallava sea-shore shrine.',
    'story': 'Built by Rajasimha.',
    'address': 'Shore Road',
    'timings': '6:00 AM – 6:00 PM',
    'specialities': ['UNESCO'],
    'images': <String>[],
    'latitude': 12.616,
    'longitude': 80.199,
    if (timingsUnverified) 'timingsVerified': false,
    if (timingsUnverified) 'timingsSourceUrl': kTimingsSrc,
    'dressCode': ?dressCode,
    'dressCodeSourceUrl': ?url,
    'dressCodeSourceType': ?type,
    'dressCodeVerified': ?verified,
  };
}

Temple dressTemple({
  Object? dressCode = kDressRule,
  Object? url = kDressSrc,
  Object? type = 'secondary',
  Object? verified = false,
  bool timingsUnverified = false,
}) => Temple.fromMap(
  'shore-temple',
  dressDoc(
    dressCode: dressCode,
    url: url,
    type: type,
    verified: verified,
    timingsUnverified: timingsUnverified,
  ),
);

Temple noDressTemple() =>
    dressTemple(dressCode: null, url: null, type: null, verified: null);

class FakeLauncher extends UrlLauncherPlatform {
  FakeLauncher({this.result = true, this.gate});
  final bool result;
  final Completer<void>? gate;
  int launches = 0;
  final urls = <String>[];
  PreferredLaunchMode? mode;

  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches++;
    urls.add(url);
    mode = options.mode;
    if (gate != null) await gate!.future;
    return result;
  }
}

class ThrowingLauncher extends FakeLauncher {
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    throw Exception('no browser');
  }
}

/// Swaps the url_launcher platform for the test and restores it after.
FakeLauncher installLauncher(FakeLauncher launcher) {
  final original = UrlLauncherPlatform.instance;
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  return launcher;
}

Future<void> pumpDetail(
  WidgetTester t,
  Temple temple, {
  ThemeData? theme,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: TempleDetailBody(temple: temple)),
    ),
  );
  await t.pump();
}

/// The first [DecoratedBox] colour/border under [of].
BoxDecoration decorationUnder(WidgetTester t, Finder of) {
  final container = t.widget<Container>(
    find.descendant(of: of, matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}
