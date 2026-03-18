import 'package:equatable/equatable.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';

export 'package:petpal/features/walks/domain/entities/walk_request.dart'
    show PetType, PetGender;

enum SittingType { atOwnerHome, atSitterHome }

enum SittingStatus { open, taken, closed }

class SittingRequest extends Equatable {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String petName;
  final PetType petType;
  final PetGender? petGender;
  final String? petImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final SittingType sittingType;
  final String area;
  final String? specialInstructions;
  final String? budget;
  final SittingStatus status;
  final DateTime? createdAt;

  const SittingRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.petName,
    required this.petType,
    this.petGender,
    this.petImageUrl,
    this.startDate,
    this.endDate,
    required this.sittingType,
    required this.area,
    this.specialInstructions,
    this.budget,
    this.status = SittingStatus.open,
    this.createdAt,
  });

  int get numberOfNights {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        ownerName,
        ownerPhotoUrl,
        petName,
        petType,
        petGender,
        petImageUrl,
        startDate,
        endDate,
        sittingType,
        area,
        specialInstructions,
        budget,
        status,
        createdAt,
      ];
}
