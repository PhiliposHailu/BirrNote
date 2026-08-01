import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/presentation/main_nav_screen.dart';
import 'core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/locale_provider.dart';
import 'core/network/api_key_provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize our local notifications!
  // It will run the first-time prompt once, then stay completely silent!
  await NotificationService().initialize();

  // Pre-load preferences synchronously for instant launch rendering!
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('language_code') ?? 'en';
  final savedAiEnabled = prefs.getBool('use_ai_parsing') ?? true;

  // 3. Launch the app
  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => LocaleNotifier(initial: savedLocale)),
        aiEnabledProvider.overrideWith((ref) => AiEnabledNotifier(initial: savedAiEnabled)),
      ],
      child: const BirrNoteApp(),
    ),
  );
}

class BirrNoteApp extends StatelessWidget {
  const BirrNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BirrNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
        ), // update color ???
        useMaterial3: true,
      ),
      home: const MainNavScreen(),
    );
  }
}
