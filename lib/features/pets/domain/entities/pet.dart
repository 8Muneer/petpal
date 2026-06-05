import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String ownerUid;
  final String name;
  final String type;       // 'כלב' | 'חתול' | 'ציפור' | 'ארנב' | 'אחר'
  final String breed;
  final String gender;     // 'זכר' | 'נקבה'
  final String? imageUrl;
  final String? notes;
  final int? ageYears;
  final double? weightKg;
  final String? color;
  final bool isVaccinated;
  final String? microchipId;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.type,
    required this.breed,
    required this.gender,
    this.imageUrl,
    this.notes,
    this.ageYears,
    this.weightKg,
    this.color,
    this.isVaccinated = false,
    this.microchipId,
    required this.createdAt,
  });

  factory Pet.fromMap(String id, Map<String, dynamic> map) => Pet(
        id: id,
        ownerUid: map['ownerUid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        type: map['type'] as String? ?? 'אחר',
        breed: map['breed'] as String? ?? '',
        gender: map['gender'] as String? ?? 'זכר',
        imageUrl: map['imageUrl'] as String?,
        notes: map['notes'] as String?,
        ageYears: (map['ageYears'] as num?)?.toInt(),
        weightKg: (map['weightKg'] as num?)?.toDouble(),
        color: map['color'] as String?,
        isVaccinated: map['isVaccinated'] as bool? ?? false,
        microchipId: map['microchipId'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'type': type,
        'breed': breed,
        'gender': gender,
        'imageUrl': imageUrl,
        'notes': notes,
        'ageYears': ageYears,
        'weightKg': weightKg,
        'color': color,
        'isVaccinated': isVaccinated,
        'microchipId': microchipId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
