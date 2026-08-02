import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarType { gregorian, ethiopian }

class CalendarTypeNotifier extends StateNotifier<CalendarType> {
  CalendarTypeNotifier({CalendarType? initial}) : super(initial ?? CalendarType.gregorian) {
    if (initial == null) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('calendar_type');
    if (saved == 'ethiopian') {
      state = CalendarType.ethiopian;
    } else {
      state = CalendarType.gregorian;
    }
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == CalendarType.gregorian) {
      await prefs.setString('calendar_type', 'ethiopian');
      state = CalendarType.ethiopian;
    } else {
      await prefs.setString('calendar_type', 'gregorian');
      state = CalendarType.gregorian;
    }
  }
}

final calendarTypeProvider = StateNotifierProvider<CalendarTypeNotifier, CalendarType>((ref) {
  return CalendarTypeNotifier();
});
