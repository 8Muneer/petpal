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
  // UI-ready stats (null = not yet available)
  final double? rating;
  final int? reviewCount;
  final int? viewCount;
  final int? requestCount;

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
    this.rating,
    this.reviewCount,
    this.viewCount,
    this.requestCount,
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
        rating,
        reviewCount,
        viewCount,
        requestCount,
      ];
}
