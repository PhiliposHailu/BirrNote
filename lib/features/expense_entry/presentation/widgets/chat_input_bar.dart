import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expense_providers.dart';
import 'manual_entry_sheet.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final TextEditingController _noteController = TextEditingController();

  void _submitNote() {
    final text = _noteController.text;
    ref.read(expenseLogicProvider).addRawNote(text);
    _noteController.clear();
  }

  @override
  void dispose() {
    _noteController.dispose(); // clean up listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                // The Flutter way to open a sliding bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled:
                      true, // IMPORTANT: Allows the sheet to move up when keyboard opens
                  useSafeArea: true,
                  builder: (context) => const ManualEntrySheet(),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'e.g. Coffee 50...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _submitNote(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _submitNote,
            ),
          ],
        ),
      ),
    );
  }
}
