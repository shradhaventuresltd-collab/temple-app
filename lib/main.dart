import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/bundled_fonts.dart';
import 'package:temple_app/config/build_flags.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/release_error_widget.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/force_update_screen.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/maintenance_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/app_bootstrap.dart';
import 'package:temple_app/services/app_config.dart';
import 'package:temple_app/services/app_update.dart';
import 'package:temple_app/services/client_cache.dart';
import 'package:temple_app/services/firebase_remote_config_gateway.dart';
import 'package:temple_app/services/installed_build.dart';
import 'package:temple_app/services/offline_link.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/policy_link_launcher.dart';
import 'package:temple_app/services/temple_service.dart';
import 'package:temple_app/services/update_nudge_store.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Detailed text only for debug, DEMO_BUILD, or ENABLE_ADMIN_TOOLS.
  // The Play AAB gets a branded screen with no stack. Flutter already
  // reports that error once before the fallback is built.
  installReleaseErrorWidget();
  // Poppins and Lora ship in assets/google_fonts. google_fonts otherwise
  // downloads fonts.gstatic.com from the first frame. loadFontIfNecessary
  // is started with .then and no catchError, so a missing file is an
  // unhandled async error. onError logs that future.
  installFontLoadErrorLogging();
  registerBundledFontLicenses();
  GoogleFonts.config.allowRuntimeFetching = false;
  // Cap decoded bitmaps before the first list paints full-size covers.
  ClientCache.installImageMemoryLimits();
  DirectoryLink.listen(directoryConnectivity());
  // Firebase before the first frame, on every flavour (Play, demo
  // distribution, and demo-seed). The 4s cap keeps a hung init from
  // holding the saffron splash (KAN-75). A timeout or a bad config still
  // launches; Home then reads cache or the bundled sample. Ads stay after
  // Terms (KAN-93) and are not awaited here.
  final firebaseReady = await AppBootstrap.initializeFirebase();
  // Defaults and the last activated cache before the first frame. The fetch
  // is not awaited: a slow or failed fetch must not hold the saffron splash.
  // Remote Config is not constructed unless Firebase already has an app.
  final appConfig = AppConfigController(
    client: remoteConfigClientIfReady(firebaseReady: firebaseReady),
    minimumFetchInterval: kRemoteConfigMinimumFetchInterval,
  );
  TempleService.readsBlocked = () => appConfig.snapshot.killSwitch;
  final remoteConfigStartup = startRemoteConfig(appConfig);
  await remoteConfigStartup.ready;
  unawaited(remoteConfigStartup.fetch);
  runApp(
    TempleDirectoryApp(firebaseReady: firebaseReady, appConfig: appConfig),
  );
}

enum _StartupPhase { checking, gate, update, home }

/// Sentinel for [TempleDirectoryApp.installedBuildNumber]. Tests pass an int
/// or null. Production reads the Android versionCode.
const Object usePlatformBuildNumber = Object();

class TempleDirectoryApp extends StatefulWidget {
  const TempleDirectoryApp({
    super.key,
    this.acceptanceStore,
    this.currentPolicyVersion = PolicyConfig.currentVersion,
    this.initializeFirebase,
    this.firebaseReady,
    this.initializeAds,
    this.templesLoader,
    this.adminAuth,
    this.adminToolsEnabled,
    this.now,
    this.onExitApp,
    this.launchPolicyUrl,
    this.appConfig,
    this.installedBuildNumber = usePlatformBuildNumber,
    this.nudgeStore,
    this.launchStoreUrl,
    this.demoAppIdSuffix,
    this.directory,
  });

  /// Defaults to shared preferences. Tests pass an in-memory store.
  final PolicyAcceptanceStore? acceptanceStore;

  /// Defaults to [PolicyConfig.currentVersion]. Tests pass a higher value
  /// to simulate a policy bump.
  final int currentPolicyVersion;

  final Future<bool> Function()? initializeFirebase;

  /// Result when [main] already awaited [AppBootstrap.initializeFirebase].
  /// Tests leave this null and pass [initializeFirebase] instead.
  final bool? firebaseReady;

  final Future<void> Function()? initializeAds;
  final Future<List<Temple>> Function()? templesLoader;
  final AdminAuth? adminAuth;
  final bool? adminToolsEnabled;
  final DateTime Function()? now;

  /// System back on the gate. Defaults to leaving the app.
  final VoidCallback? onExitApp;

