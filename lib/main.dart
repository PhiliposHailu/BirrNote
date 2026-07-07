import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/presentation/main_nav_screen.dart';
import 'core/notifications/notification_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize our local notifications!
  // It will run the first-time prompt once, then stay completely silent!
  await NotificationService().initialize();

  // 3. Launch the app
  runApp(
    const ProviderScope(
      child: BirrNoteApp(),
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
