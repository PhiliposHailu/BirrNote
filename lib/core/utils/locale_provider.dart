import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language_code') ?? 'en';
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    state = languageCode;
  }
}

// The StateNotifierProvider holding the active language code ('en', 'am', 'om', 'ti')
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

// Helper provider to directly fetch translated strings!
final trProvider = Provider.family<String, String>((ref, key) {
  final languageCode = ref.watch(localeProvider);
  return AppTranslations.getText(languageCode, key);
});