  /// Opens a policy https URL in an in-app browser.
  final Future<bool> Function(Uri url)? launchPolicyUrl;

  /// Remote Config snapshot. Tests pass a controller with no plugin.
  /// Null uses in-app defaults and does not fetch.
  final AppConfigController? appConfig;

  /// Installed Android versionCode. [usePlatformBuildNumber] reads the
  /// package. Null fails open and does not block.
  final Object? installedBuildNumber;

  /// Soft-nudge day. Tests pass an in-memory store.
  final UpdateNudgeStore? nudgeStore;

  /// Opens a Play Store uri. Defaults to an external application launch.
  final Future<bool> Function(Uri url)? launchStoreUrl;

  /// Defaults to [kDemoAppIdSuffix]. Tests pass true for the `.demo` id.
  final bool? demoAppIdSuffix;

  /// Shared directory. Resume calls [TempleService.loadDirectory] on it.
  /// Tests that pass [templesLoader] do not use it.
  final TempleService? directory;

  @override
  State<TempleDirectoryApp> createState() => _TempleDirectoryAppState();
}

class _TempleDirectoryAppState extends State<TempleDirectoryApp> {
  late final Future<bool> _firebaseReady;
  late final PolicyAcceptanceStore _store;
  late final AppConfigController _config;
  late final bool _ownsConfig;
  late final TempleService _directory;
  _StartupPhase _phase = _StartupPhase.checking;
  PolicyGateKind _gateKind = PolicyGateKind.firstLaunch;
  bool _adsStarted = false;
  int? _buildNumber;
  bool _offerSoftUpdate = false;

  @override
  void initState() {
    super.initState();
    _ownsConfig = widget.appConfig == null;
    _config = widget.appConfig ?? AppConfigController();
    TempleService.readsBlocked = () => _config.snapshot.killSwitch;
    _config.addListener(_onConfig);
    _directory = widget.directory ?? TempleService(now: widget.now);
    final override = widget.initializeFirebase;
    final already = widget.firebaseReady;
    if (override != null) {
      _firebaseReady = override();
    } else if (already != null) {
      _firebaseReady = Future<bool>.value(already);
    } else {
      _firebaseReady = AppBootstrap.initializeFirebase();
    }
    _store = widget.acceptanceStore ?? SharedPreferencesPolicyAcceptanceStore();
    unawaited(_loadAcceptance());
  }

  @override
  void dispose() {
    _config.removeListener(_onConfig);
    TempleService.readsBlocked = () => false;
    if (_ownsConfig) _config.dispose();
    super.dispose();
  }

  void _onConfig() {
    if (!mounted) return;
    setState(() {});
    _startAdsIfAllowed();
  }

  Future<void> _loadAcceptance() async {
    final storedFuture = _readStoredAcceptance();
    final buildFuture = _resolveBuildNumber();
    final stored = await storedFuture;
    _buildNumber = await buildFuture;
    if (!mounted) return;
    final kind = policyGateKind(
      stored: stored,
      currentVersion: widget.currentPolicyVersion,
    );
    if (kind != null) {
      setState(() {
        _gateKind = kind;
        _phase = _StartupPhase.gate;
      });
      return;
    }
    // Second launch reads Terms from SharedPreferences and would open Home
    // while Firebase.initializeApp is still running. Wait for that future
    // on every path, including the one main() already completed.
    await _firebaseReady;
    if (!mounted) return;
    _openHomeAndStartAds();
  }

  Future<PolicyAcceptance?> _readStoredAcceptance() async {
    try {
      return await _store.read();
    } catch (e, st) {
      debugPrint('Policy acceptance read failed: $e\n$st');
      return null;
    }
  }

  Future<int?> _resolveBuildNumber() {
    final override = widget.installedBuildNumber;
    if (!identical(override, usePlatformBuildNumber)) {
      return Future<int?>.value(override is int ? override : null);
    }
    return readInstalledBuildNumber();
  }

  Future<void> _accept() async {
    final clock = widget.now ?? DateTime.now;
    try {
      await _store.write(
        PolicyAcceptance(
          version: widget.currentPolicyVersion,
          acceptedAt: clock().toUtc(),
        ),
      );
    } catch (e, st) {
      debugPrint('Policy acceptance save failed: $e\n$st');
      rethrow;
    }
    _openHomeAndStartAds();
  }

