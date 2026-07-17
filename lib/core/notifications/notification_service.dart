import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data; // FIXED: Loads complete database!
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // 1. INITIALIZE (Silent setup)
  Future<void> initialize() async {
    try {
      // Load the full worldwide timezone database
      tz_data.initializeTimeZones();

      // Fetch the Timezone identifier (e.g. Africa/Addis_Ababa)
      final currentTimeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZoneInfo.identifier));
      
    } catch (e) {
      // SECURE FALLBACK: If lookup fails, try to load Addis Ababa. 
      // If that somehow fails, fallback to UTC so it NEVER crashes your bootup!
      print("⚠️ Timezone setup failed, attempting fallback to Africa/Addis_Ababa. Error: $e");
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
        print("🔔 BirrNote Fallback Match: Success! Set default local zone to Addis_Ababa.");
      } catch (innerError) {
        tz.setLocalLocation(tz.UTC);
        print("🔔 BirrNote Fallback Match: Extreme recovery! Set zone to UTC.");
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
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

  // 4. SCHEDULE DAILY REMINDER WITH AUTO-FALLBACK & DETAILED LOGGER
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await cancelReminder();

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Reminds you to log your daily spending',
      importance: Importance.max,
      priority: Priority.high,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // --- 📊 DETAILED DEBUGGING LOGS ---
    print("---------------------------------------------");
    print("⏰ BIRRNOTE NOTIFICATION LOGGER");
    print("Current System Time (Local): $now");
    print("Inferred App Timezone:       ${tz.local.name}");
    print("Selected Hour:Minute:        $hour:$minute");
    print("Calculated Schedule Time:    $scheduledDate");
    print("Is Scheduled for Tomorrow?   ${scheduledDate.isAfter(now.add(const Duration(hours: 1)))}");
    print("---------------------------------------------");

    try {
      // Attempt to schedule with EXACT, millisecond precision (Bypasses battery delays)
      await _plugin.zonedSchedule(
        id: 100,
        title: 'Time to log your spending! 📝',
        body: 'Keep your daily budget on track. Tap to log today\'s expenses.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Daily Reminder scheduled successfully with EXACT precision.");
    } catch (e) {
      // AUTO-FALLBACK: If Android blocks exact alarms (Android 14+), handle it gracefully!
      print("⚠️ Android exact alarm permission was blocked by your device. Auto-falling back to inexact timing. Error: $e");
      
      await _plugin.zonedSchedule(
        id: 100,
        title: 'Time to log your spending! 📝',
        body: 'Keep your daily budget on track. Tap to log today\'s expenses.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Battery-saver mode fallback
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Daily Reminder scheduled successfully in inexact battery-saver mode.");
    }
  }

  // 5. INSTANT TEST NOTIFICATION
  Future<void> showInstantNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'instant_test_channel',
      'Test Notifications',
      channelDescription: 'Used to test if notifications are working',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.show(
      id: 200,
      title: 'BirrNote Notifications Working! 🎉',
      body: 'If you see this, your phone\'s local notification system is 100% operational.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  // 6. CANCEL REMINDER
  Future<void> cancelReminder() async {
    await _plugin.cancel(id: 100);
  }
}