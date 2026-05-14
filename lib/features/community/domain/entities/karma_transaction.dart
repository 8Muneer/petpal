import 'package:equatable/equatable.dart';

enum KarmaReason {
  treatReceived,
  recommendationPosted,
  helpfulComment,
  profileCompletion,
  other
}

class KarmaTransaction extends Equatable {
  final String id;
  final String userId;
  final String? relatedPostId;
  final int points;
  final KarmaReason reason;
  final DateTime timestamp;
  final String description;

  const KarmaTransaction({
    required this.id,
    required this.userId,
    this.relatedPostId,
    required this.points,
    required this.reason,
    required this.timestamp,
    required this.description,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        relatedPostId,
        points,
        reason,
        timestamp,
        description,
      ];
}
