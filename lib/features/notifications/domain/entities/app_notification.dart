import 'package:equatable/equatable.dart';

enum NotificationType {
  bookingNew,
  bookingAccepted,
  bookingDeclined,
  bookingCancelled,
  newMessage,
  newReview,
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  String? get bookingId => data['bookingId'] as String?;
  String? get conversationId => data['conversationId'] as String?;

  @override
  List<Object?> get props => [id, userId, title, body, type, isRead, createdAt, data];
}
