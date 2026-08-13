import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expense_entry/presentation/expense_entry_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../ai_advisor/presentation/advisor_screen.dart';
import '../../../core/notifications/notification_service.dart';
import '../../expense_entry/presentation/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../expense_entry/presentation/widgets/onboarding_tour.dart'; // Gives us the Tour launcher!
import '../../../core/utils/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;

    // Silent startup setups
    Future.microtask(() => NotificationService().checkFirstTimePrompt());

    // NEW: Trigger the onboarding tour on very first launch!
    _checkFirstTimeTour();
  }

  // NEW: Checks if it's first-time launch and triggers the tour
  Future<void> _checkFirstTimeTour() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToured = prefs.getBool('has_toured_onboarding') ?? false;

    if (!hasToured) {
      // We wait 1.5 seconds to let the screen fully render on boot before showing
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          OnboardingTour.show(context, ref);
        }
      });
      await prefs.setBool('has_toured_onboarding', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BirrNote'),
        centerTitle: true,
        actions: [
          // NEW: THE "ON-DEMAND" HELP BUTTON!
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => OnboardingTour.show(context, ref), // Launches the tour!
          ),
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode
            ),
            onPressed: () {
              final currentTheme = ref.read(themeModeProvider);
              final newTheme = currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = newTheme;
              saveThemeMode(newTheme);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ExpenseEntryScreen(), // Tab 0
          DashboardScreen(),
          AdvisorScreen(), // Tab 2: Placeholder
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Update the state when a tab is clicked
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: ref.watch(trProvider('notes')),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: ref.watch(trProvider('dashboard')),
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: ref.watch(trProvider('advisor')),
          ),
        ],
      ),
    );
  }
}
