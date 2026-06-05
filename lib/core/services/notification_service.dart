import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:petpal/features/messaging/data/datasources/fcm_datasource.dart';

/// Top-level handler required by FCM for background/terminated-state messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized before this is called.
  // The OS notification tray handles display automatically from the FCM
  // `notification` payload sent by Cloud Functions. No client-side work needed
  // here — the Firestore stream in NotificationsScreen picks up the new
  // notification document written by the Cloud Function.
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FcmDatasource _fcmDatasource;

  // Stored so we can cancel the listener before re-registering on a new UID.
  StreamSubscription<String>? _tokenRefreshSub;
  // Tracks the UID whose token is currently registered, to prevent duplicate
  // subscriptions when registerToken is called more than once per service instance.
  String? _registeredUid;

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
    if (_registeredUid == uid) return;
    try {
      await requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        await _fcmDatasource.saveToken(uid, token);
      }
      // Cancel any previous refresh listener before registering a new one.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        _fcmDatasource.saveToken(uid, newToken).ignore();
      });
      _registeredUid = uid;
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
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      _registeredUid = null;
    } catch (_) {
      // Non-critical — ignore failures on logout
    }
  }
}
