import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  final Box _settings = Hive.box('settings');

  ThemeMode get mode {
    final v = _settings.get('darkMode');
    if (v == null) return ThemeMode.light;
    return v ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark {
    final v = _settings.get('darkMode');
    return v == true;
  }

  void setDark(bool dark) {
    _settings.put('darkMode', dark);
    notifyListeners();
  }
}
