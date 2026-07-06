import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/presentation/main_nav_screen.dart';

void main() {
  runApp(const ProviderScope(child: BirrNoteApp()));
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
