import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_key_provider.dart';
import 'category_settings_screen.dart';
import 'widgets/weekly_budget_card.dart';
import 'widgets/daily_reminder_card.dart';
import 'widgets/gemini_key_sheet.dart';
import 'widgets/cloud_sync_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch our key provider so we can display a dynamic subtitle on our main row!
    final currentKey = ref.watch(apiKeyProvider);
    final hasKey = currentKey != null && currentKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- CARD 1: BUDGET LIMITS ---
          const WeeklyBudgetCard(),
          const SizedBox(height: 12),

          // --- CARD 2: DAILY HABIT REMINDER ---
          const DailyReminderCard(),
          const SizedBox(height: 12),

          // --- CARD 3: APP CUSTOMIZATION ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, size: 28),
              title: const Text(
                'Manage Categories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Add, delete, or reorder categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategorySettingsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // --- CARD 4: THE SECURITY VAULT (Gemini Key + Google Drive Sync) ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // ROW A: GEMINI KEY (ListTile)
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, size: 28),
                  title: const Text(
                    'Gemini API Key',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    hasKey
                        ? 'Key Active & Secured'
                        : 'Add key for AI note parsing',
                  ),
                  trailing: hasKey
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const GeminiKeySheet(),
                    );
                  },
                ),

                const Divider(indent: 16, endIndent: 16, height: 1),

                // NEW ROW B: USE AI TOGGLE!
                SwitchListTile(
                  secondary: const Icon(Icons.psychology_outlined, size: 28),
                  title: const Text(
                    'Use AI Note Parsing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'When disabled, notes are logged directly as drafts',
                  ),
                  value: ref.watch(aiEnabledProvider),
                  onChanged: (val) =>
                      ref.read(aiEnabledProvider.notifier).toggle(val),
                ),

                const Divider(indent: 16, endIndent: 16, height: 1),

                // ROW C: GOOGLE SYNC
                const CloudSyncTile(),
              ],
            ),
          ),

          // --- APP FOOTER ---
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'BirrNote v1.0.0 • Local First',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
