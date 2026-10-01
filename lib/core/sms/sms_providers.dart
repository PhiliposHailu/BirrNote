import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_models.dart';

const String kAutoTrackSmsKey = 'auto_track_sms';

class SmsTrackingNotifier extends StateNotifier<bool> {
  SmsTrackingNotifier({bool initial = false}) : super(initial) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kAutoTrackSmsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAutoTrackSmsKey, enabled);
  }
}

/// Controls whether background SMS tracking is active
final smsTrackingEnabledProvider =
    StateNotifierProvider<SmsTrackingNotifier, bool>((ref) {
      return SmsTrackingNotifier();
    });

/// Reserved for future use: in-app SMS queue and review flow.
/// Currently unused — the production deep-link flow uses the notification
/// payload stream (NotificationService.onPayloadTapped → ManualEntrySheet)
/// rather than this provider. Retained for future expansion (e.g. batch SMS review).
final pendingSmsTransactionProvider = StateProvider<ParsedBankSms?>(
  (ref) => null,
);
