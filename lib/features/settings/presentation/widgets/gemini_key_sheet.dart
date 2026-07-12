import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_key_provider.dart';

class GeminiKeySheet extends ConsumerStatefulWidget {
  const GeminiKeySheet({super.key});

  @override
  ConsumerState<GeminiKeySheet> createState() => _GeminiKeySheetState();
}

class _GeminiKeySheetState extends ConsumerState<GeminiKeySheet> {
  final _keyController = TextEditingController();

  void _saveKey() {
    final text = _keyController.text.trim();
    if (text.isNotEmpty) {
      // Save the key securely using our provider
      ref.read(apiKeyProvider.notifier).saveKey(text);
      _keyController.clear();
      Navigator.of(context).pop(); // Slide the bottom sheet down!
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API Key saved securely!')),
      );
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = ref.watch(apiKeyProvider);
    final hasKey = currentKey != null && currentKey.isNotEmpty;
    
    // THE UX MAGIC: Measures the keyboard height to push the sheet up safely!
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset, 
        left: 16, 
        right: 16, 
        top: 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content tightly
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gemini API Key',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste your free Gemini API Key from Google AI Studio. Your key is stored securely on this device.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // KEY INPUT FIELD
            TextField(
              controller: _keyController,
              obscureText: true, // Hide the key like a password
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hasKey ? '••••••••••••••••••••' : 'AIzaSy...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // SAVE BUTTON
            FilledButton(
              onPressed: _saveKey,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Save Key', style: TextStyle(fontSize: 16)),
              ),
            ),

            // DELETE BUTTON (Only shows if a key is currently active!)
            if (hasKey) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(apiKeyProvider.notifier).deleteKey();
                  Navigator.of(context).pop(); // Slide down
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key removed.')),
                  );
                },
                child: const Text('Remove Key', style: TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}