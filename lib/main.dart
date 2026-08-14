import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/presentation/main_nav_screen.dart';
import 'core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/locale_provider.dart';
import 'core/utils/calendar_type_provider.dart';
import 'core/network/api_key_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize our local notifications!
  // It will run the first-time prompt once, then stay completely silent!
  await NotificationService().initialize();

  // Pre-load preferences synchronously for instant launch rendering!
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('language_code') ?? 'en';
  final savedAiEnabled = prefs.getBool('use_ai_parsing') ?? true;
  final savedCalendar = prefs.getString('calendar_type');
  final initialCalendar = savedCalendar == 'ethiopian' ? CalendarType.ethiopian : CalendarType.gregorian;
  
  final savedThemeModeStr = prefs.getString('theme_mode') ?? 'system';
  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedThemeModeStr == 'light') initialThemeMode = ThemeMode.light;
  if (savedThemeModeStr == 'dark') initialThemeMode = ThemeMode.dark;

  // 3. Launch the app
  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => LocaleNotifier(initial: savedLocale)),
        aiEnabledProvider.overrideWith((ref) => AiEnabledNotifier(initial: savedAiEnabled)),
        calendarTypeProvider.overrideWith((ref) => CalendarTypeNotifier(initial: initialCalendar)),
        themeModeProvider.overrideWith(() => ThemeModeNotifier(initial: initialThemeMode)),
      ],
      child: const BirrNoteApp(),
    ),
  );
}

class BirrNoteApp extends ConsumerWidget {
  const BirrNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'BirrNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavScreen(),
    );
  }
}
