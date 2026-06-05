import 'package:flutter/foundation.dart';
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
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.asData?.value?.uid ?? '';
  debugPrint('[notificationsProvider] authState: $authState, uid: $uid');
  if (uid.isEmpty) {
    debugPrint('[notificationsProvider] Return empty stream because uid is empty');
    return const Stream.empty();
  }
  return ref.watch(notificationRepositoryProvider).watchNotifications(uid);
});

/// Unread count — drives the bell badge in LuxuryHero.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .asData
          ?.value
          .where((n) => !n.isRead)
          .length ??
      0;
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
