import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rythm/provider/song_player_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bottom_navigation_pages/bottom_pages.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

SongPlayerProvider? songProviderInstance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Supabase
  await Supabase.initialize(
    url: 'https://epdzmdidqfrprgljtpam.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwZHptZGlkcWZycHJnbGp0cGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgxNDA2OTEsImV4cCI6MjA1MzcxNjY5MX0.kKHY13L0nIWCGVh4m-uihedgt-NeUSlndjlgX8NbrOI',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            songProviderInstance = SongPlayerProvider();
            return songProviderInstance!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Rythm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      /// Splash Screen
      home: AnimatedSplashScreen(
        splashIconSize: 600,
        centered: true,
        backgroundColor: const Color(0xff181B2C),
        duration: 4100,
        splash: 'assets/Splash Animation.gif',
        nextScreen: BottomPages(),
      ),
    );
  }
}
