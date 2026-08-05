import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  static bool get isUrdu => localeNotifier.value.languageCode == 'ur';

  static bool get isEnglish => localeNotifier.value.languageCode == 'en';

  /// App chrome/layout always stays LTR. Use this only for content text runs.
  static TextDirection get contentTextDirection =>
      isUrdu ? TextDirection.rtl : TextDirection.ltr;

  /// Align translated content inside its own box; does not mirror layout.
  static TextAlign get contentTextAlign =>
      isUrdu ? TextAlign.right : TextAlign.left;

  static TextAlign get contentTextAlignStart =>
      isUrdu ? TextAlign.right : TextAlign.left;

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
