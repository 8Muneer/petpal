import 'package:equatable/equatable.dart';

enum BookingStatus { pending, accepted, declined, cancelled }

enum BookingServiceType { walk, sitting }

class BookingRequest extends Equatable {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String serviceId;
  final BookingServiceType serviceType;
  final String petName;
  final String petType;
  final String? petImageUrl;
  final DateTime? requestedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? specialInstructions;
  final BookingStatus status;
  final String? providerNote;
  final String? sittingType; // 'atOwnerHome' | 'atSitterHome' — only for sitting bookings
  final DateTime? createdAt;

  const BookingRequest({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    required this.serviceId,
    required this.serviceType,
    required this.petName,
    required this.petType,
    this.petImageUrl,
    this.requestedDate,
    this.startDate,
    this.endDate,
    this.specialInstructions,
    this.status = BookingStatus.pending,
    this.providerNote,
    this.sittingType,
    this.createdAt,
  });

  String get formattedDateRange {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    if (requestedDate != null) return fmt(requestedDate!);
    if (startDate != null && endDate != null) {
      return '${fmt(startDate!)} - ${fmt(endDate!)}';
    }
    return 'תאריך לא נקבע';
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        ownerName,
        ownerPhotoUrl,
        providerUid,
        providerName,
        providerPhotoUrl,
        serviceId,
        serviceType,
        petName,
        petType,
        petImageUrl,
        requestedDate,
        startDate,
        endDate,
        specialInstructions,
        status,
        providerNote,
        sittingType,
        createdAt,
      ];
}
