import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:petpal/features/messaging/data/datasources/fcm_datasource.dart';

/// Top-level handler required by FCM for background/terminated-state messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this is called.
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FcmDatasource _fcmDatasource;

  NotificationService({
    required FirebaseMessaging messaging,
    required FcmDatasource fcmDatasource,
  })  : _messaging = messaging,
        _fcmDatasource = fcmDatasource;

  /// Stream of messages received while the app is in the foreground.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> registerToken(String uid) async {
    try {
      await requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        await _fcmDatasource.saveToken(uid, token);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmDatasource.saveToken(uid, newToken).ignore();
      });
    } catch (_) {
      // Non-critical — app works without push notifications
    }
  }

  Future<void> deregisterToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _fcmDatasource.removeToken(uid, token);
      }
    } catch (_) {
      // Non-critical — ignore failures on logout
    }
  }
}
