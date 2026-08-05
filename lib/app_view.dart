import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:digital_khata/l10n/app_localizations.dart';

import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/routes/app_router.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/common/notification_popup.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.localeNotifier,
      builder: (context, currentLocale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.themeModeNotifier, 
          builder: (context, currentThemeMode, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: "Digital Khata",

              // Localization Setup
              locale: currentLocale,
              supportedLocales: const [
                Locale('en'),
                Locale('ur'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // FIX: Cleaned up builder to safely inject overlay without forcing layout re-allocations
              builder: (context, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final overlayState = Overlay.maybeOf(context);
                  if (overlayState != null) {
                    OverlayNotificationManager().setOverlayState(overlayState);
                  }
                });

                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ColoredBox(
                    color: currentThemeMode == ThemeMode.dark 
                        ? AppColors.darkBackground 
                        : AppColors.surface1,
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              
              // Dynamic Theme Setup
              themeMode: currentThemeMode,
              // theme: AppTheme.lightTheme,
              // darkTheme: AppTheme.darkTheme,

              // GoRouter Navigation Integration
              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}