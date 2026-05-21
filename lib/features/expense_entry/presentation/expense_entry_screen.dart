import 'package:flutter/material.dart';
import 'widgets/expense_list.dart';
import 'widgets/chat_input_bar.dart';

class ExpenseEntryScreen extends StatelessWidget {
  const ExpenseEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BirrNote'),
        centerTitle: true,
      ),
      body: const Column(
        children: [
          Expanded(
            child: ExpenseList(),
          ),
          
          // The input bar stays at the bottom
          ChatInputBar(),
        ],
      ),
    );
  }
}