import 'features/expense_entry/presentation/expense_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)), // We can tweak this later!
        useMaterial3: true,
      ),
      home: const ExpenseEntryScreen()
    );
  }
}