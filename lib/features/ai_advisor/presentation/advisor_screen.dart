import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/advisor_providers.dart';

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final _chatController = TextEditingController();

  void _handleSend() {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;

    _chatController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard

    // Trigger our dynamic provider (it will handle adding typing bubbles automatically!)
    ref.read(advisorLogicProvider).sendMessage(text);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(advisorChatProvider);

    return Column(
      children: [
        // 1. THE CHAT MESSAGES
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatHistory.length,
            itemBuilder: (context, index) {
              final message = chatHistory[index];
              final role = message['role'];
              
              final isUser = role == 'user';
              final isTyping = role == 'ai_typing';
              final isError = role == 'ai_error';

              // Determine the Bubble Color
              Color bubbleColor = Theme.of(context).colorScheme.surfaceVariant;
              if (isUser) {
                bubbleColor = Theme.of(context).colorScheme.primary;
              } else if (isError) {
                bubbleColor = Colors.red.shade50; // Light red for errors
              }

              // Determine the Text Style
              TextStyle textStyle = TextStyle(
                fontSize: 16,
                color: isUser 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              );

              if (isTyping) {
                // If the AI is typing, make the text soft, grey, and italicized!
                textStyle = textStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                );
              } else if (isError) {
                // If it failed, make the text bold and dark red
                textStyle = textStyle.copyWith(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                );
              }

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    border: isError 
                        ? Border.all(color: Colors.red.shade200) 
                        : null,
                  ),
                  child: Text(
                    message['text']!,
                    style: textStyle,
                  ),
                ),
              );
            },
          ),
        ),

        // 2. THE CHAT INPUT BAR
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your budget...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}