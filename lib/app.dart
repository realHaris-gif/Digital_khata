import 'package:flutter/material.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/l10n/app_localizations.dart';
import 'package:digital_khata/routes/app_router.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/widgets/common/notification_popup.dart'; // Import for OverlayNotificationManager

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OverlayNotificationManager _overlayManager;

  @override
  void initState() {
    super.initState();
    _overlayManager = OverlayNotificationManager();
  }

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
              builder: (context, child) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (context) {
                          // Initialize OverlayNotificationManager with the overlay state
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _overlayManager.setOverlayState(
                              Overlay.of(context),
                            );
                          });
                          return child ?? const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              },

              // ============================================
              // LIGHT THEME - Using AppColors consistently
              // ============================================
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: AppColors.surface1,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.light,
                ).copyWith(
                  primary: AppColors.primary,
                  secondary: AppColors.success,
                  tertiary: AppColors.info,
                  surface: AppColors.surface0,
                  surfaceContainer: AppColors.surface2,
                  outline: AppColors.borderStrong,
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.surface0,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  centerTitle: false,
                  scrolledUnderElevation: 0,
                ),
                cardTheme: CardThemeData(
                  color: AppColors.surface0,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: AppColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),

              // ============================================
              // DARK THEME - Using AppColors consistently
              // ============================================
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: AppColors.darkBackground,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.dark,
                ).copyWith(
                  primary: AppColors.primaryAccent,
                  secondary: AppColors.success,
                  tertiary: AppColors.info,
                  surface: AppColors.darkSurface,
                  surfaceContainer: AppColors.darkSurface2,
                  outline: AppColors.darkBorder,
                  onSurface: Colors.white,
                  onBackground: Colors.white,
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.darkBackground,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: false,
                  scrolledUnderElevation: 0,
                ),
                cardTheme: CardThemeData(
                  color: AppColors.darkSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.3)),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: AppColors.darkSurface2.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                  ),
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),

              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}