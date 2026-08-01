import 'package:flutter/material.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/routes/app_router.dart';

const Color emerald = Color(0xFF059669);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.themeModeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp.router(
              title: 'Digital Khata',
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              themeMode: themeMode,

              // Light Theme
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.light,
                ).copyWith(
                  primary: Colors.teal.shade700,
                  secondary: emerald,
                  tertiary: Colors.indigo.shade600,
                ),
              ),

              // Dark Emerald Theme
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF101917),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.dark,
                ).copyWith(
                  primary: Colors.teal.shade400,
                  secondary: emerald,
                  tertiary: Colors.indigo.shade300,
                  surface: const Color(0xFF182421),
                ),
              ),

              // Referenced as AppRouter.router because it is static
              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}