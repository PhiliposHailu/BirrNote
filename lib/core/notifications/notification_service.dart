import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 1. Create a private constructor (so nobody else can build new ones)
  NotificationService._internal();

  // 2. Create the one single "built" instance
  static final NotificationService _instance = NotificationService._internal();

  // 3. Create a factory constructor that ALWAYS returns the same built instance
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // 1. INITIALIZE ON STARTUP (V22)
  Future<void> initialize() async {
     try {
      // Load the FULL worldwide timezone database (includes Addis Ababa!)
      tz_data.initializeTimeZones();
      
      // Fetch the TimezoneInfo object and grab the '.identifier' string
      final currentTimeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZoneInfo.identifier));
    } catch (e) {
      // DEFENSIVE CODING: If timezone setup ever fails, fallback to standard UTC
      // so the user's app NEVER crashes to a blank screen!
      print("Timezone setup failed, falling back to UTC. Error: $e");
      tz.setLocalLocation(tz.UTC);
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
  }

  // 2. FIRST LAUNCH PROMPT LOGIC
  Future<void> checkFirstTimePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('has_prompted_notifications') ?? false;

    if (!hasPrompted) {
      await requestPermission();
      await prefs.setBool('has_prompted_notifications', true);
    }
  }

  // 3. CHECK / REQUEST PERMISSION
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  // 4. SCHEDULE DAILY REMINDER (V22)
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await cancelReminder();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel', 
      'Daily Reminders',        
      channelDescription: 'Reminds you to log your daily spending',
      importance: Importance.max,
      priority: Priority.high,
    );

    // FIXED: Because the import clash is gone, tz.local is now perfectly matched to Ethiopian Time!
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 100, 
      title: 'Time to log your spending! 📝', 
      body: 'Keep your daily budget on track. Tap to log today\'s expenses.', 
      scheduledDate: scheduledDate, 
      notificationDetails: const NotificationDetails(android: androidDetails), 
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      matchDateTimeComponents: DateTimeComponents.time, 
    );
  }

  // 5. NEW: INSTANT TEST NOTIFICATION (0-second delay)
  Future<void> showInstantNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'instant_test_channel',
      'Test Notifications',
      channelDescription: 'Used to test if notifications are working',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.show(
      id: 200, // Named!
      title: 'BirrNote Notifications Working! 🎉', // Named!
      body: 'If you see this, your phone\'s local notification system is 100% operational.', // Named!
      notificationDetails: const NotificationDetails(android: androidDetails), // Named!
    );
  }

  // 6. CANCEL REMINDER
  Future<void> cancelReminder() async {
    await _plugin.cancel(id: 100); 
  }
}