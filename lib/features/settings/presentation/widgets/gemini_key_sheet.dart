import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW: Browser launcher
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
      ref.read(apiKeyProvider.notifier).saveKey(text);
      _keyController.clear();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API Key saved securely!')),
      );
    }
  }

  // NEW: The Step-by-Step Interactive Guide Dialog
  void _showGetKeyGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Get Free Gemini Key', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Tap the button below to go to Google AI Studio.'),
            SizedBox(height: 8),
            Text('2. Sign in with your personal Google account.'),
            SizedBox(height: 8),
            Text('3. Tap the blue "Create API key" button.'),
            SizedBox(height: 8),
            Text('4. Copy the generated key and paste it here!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = Uri.parse('https://aistudio.google.com/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Get Key'),
          ),
        ],
      ),
    );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gemini API Key',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your key is stored securely on this device.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // NEW: The Guide Button!
            TextButton.icon(
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('How do I get a free key? 🔑'),
              onPressed: () => _showGetKeyGuide(context),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hasKey ? '••••••••••••••••••••' : 'AIzaSy...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _saveKey,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Save Key', style: TextStyle(fontSize: 16)),
              ),
            ),

            if (hasKey) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(apiKeyProvider.notifier).deleteKey();
                  Navigator.of(context).pop();
                  
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