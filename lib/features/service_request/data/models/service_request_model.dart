import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart';

class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
    required super.ownerUid,
    required super.ownerName,
    super.ownerPhotoUrl,
    required super.petName,
    required super.petSpecies,
    super.petGender,
    super.petImageUrls,
    required super.serviceType,
    required super.area,
    super.specialInstructions,
    super.budget,
    super.walkDate,
    super.walkTime,
    super.walkDuration,
    super.sittingStartDate,
    super.sittingEndDate,
    super.sittingLocation,
    super.status,
    super.applicationCount,
    super.createdAt,
  });

  factory ServiceRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return ServiceRequestModel(
      id: doc.id,
      ownerUid: d['ownerUid'] as String,
      ownerName: d['ownerName'] as String? ?? '',
      ownerPhotoUrl: d['ownerPhotoUrl'] as String?,
      petName: d['petName'] as String? ?? '',
      petSpecies: _petSpecies(d['petSpecies'] as String?),
      petGender: _petGender(d['petGender'] as String?),
      petImageUrls: List<String>.from(d['petImageUrls'] ?? []),
      serviceType: d['serviceType'] == 'sitting'
          ? ServiceType.sitting
          : ServiceType.walk,
      area: d['area'] as String? ?? '',
      specialInstructions: d['specialInstructions'] as String?,
      budget: d['budget'] as String?,
      walkDate: _ts(d['walkDate']),
      walkTime: d['walkTime'] as String?,
      walkDuration: d['walkDuration'] as String?,
      sittingStartDate: _ts(d['sittingStartDate']),
      sittingEndDate: _ts(d['sittingEndDate']),
      sittingLocation: _sittingLocation(d['sittingLocation'] as String?),
      status: _status(d['status'] as String?),
      applicationCount: (d['applicationCount'] as num?)?.toInt() ?? 0,
      createdAt: _ts(d['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'petName': petName,
        'petSpecies': petSpecies.name,
        'petGender': petGender?.name,
        'petImageUrls': petImageUrls,
        'serviceType': serviceType.name,
        'area': area,
        'specialInstructions': specialInstructions,
        'budget': budget,
        'walkDate': walkDate != null ? Timestamp.fromDate(walkDate!) : null,
        'walkTime': walkTime,
        'walkDuration': walkDuration,
        'sittingStartDate': sittingStartDate != null
            ? Timestamp.fromDate(sittingStartDate!)
            : null,
        'sittingEndDate': sittingEndDate != null
            ? Timestamp.fromDate(sittingEndDate!)
            : null,
        'sittingLocation': sittingLocation?.name,
        'status': status.name,
        'applicationCount': applicationCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // ── helpers ────────────────────────────────────────────────────────────────

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static PetSpecies _petSpecies(String? v) => switch (v) {
        'cat' => PetSpecies.cat,
        'rabbit' => PetSpecies.rabbit,
        'bird' => PetSpecies.bird,
        'other' => PetSpecies.other,
        _ => PetSpecies.dog,
      };

  static PetGender? _petGender(String? v) => switch (v) {
        'male' => PetGender.male,
        'female' => PetGender.female,
        _ => null,
      };

  static SittingLocation? _sittingLocation(String? v) => switch (v) {
        'atOwnerHome' => SittingLocation.atOwnerHome,
        'atSitterHome' => SittingLocation.atSitterHome,
        _ => null,
      };

  static ServiceRequestStatus _status(String? v) => switch (v) {
        'booked' => ServiceRequestStatus.booked,
        'completed' => ServiceRequestStatus.completed,
        'cancelled' => ServiceRequestStatus.cancelled,
        _ => ServiceRequestStatus.open,
      };
}
