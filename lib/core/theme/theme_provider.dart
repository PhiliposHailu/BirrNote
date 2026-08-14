import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode initial;
  ThemeModeNotifier({this.initial = ThemeMode.system});

  @override
  ThemeMode build() => initial;

  void updateState(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', mode.name);
}
