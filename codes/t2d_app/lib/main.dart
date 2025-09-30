import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const T2DApp());
}

class T2DApp extends StatelessWidget {
  const T2DApp({super.key});

  @override
  Widget build(BuildContext context) {
    // palette
    const black = Color(0xFF000000);
    const nearBlack = Color(0xFF0E0E0E); // panels/cards
    const babyPink = Color(0xFFFFC0CB);

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: babyPink,        // buttons / accents
        onPrimary: Colors.black,  // text on buttons
        secondary: babyPink,
        onSecondary: Colors.black,
        background: black,
        onBackground: Colors.white,
        surface: nearBlack,       // card/panel bg
        onSurface: Colors.white,
      ),

      scaffoldBackgroundColor: black,

      // global text color = white
      textTheme: const TextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      // AppBar: black bg, white title, pink icons/links
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: babyPink),
      ),

      // Buttons = baby pink (text black)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: babyPink,
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: babyPink),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: babyPink,
          side: const BorderSide(color: babyPink),
        ),
      ),

      // Inputs (login/signup)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121212),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: babyPink, width: 2),
        ),
      ),

      // Cards (e.g., login panel)
      cardTheme: CardThemeData(
        color: nearBlack,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return MaterialApp.router(
      title: 'T2D Digital Twin',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: ThemeMode.dark, // lock dark
      routerConfig: buildRouter(),
    );
  }
}
