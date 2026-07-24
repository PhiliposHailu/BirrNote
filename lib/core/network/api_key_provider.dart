import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Create the secure storage instance
const _storage = FlutterSecureStorage();
const _keyName = 'gemini_api_key';

// 2. StateNotifier to manage the Key
class ApiKeyNotifier extends StateNotifier<String?> {
  ApiKeyNotifier() : super(null) {
    _loadKey();
  }

  // Load the key from the device's secure vault when the app starts
  Future<void> _loadKey() async {
    final key = await _storage.read(key: _keyName);
    state = key; 
  }

  // Save the key to the vault and update the app's state
  Future<void> saveKey(String key) async {
    await _storage.write(key: _keyName, value: key);
    state = key;
  }

  // Delete the key (if they want to revoke access)
  Future<void> deleteKey() async {
    await _storage.delete(key: _keyName);
    state = null;
  }
}

// 3. The Provider so the rest of the app can watch this state
final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  return ApiKeyNotifier();
});

//  Persistent AI Toggle Notifier (Defaults to true)
class AiEnabledNotifier extends StateNotifier<bool> {
  AiEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('use_ai_parsing') ?? true; // Default is ON
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_ai_parsing', value);
    state = value;
  }
}

final aiEnabledProvider = StateNotifierProvider<AiEnabledNotifier, bool>((ref) {
  return AiEnabledNotifier();
});