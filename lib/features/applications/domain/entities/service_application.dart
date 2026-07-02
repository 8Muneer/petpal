import 'package:equatable/equatable.dart';

/// Lifecycle of a provider's offer on an open owner request.
/// pending  → awaiting the owner's decision
/// accepted → owner chose this provider (a booking is created)
/// refused  → owner declined this offer (with an optional reason)
enum ApplicationStatus { pending, accepted, refused }

/// A provider's structured offer ("הגש מועמדות") on a walk/sitting request.
/// Stored at `{requestType}_requests/{requestId}/applications/{providerUid}`,
/// so a provider can only have one live offer per request.
class ServiceApplication extends Equatable {
  final String id; // == providerUid
  final String requestId;
  final String requestType; // 'walk' | 'sitting'
  final String ownerUid; // denormalized from the parent request
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String? price;
  final bool availabilityConfirmed;
  final String? alternativeNote; // proposed alternative when not available
  final int? experienceYears;
  final String? bio;
  final double? ratingAvg; // snapshot at submit time (display only)
  final int? ratingCount;
  final ApplicationStatus status;
  final String? refusalReason;
  final DateTime? createdAt;

  const ServiceApplication({
    required this.id,
    required this.requestId,
    required this.requestType,
    required this.ownerUid,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    this.price,
    this.availabilityConfirmed = true,
    this.alternativeNote,
    this.experienceYears,
    this.bio,
    this.ratingAvg,
    this.ratingCount,
    this.status = ApplicationStatus.pending,
    this.refusalReason,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        requestId,
        requestType,
        ownerUid,
        providerUid,
        providerName,
        providerPhotoUrl,
        price,
        availabilityConfirmed,
        alternativeNote,
        experienceYears,
        bio,
        ratingAvg,
        ratingCount,
        status,
        refusalReason,
        createdAt,
      ];
}
