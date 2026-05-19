import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_providers.dart';

// THE WHY: We use ConsumerStatefulWidget instead of a normal StatefulWidget.
// This allows us to use standard Flutter controllers (for the text field) 
// while also being able to "consume" Riverpod providers (our database).
class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  final TextEditingController _noteController = TextEditingController();

  void _submitNote() {
    final text = _noteController.text;
    // Ask Riverpod for our writer logic, and call addRawNote
    ref.read(expenseLogicProvider).addRawNote(text);
    _noteController.clear(); // Clear the chat box
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We watch the live stream of expenses
    final expensesStream = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BirrNote'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THE CHAT HISTORY (List of expenses)
          Expanded(
            child: expensesStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(child: Text('No expenses yet. Start typing!'));
                }
                return ListView.builder(
                  // Show newest items at the bottom (like WhatsApp)
                  reverse: true, 
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    // We reverse the list so newest is at the bottom
                    final expense = expenses.reversed.toList()[index];
                    return ListTile(
                      title: Text(expense.rawNote),
                      subtitle: Text(expense.date.toString().split('.')[0]),
                      // A visual indicator that the AI hasn't processed it yet
                      trailing: expense.isPendingAi 
                          ? const Icon(Icons.sync, color: Colors.orange)
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // 2. THE CHAT INPUT BOX
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // The "Manual Entry" plus button (Placeholder for later)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // TODO: Open manual entry bottom sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manual entry coming soon!')),
                      );
                    },
                  ),
                  
                  // The Text Field
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Coffee 50...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      // Submit when they hit "Enter" on keyboard
                      onSubmitted: (_) => _submitNote(), 
                    ),
                  ),

                  // The Send Button
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _submitNote,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}