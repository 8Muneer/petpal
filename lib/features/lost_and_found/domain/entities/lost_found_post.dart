import 'package:equatable/equatable.dart';

enum LostFoundType { lost, found }

enum LostFoundStatus { active, resolved }

enum MatchingStatus { pending, searching, done }

class MatchFeature extends Equatable {
  final String featureName;
  final String pet1Value;
  final String pet2Value;
  final String status; // 'MATCH' | 'MISMATCH' | 'CANNOT_DETERMINE'

  const MatchFeature({
    required this.featureName,
    required this.pet1Value,
    required this.pet2Value,
    required this.status,
  });

  @override
  List<Object?> get props => [featureName, pet1Value, pet2Value, status];
}

class LostFoundMatch extends Equatable {
  final String postId;
  final String imageUrl;
  final String reporterName;
  final int confidence;
  final String reason;
  final List<MatchFeature> features;

  const LostFoundMatch({
    required this.postId,
    required this.imageUrl,
    required this.reporterName,
    required this.confidence,
    required this.reason,
    this.features = const [],
  });

  @override
  List<Object?> get props => [postId, confidence, features];
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
  final String? size;   // 'קטן' | 'בינוני' | 'גדול'
  final String? gender; // 'זכר' | 'נקבה'
  final LostFoundStatus status;
  final MatchingStatus matchingStatus;
  final DateTime? createdAt;
  final List<LostFoundMatch> matches;
  final double? latitude;
  final double? longitude;

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
    this.size,
    this.gender,
    this.status = LostFoundStatus.active,
    this.matchingStatus = MatchingStatus.pending,
    this.createdAt,
    this.matches = const [],
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [id, reporterUid, type, status, matchingStatus, imageUrl, size, gender, latitude, longitude];
}
