import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/config/policy_config.dart';
import 'package:temple_app/models/temple.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/screens/policy_acceptance_gate.dart';
import 'package:temple_app/services/admin_auth.dart';
import 'package:temple_app/services/app_bootstrap.dart';
import 'package:temple_app/services/policy_acceptance_store.dart';
import 'package:temple_app/services/policy_link_launcher.dart';
import 'package:temple_app/services/temple_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paint Flutter UI immediately. Native splash is solid saffron (#FF8F00);
  // awaiting Ads/Firebase here made that orange linger for several seconds
  // (KAN-75). The first Flutter frame is the Terms gate or a cream hold.
  // UMP starts only after Terms are accepted (KAN-93).
  runApp(const TempleDirectoryApp());
}

enum _StartupPhase { checking, gate, home }

class TempleDirectoryApp extends StatefulWidget {
  const TempleDirectoryApp({
    super.key,
    this.acceptanceStore,
    this.currentPolicyVersion = PolicyConfig.currentVersion,
    this.initializeFirebase,
    this.initializeAds,
    this.templesLoader,
    this.adminAuth,
    this.adminToolsEnabled,
    this.now,
    this.onExitApp,
    this.launchPolicyUrl,
  });

  /// Defaults to shared preferences. Tests pass an in-memory store.
  final PolicyAcceptanceStore? acceptanceStore;

  /// Defaults to [PolicyConfig.currentVersion]. Tests pass a higher value
  /// to simulate a policy bump.
  final int currentPolicyVersion;

  final Future<bool> Function()? initializeFirebase;
  final Future<void> Function()? initializeAds;
  final Future<List<Temple>> Function()? templesLoader;
  final AdminAuth? adminAuth;
  final bool? adminToolsEnabled;
  final DateTime Function()? now;

  /// System back on the gate. Defaults to leaving the app.
  final VoidCallback? onExitApp;

  /// Opens a policy https URL in an external browser.
  final Future<bool> Function(Uri url)? launchPolicyUrl;

  @override
  State<TempleDirectoryApp> createState() => _TempleDirectoryAppState();
}

class _TempleDirectoryAppState extends State<TempleDirectoryApp> {
  late final Future<bool> _firebaseReady;
  late final PolicyAcceptanceStore _store;
  _StartupPhase _phase = _StartupPhase.checking;
  PolicyGateKind _gateKind = PolicyGateKind.firstLaunch;

  @override
  void initState() {
    super.initState();
    final startFirebase =
        widget.initializeFirebase ?? AppBootstrap.initializeFirebase;
    _firebaseReady = startFirebase();
    _store = widget.acceptanceStore ?? SharedPreferencesPolicyAcceptanceStore();
    unawaited(_loadAcceptance());
  }

  Future<void> _loadAcceptance() async {
    PolicyAcceptance? stored;
    try {
      stored = await _store.read();
    } catch (e, st) {
      debugPrint('Policy acceptance read failed: $e\n$st');
    }
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
    _openHomeAndStartAds();
  }

  Future<void> _accept() async {
    final clock = widget.now ?? DateTime.now;
    await _store.write(
      PolicyAcceptance(
        version: widget.currentPolicyVersion,
        acceptedAt: clock().toUtc(),
      ),
    );
    _openHomeAndStartAds();
  }

  /// Home is shown immediately. UMP and Mobile Ads start in the background
  /// and must not block the first Home frame (KAN-75). Ad widgets still wait
  /// until consent resolves, and this is the only place ads are started.
  void _openHomeAndStartAds() {
    if (!mounted) return;
    setState(() => _phase = _StartupPhase.home);
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
    final loader = widget.templesLoader;
    if (loader != null) return loader();
    await _firebaseReady;
    return TempleService().getTemples();
  }

  Widget _body() {
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
      case _StartupPhase.home:
        return HomeScreen(
          adminAuth: widget.adminAuth,
          templesLoader: _loadTemples,
          adminToolsEnabled: widget.adminToolsEnabled,
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
