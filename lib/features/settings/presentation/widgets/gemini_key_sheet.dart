import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_key_provider.dart';
import '../../../../core/network/model_provider.dart';
import '../../../../core/utils/locale_provider.dart';

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

  Future<void> _launchStudio() async {
    final url = Uri.parse('https://aistudio.google.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
    final availableModelsAsync = ref.watch(availableModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final models = availableModelsAsync.valueOrNull ?? kDefaultGeminiModels;
    final activeModelId = models.any((m) => m.id == selectedModel)
        ? selectedModel
        : (models.isNotEmpty ? models.first.id : kDefaultModelId);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER AREA
              Icon(
                hasKey ? Icons.check_circle : Icons.auto_awesome,
                size: 56,
                color: hasKey
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                hasKey ? 'AI Advisor Active' : 'Activate AI Advisor',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasKey
                    ? 'Your free Gemini API Key is securely stored on this device. BirrNote can automatically categorize your expenses!'
                    : 'Get a free Gemini API Key to automatically categorize your spending just by typing naturally.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // THE GUIDE (Only show if no key)
              if (!hasKey) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildStep(Icons.login, '1. Sign in to Google AI Studio'),
                      const SizedBox(height: 12),
                      _buildStep(Icons.key, '2. Tap "Create API key"'),
                      const SizedBox(height: 12),
                      _buildStep(
                        Icons.content_copy,
                        '3. Copy the key and paste it below',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _launchStudio,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open Google AI Studio'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // MODEL PICKER (Only show if key exists)
              if (hasKey) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ref.watch(trProvider('ai_model')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          availableModelsAsync.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                  ),
                                  tooltip: ref.watch(
                                    trProvider('refresh_models'),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    await ref
                                        .read(availableModelsProvider.notifier)
                                        .refresh(currentKey);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ref.watch(
                                              trProvider('models_refreshed'),
                                            ),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activeModelId,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            items: models.map((m) {
                              return DropdownMenuItem<String>(
                                value: m.id,
                                child: Text(
                                  m.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                ref
                                    .read(selectedModelProvider.notifier)
                                    .setModel(newId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // INPUT AREA
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Your API Key',
                  hintText: hasKey
                      ? '••••••••••••••••••••••••••••'
                      : 'AIzaSy...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              if (!hasKey) ...[
                FilledButton(
                  onPressed: _saveKey,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save API Key',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              if (hasKey) ...[
                OutlinedButton(
                  onPressed: () {
                    ref.read(apiKeyProvider.notifier).deleteKey();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Key removed.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Remove Key',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
