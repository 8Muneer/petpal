import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';

class WalkServiceModel extends WalkService {
  const WalkServiceModel({
    required super.id,
    required super.providerUid,
    required super.providerName,
    super.providerPhotoUrl,
    required super.area,
    required super.priceText,
    super.priceType,
    super.bio,
    required super.duration,
    super.petTypes,
    super.availableDays,
    super.isActive,
    super.createdAt,
  });

  factory WalkServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return WalkServiceModel(
      id: doc.id,
      providerUid: data['providerUid'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerPhotoUrl: data['providerPhotoUrl'] as String?,
      area: data['area'] as String? ?? '',
      priceText: data['priceText'] as String? ?? '',
      priceType: data['priceType'] as String? ?? 'קבוע',
      bio: data['bio'] as String?,
      duration: data['duration'] as String? ?? '',
      petTypes: List<String>.from(data['petTypes'] as List? ?? []),
      availableDays: List<String>.from(data['availableDays'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerUid': providerUid,
      'providerName': providerName,
      'providerPhotoUrl': providerPhotoUrl,
      'area': area,
      'priceText': priceText,
      'bio': bio,
      'duration': duration,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
