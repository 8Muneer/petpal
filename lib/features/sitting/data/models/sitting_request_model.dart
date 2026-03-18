import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';

class SittingRequestModel extends SittingRequest {
  const SittingRequestModel({
    required super.id,
    required super.ownerUid,
    required super.ownerName,
    super.ownerPhotoUrl,
    required super.petName,
    required super.petType,
    super.petGender,
    super.petImageUrl,
    super.startDate,
    super.endDate,
    required super.sittingType,
    required super.area,
    super.specialInstructions,
    super.budget,
    super.status,
    super.createdAt,
  });

  factory SittingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    PetType petType;
    switch (data['petType'] as String? ?? 'dog') {
      case 'cat':
        petType = PetType.cat;
        break;
      case 'other':
        petType = PetType.other;
        break;
      default:
        petType = PetType.dog;
    }

    PetGender? petGender;
    switch (data['petGender'] as String?) {
      case 'male':
        petGender = PetGender.male;
        break;
      case 'female':
        petGender = PetGender.female;
        break;
      default:
        petGender = null;
    }

    SittingType sittingType;
    switch (data['sittingType'] as String? ?? 'atOwnerHome') {
      case 'atSitterHome':
        sittingType = SittingType.atSitterHome;
        break;
      default:
        sittingType = SittingType.atOwnerHome;
    }

    SittingStatus status;
    switch (data['status'] as String? ?? 'open') {
      case 'taken':
        status = SittingStatus.taken;
        break;
      case 'closed':
        status = SittingStatus.closed;
        break;
      default:
        status = SittingStatus.open;
    }

    return SittingRequestModel(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      petName: data['petName'] as String? ?? '',
      petType: petType,
      petGender: petGender,
      petImageUrl: data['petImageUrl'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      sittingType: sittingType,
      area: data['area'] as String? ?? '',
      specialInstructions: data['specialInstructions'] as String?,
      budget: data['budget'] as String?,
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'petName': petName,
      'petType': petType.name,
      'petGender': petGender?.name,
      'petImageUrl': petImageUrl,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'sittingType': sittingType.name,
      'area': area,
      'specialInstructions': specialInstructions,
      'budget': budget,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
