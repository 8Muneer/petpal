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
    super.preferredTime,
    super.dropOffTime,
    super.pickupTime,
    super.location,
    super.contactPhone,
    super.feedingInfo,
    super.medicationInfo,
    super.vetContact,
    super.priceText,
    super.priceType,
    super.hours,
    super.specialInstructions,
    super.status,
    super.providerNote,
    super.sittingType,
    super.createdAt,
  });

  factory BookingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    BookingStatus status;
    switch (data['status'] as String? ?? 'pending') {
      case 'accepted':
        status = BookingStatus.accepted;
        break;
      case 'awaitingConfirmation':
        status = BookingStatus.awaitingConfirmation;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'declined':
        status = BookingStatus.declined;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      case 'expired':
        status = BookingStatus.expired;
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
      preferredTime: data['preferredTime'] as String?,
      dropOffTime: data['dropOffTime'] as String?,
      pickupTime: data['pickupTime'] as String?,
      location: data['location'] as String?,
      contactPhone: data['contactPhone'] as String?,
      feedingInfo: data['feedingInfo'] as String?,
      medicationInfo: data['medicationInfo'] as String?,
      vetContact: data['vetContact'] as String?,
      priceText: data['priceText'] as String?,
      priceType: data['priceType'] as String?,
      hours: (data['hours'] as num?)?.toInt(),
      specialInstructions: data['specialInstructions'] as String?,
      status: status,
      providerNote: data['providerNote'] as String?,
      sittingType: data['sittingType'] as String?,
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
      'preferredTime': preferredTime,
      'dropOffTime': dropOffTime,
      'pickupTime': pickupTime,
      'location': location,
      'contactPhone': contactPhone,
      'feedingInfo': feedingInfo,
      'medicationInfo': medicationInfo,
      'vetContact': vetContact,
      'priceText': priceText,
      'priceType': priceType,
      'hours': hours,
      'specialInstructions': specialInstructions,
      'status': status.name,
      'providerNote': providerNote,
      'sittingType': sittingType,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
