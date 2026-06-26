import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  accepted,
  awaitingConfirmation,
  completed,
  declined,
  cancelled
}

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

  /// The service's effective end date — the single date for a walk, or the
  /// last day for a multi-night sitting.
  DateTime? get serviceEndDate => endDate ?? requestedDate;

  /// Date-only check: the service's end date has arrived. Used to prevent a
  /// provider marking a service complete before it could have happened.
  /// Returns true when no date is set (nothing to gate on).
  bool get serviceDateReached {
    final end = serviceEndDate;
    if (end == null) return true;
    final now = DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(endDay);
  }

  /// Formatted date from which completion may be marked (the service end date).
  String? get completionAvailableFromLabel {
    final end = serviceEndDate;
    if (end == null) return null;
    return '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
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
