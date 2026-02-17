import 'package:equatable/equatable.dart';

class FeedComment extends Equatable {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final DateTime? createdAt;

  const FeedComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorPhotoUrl,
        content,
        createdAt,
      ];
}
