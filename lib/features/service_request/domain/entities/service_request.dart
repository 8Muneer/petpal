import 'package:equatable/equatable.dart';

enum ServiceType { walk, sitting }

enum PetSpecies { dog, cat, rabbit, bird, other }

enum PetGender { male, female }

enum SittingLocation { atOwnerHome, atSitterHome }

enum ServiceRequestStatus { open, booked, completed, cancelled }

class ServiceRequest extends Equatable {
  final String id;

  // Owner
  final String ownerUid;
  final String ownerName;
  final String? ownerPhotoUrl;

  // Pet
  final String petName;
  final PetSpecies petSpecies;
  final PetGender? petGender;
  final List<String> petImageUrls;

  // Request type
  final ServiceType serviceType;

  // Shared scheduling
  final String area;
  final String? specialInstructions;
  final String? budget;

  // Walk-specific (null when serviceType == sitting)
  final DateTime? walkDate;
  final String? walkTime;
  final String? walkDuration; // e.g. '30 דקות', 'שעה'

  // Sitting-specific (null when serviceType == walk)
  final DateTime? sittingStartDate;
  final DateTime? sittingEndDate;
  final SittingLocation? sittingLocation;

  // Meta
  final ServiceRequestStatus status;
  final int applicationCount;
  final DateTime? createdAt;

  const ServiceRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.petName,
    required this.petSpecies,
    this.petGender,
    this.petImageUrls = const [],
    required this.serviceType,
    required this.area,
    this.specialInstructions,
    this.budget,
    this.walkDate,
    this.walkTime,
    this.walkDuration,
    this.sittingStartDate,
    this.sittingEndDate,
    this.sittingLocation,
    this.status = ServiceRequestStatus.open,
    this.applicationCount = 0,
    this.createdAt,
  });

  int get numberOfNights {
    if (sittingStartDate == null || sittingEndDate == null) return 0;
    return sittingEndDate!.difference(sittingStartDate!).inDays;
  }

  bool get isOpen => status == ServiceRequestStatus.open;

  @override
  List<Object?> get props => [
        id, ownerUid, ownerName, ownerPhotoUrl,
        petName, petSpecies, petGender, petImageUrls,
        serviceType, area, specialInstructions, budget,
        walkDate, walkTime, walkDuration,
        sittingStartDate, sittingEndDate, sittingLocation,
        status, applicationCount, createdAt,
      ];
}
