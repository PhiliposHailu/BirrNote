import 'package:flutter/material.dart';
import 'widgets/expense_list.dart';
import 'widgets/chat_input_bar.dart';
import '../../settings/presentation/settings_screen.dart';

class ExpenseEntryScreen extends StatelessWidget {
  const ExpenseEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BirrNote'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // standard way to push a new screen onto the stack
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: ExpenseList()),

          // The input bar stays at the bottom
          ChatInputBar(),
        ],
      ),
    );
  }
}
