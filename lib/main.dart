import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/alert_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Local Persistence (Hive) ──────────────────
  await Hive.initFlutter();
  await HiveService.init();

  // ── Firebase Init ─────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Safety Notifications ──────────────────────
  await NotificationService.init();

  // ── Initial Permissions Check ─────────────────
  // Note: Only requesting mandatory ones at start.
  // Location/SMS requested when feature is used.
  await PermissionService.requestAll();

  runApp(const GuardXApp());
}

class GuardXApp extends StatefulWidget {
  const GuardXApp({super.key});

  @override
  State<GuardXApp> createState() => _GuardXAppState();
}

class _GuardXAppState extends State<GuardXApp> {
  @override
  void dispose() {
    AlertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guard-X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10141A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5352),
          secondary: Color(0xFFA0CAFF),
          surface: Color(0xFF1C2026),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFFFFB3AE)),
          titleTextStyle: TextStyle(
            color: Color(0xFFFFB3AE),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2.0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C2026),
          labelStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF5352), width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5352),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFFFF5352).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}