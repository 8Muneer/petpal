import 'package:equatable/equatable.dart';

enum PetType { dog, cat, other }

enum PetGender { male, female }

enum WalkStatus { open, taken, closed }

class WalkRequest extends Equatable {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String petName;
  final PetType petType;
  final DateTime? preferredDate;
  final String preferredTime;
  final String duration;
  final String area;
  final String? petImageUrl;
  final PetGender? petGender;
  final String? specialInstructions;
  final String? budget;
  final WalkStatus status;
  final DateTime? createdAt;

  const WalkRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.petName,
    required this.petType,
    this.preferredDate,
    required this.preferredTime,
    required this.duration,
    required this.area,
    this.petImageUrl,
    this.petGender,
    this.specialInstructions,
    this.budget,
    this.status = WalkStatus.open,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        ownerName,
        ownerPhotoUrl,
        petName,
        petType,
        preferredDate,
        preferredTime,
        duration,
        area,
        petImageUrl,
        petGender,
        specialInstructions,
        budget,
        status,
        createdAt,
      ];
}
