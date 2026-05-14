import 'package:flutter/foundation.dart';

enum AlertType { info, warning, urgent }

@immutable
class CommunityAlert {
  final String id;
  final String title;
  final String content;
  final String neighborhood;
  final AlertType type;
  final DateTime createdAt;

  const CommunityAlert({
    required this.id,
    required this.title,
    required this.content,
    required this.neighborhood,
    required this.type,
    required this.createdAt,
  });

  factory CommunityAlert.fromMap(String id, Map<String, dynamic> map) {
    return CommunityAlert(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      neighborhood: map['neighborhood'] ?? '',
      type: _mapType(map['type']),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  static AlertType _mapType(String? type) {
    switch (type) {
      case 'warning':
        return AlertType.warning;
      case 'urgent':
        return AlertType.urgent;
      case 'info':
      default:
        return AlertType.info;
    }
  }
}
