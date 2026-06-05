import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequest {
  final String id;
  final String userId;
  final String status; // pending, approved, rejected
  final List<String> documents;
  final String? notes;
  final String? reviewedBy;
  final DateTime requestedAt;
  final DateTime? resolvedAt;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.documents = const [],
    this.notes,
    this.reviewedBy,
    required this.requestedAt,
    this.resolvedAt,
  });

  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      documents: List<String>.from(data['documents'] ?? []),
      notes: data['notes'],
      reviewedBy: data['reviewedBy'],
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'documents': documents,
      'notes': notes,
      'reviewedBy': reviewedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    };
  }
}
