import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/features/service_request/domain/entities/application.dart';

class ApplicationModel extends Application {
  const ApplicationModel({
    required super.id,
    required super.requestId,
    required super.providerUid,
    required super.providerName,
    super.providerPhotoUrl,
    super.message,
    super.proposedPrice,
    super.status,
    super.createdAt,
  });

  factory ApplicationModel.fromFirestore(
      DocumentSnapshot doc, String requestId) {
    final d = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      requestId: requestId,
      providerUid: d['providerUid'] as String,
      providerName: d['providerName'] as String? ?? '',
      providerPhotoUrl: d['providerPhotoUrl'] as String?,
      message: d['message'] as String?,
      proposedPrice: (d['proposedPrice'] as num?)?.toDouble(),
      status: _status(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'providerUid': providerUid,
        'providerName': providerName,
        'providerPhotoUrl': providerPhotoUrl,
        'message': message,
        'proposedPrice': proposedPrice,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static ApplicationStatus _status(String? v) => switch (v) {
        'accepted' => ApplicationStatus.accepted,
        'rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.pending,
      };
}
