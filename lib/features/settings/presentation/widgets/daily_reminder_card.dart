import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/notifications/notification_service.dart';

class DailyReminderCard extends StatefulWidget {
  const DailyReminderCard({super.key});

  @override
  State<DailyReminderCard> createState() => _DailyReminderCardState();
}

class _DailyReminderCardState extends State<DailyReminderCard> {
  bool _isEnabled = false;
  int _hour = 21; // Default to 9:00 PM
  int _minute = 0;

  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 1. Load saved choices from local storage on bootup
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('is_reminder_enabled') ?? false;
      _hour = prefs.getInt('reminder_hour') ?? 21;
      _minute = prefs.getInt('reminder_minute') ?? 0;
    });
  }

  // 2. The Switch Toggle logic (HCI Permission Check + Clock Picker)
  Future<void> _toggleReminder(bool value) async {
    if (value) {
      // Step A: Request OS permissions (HCI Safety)
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        setState(() => _isEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable notification permissions first.')),
          );
        }
        return;
      }

      // Step B: Pop open the native Time Picker Clock Dial
      if (mounted) {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: _hour, minute: _minute),
        );

        if (picked != null) {
          setState(() {
            _isEnabled = true;
            _hour = picked.hour;
            _minute = picked.minute;
          });

          // Save choice to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_reminder_enabled', true);
          await prefs.setInt('reminder_hour', picked.hour);
          await prefs.setInt('reminder_minute', picked.minute);

          // Schedule the repeating alarm inside Android
          await _notificationService.scheduleDailyReminder(picked.hour, picked.minute);
        } else {
          // If they click cancel on the clock picker, keep toggle OFF
          setState(() => _isEnabled = false);
        }
      }
    } else {
      // Step C: Turn OFF and cancel the scheduled alarm
      setState(() => _isEnabled = false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_reminder_enabled', false);
      await _notificationService.cancelReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: _hour, minute: _minute);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Reminder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEnabled 
                        ? 'Remind me daily at ${time.format(context)}'
                        : 'Receive a reminder to log your spending every night',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isEnabled,
              onChanged: _toggleReminder, // Pointing strictly to _toggleReminder!
            ),
          ],
        ),
      ),
    );
  }
}