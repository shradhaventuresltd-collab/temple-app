import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/policy_link_launcher.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('policyGateKind', () {
    final stored = PolicyAcceptance(
      version: 1,
      acceptedAt: DateTime.utc(2026, 1, 1),
    );

    test('first launch when nothing is stored', () {
      expect(
        policyGateKind(stored: null, currentVersion: 1),
        PolicyGateKind.firstLaunch,
      );
    });

    test('no gate when the stored version covers the constant', () {
      expect(policyGateKind(stored: stored, currentVersion: 1), isNull);
      expect(policyGateKind(stored: stored, currentVersion: 0), isNull);
    });

    test('policy update when the constant is greater than stored', () {
      expect(
        policyGateKind(stored: stored, currentVersion: 2),
        PolicyGateKind.policyUpdate,
      );
    });
  });

  group('policyAcceptanceFromValues', () {
    test('requires both a version and a timestamp', () {
      expect(policyAcceptanceFromValues(version: 1, acceptedAt: null), isNull);
      expect(
        policyAcceptanceFromValues(
          version: null,
          acceptedAt: '2026-01-01T00:00:00.000Z',
        ),
        isNull,
      );
      expect(
        policyAcceptanceFromValues(version: 1, acceptedAt: 'not-a-date'),
        isNull,
      );
    });

    test('parses the timestamp as UTC', () {
      final record = policyAcceptanceFromValues(
        version: 2,
        acceptedAt: '2026-10-13T12:00:00.000Z',
      );
      expect(record, isNotNull);
      expect(record!.version, 2);
      expect(record.acceptedAt, DateTime.utc(2026, 10, 13, 12));
      expect(record.acceptedAt.isUtc, isTrue);
    });
  });

  group('PolicyConfig', () {
    test('uses the hosted Terms and Privacy pages', () {
      expect(
        PolicyConfig.termsOfServiceUrl,
        'https://temple-directory-india.web.app/terms-of-service.html',
      );
      expect(
        PolicyConfig.privacyPolicyUrl,
        'https://temple-directory-india.web.app/privacy-policy.html',
      );
      expect(PolicyConfig.termsOfServiceUri.scheme, 'https');
      expect(PolicyConfig.privacyPolicyUri.scheme, 'https');
      expect(PolicyConfig.currentVersion, greaterThan(0));
    });
  });

  group('SharedPreferencesPolicyAcceptanceStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trips version and timestamp under the local keys', () async {
      final store = SharedPreferencesPolicyAcceptanceStore();
      expect(await store.read(), isNull);

      final acceptedAt = DateTime.utc(2026, 10, 13, 12, 30);
      await store.write(PolicyAcceptance(version: 4, acceptedAt: acceptedAt));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(PolicyAcceptanceKeys.version), 4);
      expect(
        prefs.getString(PolicyAcceptanceKeys.acceptedAt),
        acceptedAt.toIso8601String(),
      );

      final stored = await store.read();
      expect(stored?.version, 4);
      expect(stored?.acceptedAt, acceptedAt);
    });
  });

  group('openPolicyUrl', () {
    late UrlLauncherPlatform original;

    setUp(() {
      original = UrlLauncherPlatform.instance;
    });

    tearDown(() {
      UrlLauncherPlatform.instance = original;
    });

    test('opens https in an in-app browser', () async {
      final fake = _FakeUrlLauncher(inAppResult: true);
      UrlLauncherPlatform.instance = fake;

      final opened = await openPolicyUrl(PolicyConfig.termsOfServiceUri);

      expect(opened, isTrue);
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.url, PolicyConfig.termsOfServiceUrl);
      expect(fake.calls.single.mode, PreferredLaunchMode.inAppBrowserView);
    });

    test(
      'falls back to an external browser when the in-app view fails',
      () async {
        final fake = _FakeUrlLauncher(inAppResult: false, externalResult: true);
        UrlLauncherPlatform.instance = fake;

        final opened = await openPolicyUrl(PolicyConfig.privacyPolicyUri);

        expect(opened, isTrue);
        expect(fake.calls.map((call) => call.mode), [
          PreferredLaunchMode.inAppBrowserView,
          PreferredLaunchMode.externalApplication,
        ]);
      },
    );

    test('falls back when the in-app browser throws', () async {
      final fake = _FakeUrlLauncher(
        inAppResult: true,
        externalResult: true,
        throwInApp: true,
      );
      UrlLauncherPlatform.instance = fake;

      final opened = await openPolicyUrl(PolicyConfig.privacyPolicyUri);

      expect(opened, isTrue);
      expect(fake.calls.map((call) => call.mode), [
        PreferredLaunchMode.inAppBrowserView,
        PreferredLaunchMode.externalApplication,
      ]);
    });

    test('does not launch a non-https url', () async {
      final fake = _FakeUrlLauncher(inAppResult: true);
      UrlLauncherPlatform.instance = fake;

      expect(
        await openPolicyUrl(Uri.parse('http://example.com/terms')),
        isFalse,
      );
      expect(fake.calls, isEmpty);
    });
  });
}

class _LaunchCall {
  const _LaunchCall(this.url, this.mode);

  final String url;
  final PreferredLaunchMode mode;
}

class _FakeUrlLauncher extends UrlLauncherPlatform {
  _FakeUrlLauncher({
    required this.inAppResult,
    this.externalResult = false,
    this.throwInApp = false,
  });

  final bool inAppResult;
  final bool externalResult;
  final bool throwInApp;
  final List<_LaunchCall> calls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add(_LaunchCall(url, options.mode));
    if (options.mode == PreferredLaunchMode.inAppBrowserView) {
      if (throwInApp) throw Exception('in-app browser unavailable');
      return inAppResult;
    }
    return externalResult;
  }
}
