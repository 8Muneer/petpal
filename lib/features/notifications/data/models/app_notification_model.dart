import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/notifications/domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    required super.isRead,
    required super.createdAt,
    super.data,
  });

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data() as Map<String, dynamic>? ?? {};

    NotificationType type;
    switch (raw['type'] as String? ?? '') {
      case 'bookingNew':
        type = NotificationType.bookingNew;
        break;
      case 'bookingAccepted':
        type = NotificationType.bookingAccepted;
        break;
      case 'bookingDeclined':
        type = NotificationType.bookingDeclined;
        break;
      case 'bookingCancelled':
        type = NotificationType.bookingCancelled;
        break;
      case 'newMessage':
        type = NotificationType.newMessage;
        break;
      case 'newReview':
        type = NotificationType.newReview;
        break;
      default:
        type = NotificationType.bookingNew;
    }

    return AppNotificationModel(
      id: doc.id,
      userId: raw['userId'] as String? ?? '',
      title: raw['title'] as String? ?? '',
      body: raw['body'] as String? ?? '',
      type: type,
      isRead: raw['isRead'] as bool? ?? false,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: Map<String, dynamic>.from(raw['data'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }
}
