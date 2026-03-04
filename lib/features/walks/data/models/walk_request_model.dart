import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';

class WalkRequestModel extends WalkRequest {
  const WalkRequestModel({
    required super.id,
    required super.ownerUid,
    required super.ownerName,
    super.ownerPhotoUrl,
    required super.petName,
    required super.petType,
    super.preferredDate,
    required super.preferredTime,
    required super.duration,
    required super.area,
    super.petImageUrl,
    super.petGender,
    super.specialInstructions,
    super.budget,
    super.status,
    super.createdAt,
  });

  factory WalkRequestModel.fromFirestore(DocumentSnapshot doc) {
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

    WalkStatus status;
    switch (data['status'] as String? ?? 'open') {
      case 'taken':
        status = WalkStatus.taken;
        break;
      case 'closed':
        status = WalkStatus.closed;
        break;
      default:
        status = WalkStatus.open;
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

    return WalkRequestModel(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      petName: data['petName'] as String? ?? '',
      petType: petType,
      preferredDate: (data['preferredDate'] as Timestamp?)?.toDate(),
      preferredTime: data['preferredTime'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      area: data['area'] as String? ?? '',
      petImageUrl: data['petImageUrl'] as String?,
      petGender: petGender,
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
      'preferredDate':
          preferredDate != null ? Timestamp.fromDate(preferredDate!) : null,
      'preferredTime': preferredTime,
      'duration': duration,
      'area': area,
      'petImageUrl': petImageUrl,
      'petGender': petGender?.name,
      'specialInstructions': specialInstructions,
      'budget': budget,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
