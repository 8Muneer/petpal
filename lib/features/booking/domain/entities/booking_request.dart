import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  accepted,
  awaitingConfirmation,
  completed,
  declined,
  cancelled,
  // Set server-side by the expireStaleBookings scheduler when a pending request
  // passes its service date without the provider responding.
  expired
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
  final String? preferredTime; // 'HH:mm' — walk start time
  final String? dropOffTime; // 'HH:mm' — sitting drop-off time
  final String? pickupTime; // 'HH:mm' — sitting pickup time
  final String? location; // address / meeting point
  final String? contactPhone; // owner's phone for coordination
  final String? feedingInfo; // optional care detail
  final String? medicationInfo; // optional care detail
  final String? vetContact; // emergency / vet contact
  final String? priceText; // agreed price snapshot at booking time
  final String? priceType; // 'קבוע' | 'לשעה' | 'לפי הסכמה'
  final int? hours; // requested number of hours (walk) — drives hourly total
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
    this.preferredTime,
    this.dropOffTime,
    this.pickupTime,
    this.location,
    this.contactPhone,
    this.feedingInfo,
    this.medicationInfo,
    this.vetContact,
    this.priceText,
    this.priceType,
    this.hours,
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

  /// Live bookings still moving through the flow (vs. terminal history:
  /// completed / declined / cancelled / expired). Used to split the lists.
  bool get isActive =>
      status == BookingStatus.pending ||
      status == BookingStatus.accepted ||
      status == BookingStatus.awaitingConfirmation;

  /// The service's effective end date — the single date for a walk, or the
  /// last day for a multi-night sitting.
  DateTime? get serviceEndDate => endDate ?? requestedDate;

  /// Date-only [start, end] span this booking occupies, or null when no date
  /// is set. Walk = its single day; sitting = start..end.
  (DateTime, DateTime)? get _dayRange {
    DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    if (serviceType == BookingServiceType.sitting) {
      if (startDate == null || endDate == null) return null;
      return (dOnly(startDate!), dOnly(endDate!));
    }
    if (requestedDate == null) return null;
    final d = dOnly(requestedDate!);
    return (d, d);
  }

  static int? _hmToMinutes(String? hm) {
    if (hm == null) return null;
    final p = hm.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// True when this booking and [other] can't both be honoured — mirrors the
  /// server's `bookingsConflict` (C2): overlapping day spans conflict, except
  /// two single-day walks on the same day only clash if their start times are
  /// within 90 minutes (a missing time is treated as a clash).
  bool conflictsWith(BookingRequest other) {
    final a = _dayRange;
    final b = other._dayRange;
    if (a == null || b == null) return false;
    if (a.$2.isBefore(b.$1) || b.$2.isBefore(a.$1)) return false; // disjoint

    final bothSingleWalk = serviceType == BookingServiceType.walk &&
        other.serviceType == BookingServiceType.walk &&
        a.$1 == a.$2 &&
        b.$1 == b.$2 &&
        a.$1 == b.$1;
    if (bothSingleWalk) {
      final ta = _hmToMinutes(preferredTime);
      final tb = _hmToMinutes(other.preferredTime);
      if (ta == null || tb == null) return true;
      return (ta - tb).abs() < 90;
    }
    return true;
  }

  static (int, int)? _parseHm(String? hm) {
    if (hm == null) return null;
    final parts = hm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  /// Time-of-day the service wraps up: a walk's start time, or a sitting's
  /// pickup time. Null when none was recorded.
  String? get _endTimeOfDay =>
      serviceType == BookingServiceType.walk ? preferredTime : pickupTime;

  /// The instant from which completion may be marked — the end date combined
  /// with the end time-of-day when known, otherwise the start of the end day
  /// (preserves the pre-time date-only behaviour for older bookings).
  DateTime? get serviceEndInstant {
    final end = serviceEndDate;
    if (end == null) return null;
    final hm = _parseHm(_endTimeOfDay);
    if (hm == null) return DateTime(end.year, end.month, end.day);
    return DateTime(end.year, end.month, end.day, hm.$1, hm.$2);
  }

  /// Whether the service's end moment has passed. Gates completion so neither
  /// party can close a booking before it could have happened. True when no
  /// date is set (nothing to gate on).
  bool get serviceDateReached {
    final inst = serviceEndInstant;
    if (inst == null) return true;
    return !DateTime.now().isBefore(inst);
  }

  /// Formatted date (+ time when known) from which completion may be marked.
  String? get completionAvailableFromLabel {
    final end = serviceEndDate;
    if (end == null) return null;
    final date =
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
    final hm = _endTimeOfDay;
    return (hm != null && hm.isNotEmpty) ? '$date $hm' : date;
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
        preferredTime,
        dropOffTime,
        pickupTime,
        location,
        contactPhone,
        feedingInfo,
        medicationInfo,
        vetContact,
        priceText,
        priceType,
        hours,
        specialInstructions,
        status,
        providerNote,
        sittingType,
        createdAt,
      ];
}
