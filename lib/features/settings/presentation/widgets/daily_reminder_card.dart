import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/notifications/notification_service.dart';

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

  // --- THE SAMSUNG-STYLE HYBRID DIALOG ---
  void _showSamsungTimeDialog() {
    int tempHour = _hour;
    int tempMinute = _minute;

    bool isEditingHour = false;
    bool isEditingMinute = false;

    final hourScrollController = FixedExtentScrollController(initialItem: tempHour);
    final minuteScrollController = FixedExtentScrollController(initialItem: tempMinute);

    final hourInputController = TextEditingController();
    final minuteInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212), // Deep Samsung dark-mode black!
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text(
                'Set Reminder',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- COLUMN 1: HOURS ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Hours', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        height: 150,
                        child: isEditingHour
                            ? Center(
                                child: TextField(
                                  controller: hourInputController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  autofocus: true,
                                  maxLength: 2,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (val) {
                                    final h = int.tryParse(val);
                                    dialogSetState(() {
                                      isEditingHour = false;
                                      if (h != null && h >= 0 && h < 24) {
                                        tempHour = h;
                                        hourScrollController.jumpToItem(h); 
                                      }
                                    });
                                  },
                                ),
                              )
                            // THE MAGIC: NotificationListener recalculates our math on every single scroll tick!
                            : NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  dialogSetState(() {}); // Force local dialog rebuild while scrolling
                                  return false;
                                },
                                child: ListWheelScrollView.useDelegate(
                                  controller: hourScrollController,
                                  itemExtent: 50,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    dialogSetState(() {
                                      tempHour = index;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 24,
                                    builder: (context, index) {
                                      // --- THE ANALOG INTERPOLATION MATH ---
                                      double hourOffset = tempHour.toDouble();
                                      if (hourScrollController.hasClients) {
                                        // Calculates precisely where the wheel is, including fractions (e.g. 12.4)
                                        hourOffset = hourScrollController.offset / 50.0;
                                      }
                                      
                                      // Find how far this specific number is from the center line
                                      final double distance = (index - hourOffset).abs();
                                      
                                      // Smoothly fade opacity from 100% (centered) to 30% (scrolled away)
                                      final double opacity = (1.0 - (distance * 0.7)).clamp(0.3, 1.0);
                                      
                                      // Smoothly shrink font size from 32 (centered) to 22 (scrolled away)
                                      final double fontSize = (32.0 - (distance * 8.0)).clamp(22.0, 32.0);
                                      final isSelected = index == tempHour;

                                      return GestureDetector(
                                        onTap: () {
                                          if (isSelected) {
                                            dialogSetState(() {
                                              isEditingHour = true;
                                              hourInputController.text = index.toString().padLeft(2, '0');
                                            });
                                          }
                                        },
                                        child: Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: Colors.white.withOpacity(opacity), // Fluid color fade!
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),

                  // THE COLON SEPARATOR
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 16),
                        Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),

                  // --- COLUMN 2: MINUTES ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Minutes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        height: 150,
                        child: isEditingMinute
                            ? Center(
                                child: TextField(
                                  controller: minuteInputController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  autofocus: true,
                                  maxLength: 2,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (val) {
                                    final m = int.tryParse(val);
                                    dialogSetState(() {
                                      isEditingMinute = false;
                                      if (m != null && m >= 0 && m < 60) {
                                        tempMinute = m;
                                        minuteScrollController.jumpToItem(m);
                                      }
                                    });
                                  },
                                ),
                              )
                            // THE MAGIC: NotificationListener recalculates our math on every single scroll tick!
                            : NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  dialogSetState(() {}); // Force local dialog rebuild while scrolling
                                  return false;
                                },
                                child: ListWheelScrollView.useDelegate(
                                  controller: minuteScrollController,
                                  itemExtent: 50,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    dialogSetState(() {
                                      tempMinute = index;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 60,
                                    builder: (context, index) {
                                      // --- THE ANALOG INTERPOLATION MATH ---
                                      double minuteOffset = tempMinute.toDouble();
                                      if (minuteScrollController.hasClients) {
                                        minuteOffset = minuteScrollController.offset / 50.0;
                                      }
                                      
                                      final double distance = (index - minuteOffset).abs();
                                      final double opacity = (1.0 - (distance * 0.7)).clamp(0.3, 1.0);
                                      final double fontSize = (32.0 - (distance * 8.0)).clamp(22.0, 32.0);
                                      final isSelected = index == tempMinute;

                                      return GestureDetector(
                                        onTap: () {
                                          if (isSelected) {
                                            dialogSetState(() {
                                              isEditingMinute = true;
                                              minuteInputController.text = index.toString().padLeft(2, '0');
                                            });
                                          }
                                        },
                                        child: Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: Colors.white.withOpacity(opacity), // Fluid color fade!
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!_isEnabled) this.setState(() => _isEnabled = false);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    this.setState(() {
                      _isEnabled = true;
                      _hour = tempHour;
                      _minute = tempMinute;
                    });

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_reminder_enabled', true);
                    await prefs.setInt('reminder_hour', tempHour);
                    await prefs.setInt('reminder_minute', tempMinute);

                    await _notificationService.scheduleDailyReminder(tempHour, tempMinute);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        setState(() => _isEnabled = false);
        return;
      }

      _showSamsungTimeDialog();
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
                        ? 'Remind me daily at ${time.format(context)}'
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