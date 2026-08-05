import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/notification_model.dart';
import '../../../provider/notification_provider.dart';
import '../../../controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';
import 'package:digital_khata/theme/app_theme.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;
    final notificationsAsync = ref.watch(notificationsNotifierProvider);
    final groupedNotifications = ref.watch(notificationGroupedProvider);
    final searchQuery = ref.watch(notificationSearchProvider);
    final selectedCategory = ref.watch(notificationCategoryFilterProvider);

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
                leading: IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: isDark ? AppColors.jordyBlue : AppColors.oxfordBlue,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                title: Text(
                  LanguageController.isUrdu ? 'اطلاعات' : 'Notifications',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: isDark ? Colors.white : AppColors.oxfordBlue,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Center(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final unreadCount = ref.watch(unreadCountProvider);
                          return unreadCount.when(
                            data: (count) => count > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.spaceCadet, AppColors.yinMnBlue],
                                      ),
                                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
                      ),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        ref
                            .read(notificationSearchProvider.notifier)
                            .state = value;
                      },
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.oxfordBlue,
                      ),
                      decoration: InputDecoration(
                        hintText: LanguageController.isUrdu ? 'اطلاعات تلاش کریں...' : 'Search notifications...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.6) : AppColors.spaceCadet.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        FilterChip(
                          label: Text(
                            LanguageController.isUrdu ? 'سب' : 'All',
                            textDirection: LanguageController.contentTextDirection,
                          ),
                          selected: selectedCategory == null,
                          selectedColor: AppColors.yinMnBlue,
                          labelStyle: TextStyle(
                            color: selectedCategory == null ? Colors.white : (isDark ? Colors.white : AppColors.oxfordBlue),
                          ),
                          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                          onSelected: (selected) {
                            ref
                                .read(
                                    notificationCategoryFilterProvider.notifier)
                                .state = null;
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ...NotificationCategory.values.map((category) {
                          final isSelected = selectedCategory == category;
                          final categoryName = category.name.replaceAll('_', ' ');
                          final translatedCategoryName = LanguageController.isUrdu
                              ? (categoryName == 'all' ? 'سب' : categoryName)
                              : categoryName;

                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: FilterChip(
                              label: Text(
                                translatedCategoryName,
                                textDirection: LanguageController.contentTextDirection,
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.yinMnBlue,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.oxfordBlue),
                              ),
                              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                              onSelected: (selected) {
                                ref
                                    .read(notificationCategoryFilterProvider
                                        .notifier)
                                    .state = selected ? category : null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

              // Action Buttons
              if (groupedNotifications.values.any((list) => list.isNotEmpty))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(markAllAsReadProvider);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LanguageController.isUrdu ? 'تمام اطلاعات کو پڑھا ہوا نشان زد کر دیا گیا' : 'All notifications marked as read',
                                    textDirection: LanguageController.contentTextDirection,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: Text(
                              LanguageController.isUrdu ? 'سب پڑھا ہوا نشان زد کریں' : 'Mark All Read',
                              textDirection: LanguageController.contentTextDirection,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.yinMnBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  title: Text(
                                    LanguageController.isUrdu ? 'سب صاف کریں؟' : 'Clear All?',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.oxfordBlue,
                                    ),
                                  ),
                                  content: Text(
                                    LanguageController.isUrdu ? 'اس سے تمام اطلاعات حذف ہو جائیں گی۔ اس عمل کو واپس نہیں کیا جا سکتا۔' : 'This will delete all notifications. This action cannot be undone.',
                                    textDirection: LanguageController.contentTextDirection,
                                    style: TextStyle(
                                      color: isDark ? AppColors.lavender : Colors.grey.shade700,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: TextStyle(
                                          color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await ref.read(deleteAllNotificationsProvider);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              LanguageController.isUrdu ? 'تمام اطلاعات حذف کر دی گئیں' : 'All notifications deleted',
                                              textDirection: LanguageController.contentTextDirection,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        LanguageController.isUrdu ? 'حذف کریں' : 'Delete',
                                        textDirection: LanguageController.contentTextDirection,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_rounded, size: 18),
                            label: Text(
                              LanguageController.isUrdu ? 'سب صاف کریں' : 'Clear All',
                              textDirection: LanguageController.contentTextDirection,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Notifications List
              notificationsAsync.when(
                data: (notificationsList) {
                  final hasNotifications = groupedNotifications.values.any((list) => list.isNotEmpty);

                  if (!hasNotifications) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.5) : AppColors.spaceCadet.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              searchQuery.isEmpty && selectedCategory == null
                                  ? (LanguageController.isUrdu ? 'ابھی تک کوئی اطلاع نہیں ہے' : 'No notifications yet')
                                  : (LanguageController.isUrdu ? 'آپ کے فلٹرز سے کوئی اطلاع مطابقت نہیں رکھتی' : 'No notifications match your filters'),
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.lavender : AppColors.spaceCadet.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final groupKeys = groupedNotifications.keys.toList();
                        final groupKey = groupKeys[index];
                        final items = groupedNotifications[groupKey]!;

                        if (items.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: LanguageController.contentTextDirection,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                              child: Text(
                                groupKey,
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.jordyBlue : AppColors.spaceCadet,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...items.map((notification) {
                              return NotificationItem(
                                notification: notification,
                                isDark: isDark,
                              );
                            }),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        );
                      },
                      childCount: groupedNotifications.keys.length,
                    ),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                      child: Container(
                        height: 76,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                    childCount: 5,
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      LanguageController.isUrdu ? 'اطلاعات لوڈ کرنے میں ناکام' : 'Failed to load notifications',
                      textDirection: LanguageController.contentTextDirection,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationItem extends ConsumerWidget {
  final NotificationModel notification;
  final bool isDark;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: notification.isRead
              ? []
              : [
                  BoxShadow(
                    color: notification.typeColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () async {
              if (!notification.isRead) {
                await ref.read(markNotificationAsReadProvider(notification.id));
              }
              if (context.mounted && notification.actionRoute != null) {
                context.push(notification.actionRoute!);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                textDirection: LanguageController.contentTextDirection,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: notification.typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: LanguageController.contentTextDirection,
                      children: [
                        Text(
                          notification.title,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppColors.oxfordBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.lavender
                                : AppColors.yinMnBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(notification.createdAt),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.jordyBlue.withValues(alpha: 0.7) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius:
                                BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger
                                    .withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(
                          width: 10,
                          height: 10,
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      PopupMenuButton<String>(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await ref.read(deleteNotificationProvider(notification.id));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              LanguageController.isUrdu ? 'حذف کریں' : 'Delete',
                              textDirection: LanguageController.contentTextDirection,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.oxfordBlue,
                              ),
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.jordyBlue
                              : AppColors.spaceCadet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (LanguageController.isUrdu) {
      if (difference.inMinutes < 1) {
        return 'ابھی ابھی';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} منٹ پہلے';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} گھنٹے پہلے';
      } else if (difference.inDays == 1) {
        return 'कल'; // Or کل
      } else if (difference.inDays < 7) {
        return '${difference.inDays} دن پہلے';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else {
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }
  }
}