  /// Home is shown immediately. UMP and Mobile Ads start in the background
  /// and must not block the first Home frame (KAN-75). Ad widgets still wait
  /// until consent resolves, and this is the only place ads are started.
  ///
  /// A kill switch skips Home, ads, and directory reads. `ff_ads_enabled`
  /// false still opens Home and skips only the ad startup.
  void _openHomeAndStartAds() {
    if (!mounted) return;
    final requirement = updateRequirement(
      buildNumber: _buildNumber,
      minSupportedBuild: _config.snapshot.minSupportedBuild,
      recommendedBuild: _config.snapshot.recommendedBuild,
    );
    if (requirement == UpdateRequirement.hard) {
      setState(() {
        _offerSoftUpdate = false;
        _phase = _StartupPhase.update;
      });
      return;
    }
    setState(() {
      _offerSoftUpdate = requirement == UpdateRequirement.soft;
      _phase = _StartupPhase.home;
    });
    _startAdsIfAllowed();
  }

  String get _playPackage => playStorePackageName(
    demoAppIdSuffix: widget.demoAppIdSuffix ?? kDemoAppIdSuffix,
  );

  Future<bool> _launchStore(Uri url) {
    final launch = widget.launchStoreUrl;
    if (launch != null) return launch(url);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Ads start once, after Terms, and only while the kill switch is off.
  /// A switch that clears later still starts them. `ff_ads_enabled` false
  /// leaves them off for this process.
  void _startAdsIfAllowed() {
    if (_adsStarted || _phase != _StartupPhase.home) return;
    if (_config.snapshot.killSwitch || !_config.snapshot.adsEnabled) return;
    _adsStarted = true;
    final startAds = widget.initializeAds ?? AppBootstrap.initializeAdsSafely;
    unawaited(_startAdsInBackground(startAds));
  }

  Future<void> _startAdsInBackground(Future<void> Function() startAds) async {
    try {
      await startAds();
    } catch (e, st) {
      debugPrint('Ad startup after policy acceptance failed: $e\n$st');
    }
  }

  void _exitApp() {
    final exit = widget.onExitApp;
    if (exit != null) {
      exit();
      return;
    }
    SystemNavigator.pop();
  }

  Future<List<Temple>> _loadTemples() async {
    if (_config.snapshot.killSwitch) return const [];
    final loader = widget.templesLoader;
    if (loader != null) return loader();
    await _firebaseReady;
    return _directory.getTemples();
  }

  Future<List<Temple>> _refreshTemples() async {
    if (_config.snapshot.killSwitch) return const [];
    final loader = widget.templesLoader;
    if (loader != null) return loader();
    await _firebaseReady;
    return _directory.loadDirectory();
  }

  Widget _body() {
    if (_config.snapshot.killSwitch) {
      return MaintenanceScreen(
        message: _config.snapshot.maintenanceMessage,
        onExit: _exitApp,
      );
    }
    switch (_phase) {
      case _StartupPhase.checking:
        return const PolicyStartupHold();
      case _StartupPhase.gate:
        return PolicyAcceptanceGate(
          kind: _gateKind,
          onAccept: _accept,
          onOpenUrl: widget.launchPolicyUrl ?? openPolicyUrl,
          onExit: _exitApp,
        );
      case _StartupPhase.update:
        return ForceUpdateScreen(
          packageName: _playPackage,
          launch: _launchStore,
          onExit: _exitApp,
        );
      case _StartupPhase.home:
        return HomeScreen(
          adminAuth: widget.adminAuth,
          templesLoader: _loadTemples,
          refreshTemples: widget.templesLoader == null ? _refreshTemples : null,
          lastIndexCheck: widget.templesLoader == null
              ? () => _directory.lastIndexCheckAt
              : null,
          now: widget.now,
          adminToolsEnabled: widget.adminToolsEnabled,
          maintenanceMessage: _config.snapshot.maintenanceMessage,
          offerSoftUpdate: _offerSoftUpdate,
          nudgeStore: widget.nudgeStore,
          openPlayStore: () => openPlayStoreListing(
            packageName: _playPackage,
            launch: _launchStore,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFFF8F00);
    const gold = Color(0xFFFFD54F);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Temple Directory India',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: saffron,
          primary: saffron,
          secondary: gold,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFFBF2),
      ),
      home: _body(),
    );
  }
}
