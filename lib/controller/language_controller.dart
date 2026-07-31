import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    localeNotifier.value = Locale(langCode);
  }

  static Future<void> changeLanguage(Locale newLocale) async {
    localeNotifier.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }
}