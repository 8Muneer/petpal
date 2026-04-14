import 'package:equatable/equatable.dart';

enum LostFoundType { lost, found }

enum LostFoundStatus { active, resolved }

class LostFoundMatch extends Equatable {
  final String postId;
  final String imageUrl;
  final String reporterName;
  final int confidence;
  final String reason;

  const LostFoundMatch({
    required this.postId,
    required this.imageUrl,
    required this.reporterName,
    required this.confidence,
    required this.reason,
  });

  @override
  List<Object?> get props => [postId, confidence];
}

class LostFoundPost extends Equatable {
  final String id;
  final String reporterUid;
  final String reporterName;
  final String? reporterPhotoUrl;
  final LostFoundType type;
  final String petName;
  final String species;
  final String breed;
  final String color;
  final String description;
  final String area;
  final String imageUrl;
  final LostFoundStatus status;
  final DateTime? createdAt;
  final List<LostFoundMatch> matches;

  const LostFoundPost({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    this.reporterPhotoUrl,
    required this.type,
    required this.petName,
    required this.species,
    required this.breed,
    required this.color,
    required this.description,
    required this.area,
    required this.imageUrl,
    this.status = LostFoundStatus.active,
    this.createdAt,
    this.matches = const [],
  });

  @override
  List<Object?> get props => [id, reporterUid, type, status, imageUrl];
}
