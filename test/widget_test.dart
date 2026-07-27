import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birr_note/main.dart';

void main() {
  testWidgets('BirrNoteApp builds smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: BirrNoteApp(),
      ),
    );

    // Verify that BirrNote app initializes cleanly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
