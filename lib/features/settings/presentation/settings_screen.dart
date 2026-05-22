import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_key_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current API key state
    final currentKey = ref.watch(apiKeyProvider);
    final hasKey = currentKey != null && currentKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bring Your Own Key (BYOK)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'BirrNote uses Google Gemini to magically organize your notes. Your data never leaves your device, and you use your own free API key.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // The Input Field
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: hasKey ? '••••••••••••••••••••' : 'Paste your key here...',
                border: const OutlineInputBorder(),
                suffixIcon: hasKey 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              ),
              obscureText: true, // Hides the text like a password field
            ),
            
            const SizedBox(height: 16),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_keyController.text.isNotEmpty) {
                    ref.read(apiKeyProvider.notifier).saveKey(_keyController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Key securely saved!')),
                    );
                    _keyController.clear();
                  }
                },
                child: const Text('Save Key'),
              ),
            ),

            // If they have a key, give them the option to delete it
            if (hasKey) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(apiKeyProvider.notifier).deleteKey();
                  },
                  child: const Text('Remove Key', style: TextStyle(color: Colors.red)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}