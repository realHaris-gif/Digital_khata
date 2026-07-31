import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:digital_khata/l10n/app_localizations.dart';

import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/routes/app_router.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.localeNotifier,
      builder: (context, currentLocale, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: "Digital Khata",
          
          // Localization Setup
          locale: currentLocale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('ur'), // Urdu (Automatic RTL)
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme Setup
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(
              surface: Colors.grey.shade100,
              onSurface: Colors.black,
              primary: const Color(0xFF4A90E2),
              secondary: const Color(0xFF1ABC9C),
              tertiary: const Color(0xFFBDC3C7),
              outline: Colors.grey,
            ),
          ),

          // GoRouter Navigation Integration
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}