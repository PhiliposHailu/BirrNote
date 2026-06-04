import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/advisor_providers.dart';

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final TextEditingController _chatController = TextEditingController();
  bool _isLoading = false; // To show a loading spinner while AI thinks

  Future<void> _handleSend() async {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;

    _chatController.clear();
    FocusScope.of(context).unfocus(); // Close the keyboard like a pro

    setState(() => _isLoading = true);
    
    // Call our provider logic we just wrote!
    await ref.read(advisorLogicProvider).sendMessage(text);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the chat history array
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
              final isUser = message['role'] == 'user';

              return Align(
                // React flexbox equivalent: align-self: flex-end vs flex-start
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    // Give user and AI different bubble colors
                    color: isUser 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0), // Sharp corner on speaker's side
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                  ),
                  child: Text(
                    message['text']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Show a cute loading indicator while Gemini thinks
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),

        // 2. THE INPUT BOX
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
                  onPressed: _isLoading ? null : _handleSend, // Disable button if loading
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}