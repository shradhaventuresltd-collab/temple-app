import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/app_bootstrap.dart';
import 'package:temple_app/services/temple_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paint Flutter UI immediately. Native splash is solid saffron (#FF8F00);
  // awaiting Ads/Firebase here made that orange linger for several seconds
  // (KAN-75). Firebase + Ads start from [TempleDirectoryApp] instead.
  runApp(const TempleDirectoryApp());
}

class TempleDirectoryApp extends StatefulWidget {
  const TempleDirectoryApp({super.key});

  @override
  State<TempleDirectoryApp> createState() => _TempleDirectoryAppState();
}

class _TempleDirectoryAppState extends State<TempleDirectoryApp> {
  late final Future<bool> _firebaseReady;

  @override
  void initState() {
    super.initState();
    _firebaseReady = AppBootstrap.initializeFirebase();
    // UMP, then MobileAds.initialize, after the first frame. Consent must
    // not run before runApp — that brought back the saffron splash hang
    // (KAN-75). A slow form overlays Home; it does not block startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppBootstrap.initializeAdsSafely());
    });
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
      home: HomeScreen(
        // Cream Home shell paints first; temple fetch waits for Firebase
        // (or its short timeout) then uses Firestore / sample fallback.
        templesLoader: () async {
          await _firebaseReady;
          return TempleService().getTemples();
        },
      ),
    );
  }
}
