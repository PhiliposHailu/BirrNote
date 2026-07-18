import 'package:flutter/material.dart';
import 'time_roller_column.dart';

class SamsungTimeDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final Function(int hour, int minute) onSave;

  const SamsungTimeDialog({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.onSave,
  });

  @override
  State<SamsungTimeDialog> createState() => _SamsungTimeDialogState();
}

class _SamsungTimeDialogState extends State<SamsungTimeDialog> {
  late int _selectedHourIndex; // Stores index 0-11
  late int _selectedMinute;
  late int _selectedAmPmIndex; // 0 = AM, 1 = PM

  @override
  void initState() {
    super.initState();
    _selectedMinute = widget.initialMinute;

    // 1. TRANSLATION: 24h hour (0-23) ──► 12h hour (1-12) & AM/PM
    int displayHour = widget.initialHour % 12;
    if (displayHour == 0) displayHour = 12;
    _selectedHourIndex = displayHour - 1; // Maps 1-12 to index 0-11

    _selectedAmPmIndex = widget.initialHour >= 12 ? 1 : 0;
  }

  void _handleSave() {
    // 2. TRANSLATION: 12h hour & AM/PM ──► 24h hour (0-23)
    final finalHourVal = _selectedHourIndex + 1; // Map index 0-11 back to 1-12
    final isPm = _selectedAmPmIndex == 1;

    int final24hHour = finalHourVal;
    if (isPm) {
      if (finalHourVal != 12) final24hHour += 12;
    } else {
      if (finalHourVal == 12) final24hHour = 0;
    }

    widget.onSave(final24hHour, _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Set Reminder',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. THE 12-HOUR COLUMN
          TimeRollerColumn(
            label: 'Hours',
            maxCount: 12,
            initialItem: _selectedHourIndex,
            is12Hour: true, // TRIGGERS 12H MODE!
            onChanged: (val) => _selectedHourIndex = val,
          ),

          const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),

          // 2. THE MINUTES COLUMN
          TimeRollerColumn(
            label: 'Minutes',
            maxCount: 60,
            initialItem: _selectedMinute,
            onChanged: (val) => _selectedMinute = val,
          ),

          const SizedBox(width: 8),

          // 3. THE AM/PM COLUMN
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AM/PM', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: 50,
                height: 150,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    setState(() {});
                    return false;
                  },
                  child: ListWheelScrollView(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(initialItem: _selectedAmPmIndex),
                    onSelectedItemChanged: (index) => _selectedAmPmIndex = index,
                    children: ['AM', 'PM'].map((label) {
                      final isSelected = (_selectedAmPmIndex == 0 && label == 'AM') || 
                                         (_selectedAmPmIndex == 1 && label == 'PM');
                      return Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        FilledButton(
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}