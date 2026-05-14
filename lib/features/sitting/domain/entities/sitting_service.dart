import 'package:equatable/equatable.dart';

class SittingService extends Equatable {
  final String id;
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String area;
  final String priceText;
  final String priceType; // 'ללילה' | 'ליום' | 'לפי הסכמה'
  final String? bio;
  final List<String> petTypes; // ['כלב', 'חתול', 'אחר']
  final List<String> availableDays; // ['א', 'ב', ...]
  final String sittingLocation; // 'בבית השומר' | 'בבית הבעלים' | 'שניהם'
  final bool isActive;
  final DateTime? createdAt;
  final int experienceYears;
  final bool isVerified;
  final double? rating;
  final int? reviewCount;
  final int? viewCount;
  final int? requestCount;
  final Map<String, int> tagFrequencies;
  final List<String> reputationBadges;

  const SittingService({
    required this.id,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    required this.area,
    required this.priceText,
    this.priceType = 'ללילה',
    this.bio,
    this.petTypes = const [],
    this.availableDays = const [],
    this.sittingLocation = 'בבית השומר',
    this.isActive = true,
    this.createdAt,
    this.experienceYears = 0,
    this.isVerified = false,
    this.rating,
    this.reviewCount,
    this.viewCount,
    this.requestCount,
    this.tagFrequencies = const {},
    this.reputationBadges = const [],
  });

  @override
  List<Object?> get props => [
        id,
        providerUid,
        providerName,
        providerPhotoUrl,
        area,
        priceText,
        priceType,
        bio,
        petTypes,
        availableDays,
        sittingLocation,
        isActive,
        createdAt,
        experienceYears,
        isVerified,
        rating,
        reviewCount,
        viewCount,
        requestCount,
        tagFrequencies,
        reputationBadges,
      ];
}
