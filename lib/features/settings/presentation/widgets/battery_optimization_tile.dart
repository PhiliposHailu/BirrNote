import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationTile extends ConsumerWidget {
  const BatteryOptimizationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(Icons.battery_charging_full_outlined, size: 28),
        title: const Text(
          "Unrestrict Background Alarms",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "Prevent Android from killing your daily reminders in deep sleep.",
        ),
        trailing: const Icon(Icons.shield_outlined),
        onTap: () async {
          // Ask Android if we are currently unrestricted
          final isRestricted = await Permission.ignoreBatteryOptimizations.isDenied;
          
          if (!context.mounted) return;

          if (isRestricted) {
            // Request Android to open the system-level "Allow background?" prompt
            final status = await Permission.ignoreBatteryOptimizations.request();
            if (status.isGranted) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Alarms are now protected!")),
                );
              }
            }
          } else {
            // Already protected!
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("BirrNote is already unrestricted!")),
            );
          }
        },
      ),
    );
  }
}
