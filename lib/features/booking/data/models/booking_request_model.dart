import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';

class BookingRequestModel extends BookingRequest {
  const BookingRequestModel({
    required super.id,
    required super.ownerUid,
    required super.ownerName,
    super.ownerPhotoUrl,
    required super.providerUid,
    required super.providerName,
    super.providerPhotoUrl,
    required super.serviceId,
    required super.serviceType,
    required super.petName,
    required super.petType,
    super.petImageUrl,
    super.requestedDate,
    super.startDate,
    super.endDate,
    super.specialInstructions,
    super.status,
    super.providerNote,
    super.createdAt,
  });

  factory BookingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    BookingStatus status;
    switch (data['status'] as String? ?? 'pending') {
      case 'accepted':
        status = BookingStatus.accepted;
        break;
      case 'declined':
        status = BookingStatus.declined;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      default:
        status = BookingStatus.pending;
    }

    BookingServiceType serviceType;
    switch (data['serviceType'] as String? ?? 'walk') {
      case 'sitting':
        serviceType = BookingServiceType.sitting;
        break;
      default:
        serviceType = BookingServiceType.walk;
    }

    return BookingRequestModel(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      providerUid: data['providerUid'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerPhotoUrl: data['providerPhotoUrl'] as String?,
      serviceId: data['serviceId'] as String? ?? '',
      serviceType: serviceType,
      petName: data['petName'] as String? ?? '',
      petType: data['petType'] as String? ?? '',
      petImageUrl: data['petImageUrl'] as String?,
      requestedDate: (data['requestedDate'] as Timestamp?)?.toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      specialInstructions: data['specialInstructions'] as String?,
      status: status,
      providerNote: data['providerNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'providerUid': providerUid,
      'providerName': providerName,
      'providerPhotoUrl': providerPhotoUrl,
      'serviceId': serviceId,
      'serviceType': serviceType.name,
      'petName': petName,
      'petType': petType,
      'petImageUrl': petImageUrl,
      'requestedDate': requestedDate != null ? Timestamp.fromDate(requestedDate!) : null,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'specialInstructions': specialInstructions,
      'status': status.name,
      'providerNote': providerNote,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
