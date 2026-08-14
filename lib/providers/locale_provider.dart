import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru')) {
    _loadLocale();
  }

  void _loadLocale() {
    final box = Hive.box('settings');
    final lang = box.get('language', defaultValue: 'ru');
    state = Locale(lang);
  }

  void setLocale(String languageCode) {
    state = Locale(languageCode);
    final box = Hive.box('settings');
    box.put('language', languageCode);
  }

  String getCurrentLanguage() {
    return state.languageCode;
  }
}