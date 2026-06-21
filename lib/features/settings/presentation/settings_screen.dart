import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_key_provider.dart';
import '../data/cloud_sync_service.dart';

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
    // Keep watch the current API key state
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

            // If they have a key, give them the option to delete it ???
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
            ],

            
            const SizedBox(height: 32), // Spacer
            const Divider(), // A nice line to separate sections
            const SizedBox(height: 16),

            const Text(
              'Cloud Backup (Free)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Securely sync your database to your hidden Google Drive App Data folder. You own your data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Google Sign-In Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Test Google Login'),
                onPressed: () async {
                  // Show a quick loading message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to Google...')),
                  );
                  
                  // Call our provider!
                  final authService = ref.read(cloudSyncProvider);
                  final account = await authService.signIn();
                  
                  if (account != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Success! Logged in as: ${account.email}')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login failed or canceled.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),

            
    );
  }
}