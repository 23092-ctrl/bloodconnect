import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsController extends ChangeNotifier {
  static const _box = 'settings';

  Locale _locale = const Locale('fr');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  static Future<void> init() async {
    await Hive.openBox(_box);
  }

  void loadFromStorage() {
    final box = Hive.box(_box);
    _locale = Locale(box.get('locale', defaultValue: 'fr') as String);
    _themeMode = (box.get('dark', defaultValue: false) as bool)
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    await Hive.box(_box).put('locale', languageCode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await Hive.box(_box).put('dark', isDark);
    notifyListeners();
  }
}
