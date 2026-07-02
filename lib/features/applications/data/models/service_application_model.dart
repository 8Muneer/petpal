import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/applications/domain/entities/service_application.dart';

class ServiceApplicationModel extends ServiceApplication {
  const ServiceApplicationModel({
    required super.id,
    required super.requestId,
    required super.requestType,
    required super.ownerUid,
    required super.providerUid,
    required super.providerName,
    super.providerPhotoUrl,
    super.price,
    super.availabilityConfirmed,
    super.alternativeNote,
    super.experienceYears,
    super.bio,
    super.ratingAvg,
    super.ratingCount,
    super.status,
    super.refusalReason,
    super.createdAt,
  });

  factory ServiceApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    ApplicationStatus status;
    switch (data['status'] as String? ?? 'pending') {
      case 'accepted':
        status = ApplicationStatus.accepted;
        break;
      case 'refused':
        status = ApplicationStatus.refused;
        break;
      default:
        status = ApplicationStatus.pending;
    }

    return ServiceApplicationModel(
      id: doc.id,
      requestId: data['requestId'] as String? ?? '',
      requestType: data['requestType'] as String? ?? 'walk',
      ownerUid: data['ownerUid'] as String? ?? '',
      providerUid: data['providerUid'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerPhotoUrl: data['providerPhotoUrl'] as String?,
      price: data['price'] as String?,
      availabilityConfirmed: data['availabilityConfirmed'] as bool? ?? true,
      alternativeNote: data['alternativeNote'] as String?,
      experienceYears: (data['experienceYears'] as num?)?.toInt(),
      bio: data['bio'] as String?,
      ratingAvg: (data['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as num?)?.toInt(),
      status: status,
      refusalReason: data['refusalReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Payload for creating/overwriting an application. `createdAt` is stamped
  /// server-side; `status` always starts 'pending' from the client.
  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'requestType': requestType,
      'ownerUid': ownerUid,
      'providerUid': providerUid,
      'providerName': providerName,
      'providerPhotoUrl': providerPhotoUrl,
      'price': price,
      'availabilityConfirmed': availabilityConfirmed,
      'alternativeNote': alternativeNote,
      'experienceYears': experienceYears,
      'bio': bio,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'status': status.name,
      'refusalReason': refusalReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
