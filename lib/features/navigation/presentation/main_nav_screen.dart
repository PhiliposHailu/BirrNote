import 'package:flutter/material.dart';
import '../../expense_entry/presentation/expense_entry_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../ai_advisor/presentation/advisor_screen.dart';
import '../../../core/notifications/notification_service.dart';
import '../../expense_entry/presentation/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../expense_entry/presentation/widgets/onboarding_tour.dart'; // Gives us the Tour launcher!

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
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
          OnboardingTour.show(context);
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
            onPressed: () => OnboardingTour.show(context), // Launches the tour!
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Advisor',
          ),
        ],
      ),
    );
  }
}
