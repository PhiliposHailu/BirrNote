import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    // THE WHY: ProviderScope is the "brain" of Riverpod. 
    // By wrapping our entire app in it, any screen or widget 
    // inside our app can easily talk to our database or AI logic.
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
      // THE WHY: Material 3 is Google's latest design system. 
      // It gives us beautiful, modern UI components out of the box.
      // We are using a deep green seed color since this is a finance app!
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)), // We can tweak this later!
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'BirrNote Foundation Set! 🚀',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}