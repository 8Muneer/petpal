import 'package:flutter/foundation.dart';

enum TrustPostType { update, recommendation, playdate, tip }

@immutable
class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String authorNeighborhood;
  final int authorKarma;
  final bool isAuthorVerified;
  
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final TrustPostType type;
  final int likes;
  final int treats;
  final String? topic;
  final int commentsCount;
  final bool isUrgent;
  
  // Associated Service for "Neighbor Recommendations"
  final String? associatedServiceId;
  final String? associatedServiceName;
  final double? associatedServiceRating;
  final bool isLikedByMe;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.authorNeighborhood,
    required this.authorKarma,
    required this.isAuthorVerified,
    required this.content,
    this.imageUrls,
    required this.createdAt,
    required this.type,
    this.likes = 0,
    this.treats = 0,
    this.topic,
    this.commentsCount = 0,
    this.isUrgent = false,
    this.associatedServiceId,
    this.associatedServiceName,
    this.associatedServiceRating,
    this.isLikedByMe = false,
  });

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? authorNeighborhood,
    int? authorKarma,
    bool? isAuthorVerified,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    TrustPostType? type,
    int? likes,
    int? treats,
    String? topic,
    int? commentsCount,
    bool? isUrgent,
    String? associatedServiceId,
    String? associatedServiceName,
    double? associatedServiceRating,
    bool? isLikedByMe,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      authorNeighborhood: authorNeighborhood ?? this.authorNeighborhood,
      authorKarma: authorKarma ?? this.authorKarma,
      isAuthorVerified: isAuthorVerified ?? this.isAuthorVerified,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      treats: treats ?? this.treats,
      topic: topic ?? this.topic,
      commentsCount: commentsCount ?? this.commentsCount,
      isUrgent: isUrgent ?? this.isUrgent,
      associatedServiceId: associatedServiceId ?? this.associatedServiceId,
      associatedServiceName: associatedServiceName ?? this.associatedServiceName,
      associatedServiceRating: associatedServiceRating ?? this.associatedServiceRating,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}
