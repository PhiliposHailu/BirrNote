import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_key_provider.dart'; // Watches the AI toggle state!
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

  void _openManualSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ManualEntrySheet(),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch whether AI Note Parsing is enabled in Settings
    final isAiEnabled = ref.watch(aiEnabledProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isAiEnabled
            // --- MODE 1: AI IS ON (Show Chat Input + Manual Button) ---
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _openManualSheet,
                  ),
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
                      onSubmitted: (_) => _submitNote(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _submitNote,
                  ),
                ],
              )
            // --- MODE 2: AI IS OFF (Hide Text Box! Show Full-Width Add Button) ---
            : SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _openManualSheet, // Opens manual form directly!
                ),
              ),
      ),
    );
  }
}