import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    required NotificationCategory category,
    required String icon,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'category': category.name,
        'icon': icon,
        'action_route': actionRoute,
        'metadata': metadata,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) =>
            (data as List).map((json) => NotificationModel.fromJson(json)).toList());
  }
}