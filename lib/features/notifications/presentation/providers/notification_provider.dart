import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:petpal/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:petpal/features/notifications/domain/entities/app_notification.dart';
import 'package:petpal/features/notifications/domain/repositories/notification_repository.dart';

final notificationDatasourceProvider = Provider<NotificationRemoteDatasource>((ref) {
  return NotificationRemoteDatasource(ref.watch(firebaseFirestoreProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationDatasourceProvider));
});

/// Real-time stream of notifications for the current user.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

/// Live unread count (capped at 10), independent of the 50-doc display window.
/// Driving the badge off this dedicated query — rather than counting unread
/// items inside notificationsProvider's most-recent-50 stream — fixes the
/// undercount where unread notifications older than the latest 50 were missed.
final _unreadNotificationCountStreamProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return Stream.value(0);
  return ref.watch(notificationDatasourceProvider).watchUnreadCount(uid);
});

/// Unread count — drives the bell badge in LuxuryHero. Stays a synchronous
/// `Provider<int>` so existing consumers don't change; unwraps the stream and
/// falls back to 0 while it's still loading.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(_unreadNotificationCountStreamProvider).asData?.value ?? 0;
});

/// Actions: markAsRead, markAllAsRead, delete.
final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>(
  (ref) => NotificationNotifier(ref.watch(notificationRepositoryProvider)),
);

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repo;

  NotificationNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.markAsRead(notificationId));
  }

  Future<void> markAllAsRead(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.markAllAsRead(userId));
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteNotification(notificationId));
  }
}
