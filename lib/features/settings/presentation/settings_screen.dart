import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_key_provider.dart';
import 'category_settings_screen.dart';
import 'widgets/weekly_budget_card.dart';
import 'widgets/daily_reminder_card.dart';
import 'widgets/gemini_key_sheet.dart';
import 'widgets/cloud_sync_tile.dart';
import 'widgets/language_tile.dart';
import 'widgets/battery_optimization_tile.dart';
import '../../../core/utils/locale_provider.dart';
import '../../../core/utils/calendar_type_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../navigation/presentation/main_nav_screen.dart'; // Gives us the tour triggers!

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch our key provider so we can display a dynamic subtitle on our main row!
    final currentKey = ref.watch(apiKeyProvider);
    final hasKey = currentKey != null && currentKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(ref.watch(trProvider('settings'))), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- CARD 1: BUDGET LIMITS ---
          const WeeklyBudgetCard(),
          const SizedBox(height: 12),

          // --- CARD 2: DAILY HABIT REMINDER ---
          const DailyReminderCard(),
          const SizedBox(height: 12),

          // --- CARD 2.5: BATTERY OPTIMIZATION ---
          const BatteryOptimizationTile(),
          const SizedBox(height: 12),

          // --- CARD 3: APP CUSTOMIZATION ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined, size: 28),
                  title: Text(
                    ref.watch(trProvider('manage_categories')),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(ref.watch(trProvider('manage_categories_desc'))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CategorySettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),

                // ETHIOPIAN MULTILINGUAL LANGUAGE SELECTOR!
                const LanguageTile(),
                
                const Divider(indent: 16, endIndent: 16, height: 1),

                // CALENDAR SELECTOR
                SwitchListTile(
                  secondary: const Icon(Icons.calendar_month_outlined, size: 28),
                  title: const Text(
                    "Ethiopian Calendar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Use Ethiopian dates across the app"),
                  value: ref.watch(calendarTypeProvider) == CalendarType.ethiopian,
                  onChanged: (val) =>
                      ref.read(calendarTypeProvider.notifier).toggle(),
                ),

                const Divider(indent: 16, endIndent: 16, height: 1),

                // DARK MODE TOGGLE
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, size: 28),
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Toggle dark theme"),
                  value: ref.watch(themeModeProvider) == ThemeMode.dark,
                  onChanged: (val) {
                    final newTheme = val ? ThemeMode.dark : ThemeMode.light;
                    ref.read(themeModeProvider.notifier).updateState(newTheme);
                    saveThemeMode(newTheme);
                  },
                ),

                const Divider(indent: 16, endIndent: 16, height: 1),

                // HELP / TOUR
                ListTile(
                  leading: const Icon(Icons.help_outline, size: 28),
                  title: const Text(
                    "App Tour",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("Replay the onboarding tour"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // 1. Switch back to the main Expense Entry tab
                    ref.read(navIndexProvider.notifier).updateState(0);
                    // 2. Trigger the tour to launch on the main screen
                    ref.read(tourTriggerProvider.notifier).increment();
                    // 3. Pop the settings screen so the main screen is visible
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- CARD 4: THE SECURITY VAULT (Gemini Key + Google Drive Sync) ---
          Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // ROW A: GEMINI KEY (ListTile)
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, size: 28),
                  title: Text(
                    ref.watch(trProvider('gemini_api_key')),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    hasKey
                        ? ref.watch(trProvider('key_active_secured'))
                        : ref.watch(trProvider('add_key_for_ai')),
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
                  title: Text(
                    ref.watch(trProvider('use_ai_parsing')),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    ref.watch(trProvider('when_disabled_notes')),
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
          Center(
            child: Text(
              ref.watch(trProvider('birr_note_footer')),
              style: const TextStyle(
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
