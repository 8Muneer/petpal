import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';

class SittingServiceModel extends SittingService {
  const SittingServiceModel({
    required super.id,
    required super.providerUid,
    required super.providerName,
    super.providerPhotoUrl,
    required super.area,
    required super.priceText,
    super.priceType,
    super.bio,
    super.petTypes,
    super.availableDays,
    super.sittingLocation,
    super.isActive,
    super.experienceYears,
    super.isVerified,
    super.rating,
    super.reviewCount,
    super.viewCount,
    super.requestCount,
    super.createdAt,
    super.tagFrequencies = const {},
    super.reputationBadges = const [],
  });

  factory SittingServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SittingServiceModel(
      id: doc.id,
      providerUid: data['providerUid'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerPhotoUrl: data['providerPhotoUrl'] as String?,
      area: data['area'] as String? ?? '',
      priceText: data['priceText'] as String? ?? '',
      priceType: data['priceType'] as String? ?? 'ללילה',
      bio: data['bio'] as String?,
      petTypes: List<String>.from(data['petTypes'] as List? ?? []),
      availableDays: List<String>.from(data['availableDays'] as List? ?? []),
      sittingLocation: data['sittingLocation'] as String? ?? 'בבית השומר',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      experienceYears: data['experienceYears'] as int? ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
      viewCount: data['viewCount'] as int?,
      requestCount: data['requestCount'] as int?,
      tagFrequencies: Map<String, int>.from(data['tagFrequencies'] as Map? ?? {}),
      reputationBadges: List<String>.from(data['reputationBadges'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerUid': providerUid,
      'providerName': providerName,
      'providerPhotoUrl': providerPhotoUrl,
      'area': area,
      'priceText': priceText,
      'priceType': priceType,
      'bio': bio,
      'petTypes': petTypes,
      'availableDays': availableDays,
      'sittingLocation': sittingLocation,
      'isActive': isActive,
      'experienceYears': experienceYears,
      'isVerified': isVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'tagFrequencies': tagFrequencies,
      'reputationBadges': reputationBadges,
    };
  }
}
