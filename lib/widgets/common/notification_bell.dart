import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/provider/notification_provider.dart';
import 'package:digital_khata/theme/app_theme.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ThemeController.isDarkMode;

    // Watch the unread count provider
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return IconButton(
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_rounded,
            size: 26,
            color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet,
          ),
          unreadCountAsync.maybeWhen(
            data: (count) {
              if (count <= 0) return const SizedBox.shrink();
              return Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      onPressed: () => context.push('/notifications'),
    );
  }
}