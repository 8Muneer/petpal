import 'package:petpal/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:petpal/features/notifications/domain/entities/app_notification.dart';
import 'package:petpal/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _datasource;

  NotificationRepositoryImpl(this._datasource);

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _datasource.watchNotifications(userId);

  @override
  Future<void> markAsRead(String notificationId) =>
      _datasource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead(String userId) =>
      _datasource.markAllAsRead(userId);

  @override
  Future<void> deleteNotification(String notificationId) =>
      _datasource.deleteNotification(notificationId);
}
