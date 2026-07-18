import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
import 'samsung_time_dialog.dart'; // Import our new clean dialog!

class DailyReminderCard extends StatefulWidget {
  const DailyReminderCard({super.key});

  @override
  State<DailyReminderCard> createState() => _DailyReminderCardState();
}

class _DailyReminderCardState extends State<DailyReminderCard> {
  bool _isEnabled = false;
  int _hour = 21; // Default to 9:00 PM (21:00)
  int _minute = 0;

  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('is_reminder_enabled') ?? false;
      _hour = prefs.getInt('reminder_hour') ?? 21;
      _minute = prefs.getInt('reminder_minute') ?? 0;
    });
  }

  String _formatTime12h(int hour, int minute) {
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $amPm';
  }

  String _getTimeRemaining(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    final difference = scheduled.difference(now);
    final hrs = difference.inHours;
    final mins = difference.inMinutes % 60;
    
    if (hrs == 0) {
      return 'In $mins min';
    }
    return 'In $hrs hr, $mins min';
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        setState(() => _isEnabled = false);
        return;
      }

      if (mounted) {
        // POP OPEN OUR NEW CLEAN, DRY DIALOG!
        showDialog(
          context: context,
          builder: (context) => SamsungTimeDialog(
            initialHour: _hour,
            initialMinute: _minute,
            onSave: (hour, minute) async {
              Navigator.pop(context); // Close dialog
              setState(() {
                _isEnabled = true;
                _hour = hour;
                _minute = minute;
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_reminder_enabled', true);
              await prefs.setInt('reminder_hour', hour);
              await prefs.setInt('reminder_minute', minute);

              await _notificationService.scheduleDailyReminder(hour, minute);
            },
          ),
        );
      }
    } else {
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
                        ? 'Remind me daily at ${_formatTime12h(_hour, _minute)} (${_getTimeRemaining(_hour, _minute)})'
                        : 'Receive a reminder to log your spending every night',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isEnabled,
              onChanged: _toggleReminder,
            ),
          ],
        ),
      ),
    );
  }
}