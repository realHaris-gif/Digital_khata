import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../repository/notfication_repository.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository();
});

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final notificationsNotifierProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  RealtimeChannel? _realtimeChannel;

  @override
  Future<List<NotificationModel>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];

    final repository = ref.watch(notificationRepositoryProvider);
    
    // Listen to real-time changes from Supabase so notifications appear instantly
    _setupRealtimeSubscription(userId);

    return repository.getUserNotifications(userId: userId, limit: 50, offset: 0);
  }

  void _setupRealtimeSubscription(String userId) {
    _realtimeChannel?.unsubscribe();
    
    final client = Supabase.instance.client;
    _realtimeChannel = client
        .channel('public:notifications:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // New notification inserted, parse and add it straight to state
            try {
              final newNotification = NotificationModel.fromJson(payload.newRecord);
              state.whenData((currentList) {
                // Prevent duplicate additions
                if (!currentList.any((n) => n.id == newNotification.id)) {
                  state = AsyncValue.data([newNotification, ...currentList]);
                  ref.invalidate(unreadCountProvider);
                }
              });
            } catch (_) {
              // Fallback refresh if parsing fails
              refresh();
            }
          },
        )
        .subscribe();

    // Clean up channel when provider is disposed
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return [];
      final repository = ref.read(notificationRepositoryProvider);
      return repository.getUserNotifications(userId: userId, limit: 50, offset: 0);
    });
  }

  Future<void> markAsRead(String id) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAsRead(id);
    
    state.whenData((notifications) {
      state = AsyncValue.data(
        notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    });
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAllAsRead(userId);

    state.whenData((notifications) {
      state = AsyncValue.data(
        notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    });
    ref.invalidate(unreadCountProvider);
  }

  Future<void> delete(String id) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.deleteNotification(id);

    state.whenData((notifications) {
      state = AsyncValue.data(
        notifications.where((n) => n.id != id).toList(),
      );
    });
    ref.invalidate(unreadCountProvider);
  }

  Future<void> deleteAll() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repository = ref.read(notificationRepositoryProvider);
    await repository.deleteAllNotifications(userId);

    state = const AsyncValue.data([]);
    ref.invalidate(unreadCountProvider);
  }
}

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount(userId);
});

final notificationSearchProvider = StateProvider<String>((ref) => '');

final notificationCategoryFilterProvider =
    StateProvider<NotificationCategory?>((ref) => null);

final filteredNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsAsync = ref.watch(notificationsNotifierProvider);
  final searchQuery = ref.watch(notificationSearchProvider);
  final selectedCategory = ref.watch(notificationCategoryFilterProvider);

  return notificationsAsync.maybeWhen(
    data: (data) {
      var filtered = List<NotificationModel>.from(data);

      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((n) =>
                n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                n.message.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      if (selectedCategory != null) {
        filtered =
            filtered.where((n) => n.category == selectedCategory).toList();
      }

      return filtered;
    },
    orElse: () => [],
  );
});

final notificationGroupedProvider =
    Provider<Map<String, List<NotificationModel>>>((ref) {
  final notifications = ref.watch(filteredNotificationsProvider);

  final Map<String, List<NotificationModel>> grouped = {};

  for (var notification in notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    String group;
    final notifDate =
        DateTime(notification.createdAt.year, notification.createdAt.month, notification.createdAt.day);

    if (notifDate == today) {
      group = 'Today';
    } else if (notifDate == yesterday) {
      group = 'Yesterday';
    } else if (notifDate.isAfter(weekAgo)) {
      group = 'This Week';
    } else {
      group = 'Earlier';
    }

    if (grouped[group] == null) {
      grouped[group] = [];
    }
    grouped[group]!.add(notification);
  }

  return grouped;
});

final markNotificationAsReadProvider =
    Provider.family<Future<void>, String>((ref, notificationId) {
  return ref.read(notificationsNotifierProvider.notifier).markAsRead(notificationId);
});

final markAllAsReadProvider = Provider<Future<void>>((ref) {
  return ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
});

final deleteNotificationProvider =
    Provider.family<Future<void>, String>((ref, notificationId) {
  return ref.read(notificationsNotifierProvider.notifier).delete(notificationId);
});

final deleteAllNotificationsProvider = Provider<Future<void>>((ref) {
  return ref.read(notificationsNotifierProvider.notifier).deleteAll();
});