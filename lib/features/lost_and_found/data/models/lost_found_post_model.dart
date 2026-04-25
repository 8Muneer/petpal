import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';

class LostFoundMatchModel extends LostFoundMatch {
  const LostFoundMatchModel({
    required super.postId,
    required super.imageUrl,
    required super.reporterName,
    required super.confidence,
    required super.reason,
  });

  factory LostFoundMatchModel.fromMap(Map<String, dynamic> map) {
    return LostFoundMatchModel(
      postId: map['postId'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      confidence: map['confidence'] as int? ?? 0,
      reason: map['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'imageUrl': imageUrl,
        'reporterName': reporterName,
        'confidence': confidence,
        'reason': reason,
      };
}

class LostFoundPostModel extends LostFoundPost {
  const LostFoundPostModel({
    required super.id,
    required super.reporterUid,
    required super.reporterName,
    super.reporterPhotoUrl,
    required super.type,
    required super.petName,
    required super.species,
    required super.breed,
    required super.color,
    required super.description,
    required super.area,
    required super.imageUrl,
    super.status,
    super.matchingStatus,
    super.createdAt,
    super.matches,
  });

  factory LostFoundPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final matchesList = (data['matches'] as List<dynamic>? ?? [])
        .map((m) => LostFoundMatchModel.fromMap(m as Map<String, dynamic>))
        .toList();

    MatchingStatus matchingStatus;
    switch (data['matchingStatus'] as String?) {
      case 'searching':
        matchingStatus = MatchingStatus.searching;
        break;
      case 'done':
        matchingStatus = MatchingStatus.done;
        break;
      default:
        matchingStatus = MatchingStatus.pending;
    }

    return LostFoundPostModel(
      id: doc.id,
      reporterUid: data['reporterUid'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      reporterPhotoUrl: data['reporterPhotoUrl'] as String?,
      type: (data['type'] as String?) == 'found'
          ? LostFoundType.found
          : LostFoundType.lost,
      petName: data['petName'] as String? ?? '',
      species: data['species'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      color: data['color'] as String? ?? '',
      description: data['description'] as String? ?? '',
      area: data['area'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      status: (data['status'] as String?) == 'resolved'
          ? LostFoundStatus.resolved
          : LostFoundStatus.active,
      matchingStatus: matchingStatus,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      matches: matchesList,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reporterUid': reporterUid,
        'reporterName': reporterName,
        'reporterPhotoUrl': reporterPhotoUrl,
        'type': type == LostFoundType.found ? 'found' : 'lost',
        'petName': petName,
        'species': species,
        'breed': breed,
        'color': color,
        'description': description,
        'area': area,
        'imageUrl': imageUrl,
        'status': 'active',
        'matchingStatus': 'pending',
        'matches': [],
        'createdAt': FieldValue.serverTimestamp(),
      };
}
