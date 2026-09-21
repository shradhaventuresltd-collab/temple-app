import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temple_app/firebase_options.dart';
import 'package:temple_app/screens/home_screen.dart';
import 'package:temple_app/services/ad_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AdHelper.initializeAds();
  runApp(const TempleDirectoryApp());
}

class TempleDirectoryApp extends StatelessWidget {
  const TempleDirectoryApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}
