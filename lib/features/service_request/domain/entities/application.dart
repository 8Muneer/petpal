import 'package:equatable/equatable.dart';

enum ApplicationStatus { pending, accepted, rejected }

class Application extends Equatable {
  final String id;
  final String requestId;

  // Provider
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;

  // Offer details
  final String? message;
  final double? proposedPrice;

  final ApplicationStatus status;
  final DateTime? createdAt;

  const Application({
    required this.id,
    required this.requestId,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    this.message,
    this.proposedPrice,
    this.status = ApplicationStatus.pending,
    this.createdAt,
  });

  bool get isPending => status == ApplicationStatus.pending;
  bool get isAccepted => status == ApplicationStatus.accepted;

  @override
  List<Object?> get props => [
        id, requestId, providerUid, providerName, providerPhotoUrl,
        message, proposedPrice, status, createdAt,
      ];
}
