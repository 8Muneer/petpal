import 'package:petpal/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
}
