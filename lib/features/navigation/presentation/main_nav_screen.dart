import 'package:flutter/material.dart';
import '../../expense_entry/presentation/expense_entry_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../ai_advisor/presentation/advisor_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BirrNote'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      
      // The IndexedStack keeps the hidden tabs "alive" in memory
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