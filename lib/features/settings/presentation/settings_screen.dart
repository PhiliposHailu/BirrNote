import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_key_provider.dart';
import '../data/cloud_sync_service.dart';
import 'category_settings_screen.dart';

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
      appBar: AppBar(title: const Text('Settings')),
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
                hintText: hasKey
                    ? '••••••••••••••••••••'
                    : 'Paste your key here...',
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
                    ref
                        .read(apiKeyProvider.notifier)
                        .saveKey(_keyController.text);
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
                  child: const Text(
                    'Remove Key',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
            
            // ADD THIS MENU ITEM (Navigate to Manage Categories Screen)
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text(
                'Manage Categories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Add, delete, or reset expense categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategorySettingsScreen(),
                  ),
                );
              },
            ),

            // --------------------------------------------------
            // GOOGLE SYNC SECTION (Now with both Backup and Restore!)
            // --------------------------------------------------
            const SizedBox(height: 32),
            const Divider(),
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

            // BUTTON 1: BACKUP TO GOOGLE DRIVE (This replaces the "Test Login" button!)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Backup to Google Drive'),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting cloud backup...')),
                  );

                  final authService = ref.read(cloudSyncProvider);
                  // CALLS THE BACKUP METHOD!
                  final success = await authService.backupDatabase();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup Successful! 🚀'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup failed. Check connection.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // BUTTON 2: RESTORE FROM GOOGLE DRIVE
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('Restore from Google Drive'),
                onPressed: () async {
                  // Standard Confirm Dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Restore Database?'),
                      content: const Text(
                        'This will overwrite all current expenses on this device with the data from your cloud backup. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading backup...')),
                  );

                  final authService = ref.read(cloudSyncProvider);
                  // CALLS THE RESTORE METHOD!
                  final success = await authService.restoreDatabase();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Restore Successful! Please restart the app. 🎉',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Restore failed. No backup found or offline.',
                        ),
                        backgroundColor: Colors.red,
                      ),
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
