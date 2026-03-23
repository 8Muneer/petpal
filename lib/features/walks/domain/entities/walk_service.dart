import 'package:equatable/equatable.dart';

class WalkService extends Equatable {
  final String id;
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String area;
  final String priceText;
  final String? bio;
  final String duration; // "30 דקות", "שעה", etc.
  final String priceType; // "קבוע" | "לשעה" | "לפי הסכמה"
  final List<String> petTypes; // ["כלב", "חתול", "אחר"]
  final List<String> availableDays; // ["א", "ב", ...]
  final bool isActive;
  final DateTime? createdAt;

  const WalkService({
    required this.id,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    required this.area,
    required this.priceText,
    this.priceType = 'קבוע',
    this.bio,
    required this.duration,
    this.petTypes = const [],
    this.availableDays = const [],
    this.isActive = true,
    this.createdAt,
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
        duration,
        petTypes,
        availableDays,
        isActive,
        createdAt,
      ];
}
