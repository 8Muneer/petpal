import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';

final userPetsProvider = StreamProvider.autoDispose<List<Pet>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('pets')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList());
});

class PetsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addPet({
    required String name,
    required String type,
    required String breed,
    required String gender,
    String? notes,
    int? ageYears,
    double? weightKg,
    String? color,
    bool isVaccinated = false,
    String? microchipId,
    File? imageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    String? imageUrl;
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('pets/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .add({
      'ownerUid': user.uid,
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender,
      'notes': notes,
      'ageYears': ageYears,
      'weightKg': weightKg,
      'color': color,
      'isVaccinated': isVaccinated,
      'microchipId': microchipId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editPet({
    required String petId,
    required String name,
    required String type,
    required String breed,
    required String gender,
    String? notes,
    int? ageYears,
    double? weightKg,
    String? color,
    bool isVaccinated = false,
    String? microchipId,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    String? imageUrl = existingImageUrl;
    if (imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('pets/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .update({
      'name': name,
      'type': type,
      'breed': breed,
      'gender': gender,
      'notes': notes,
      'ageYears': ageYears,
      'weightKg': weightKg,
      'color': color,
      'isVaccinated': isVaccinated,
      'microchipId': microchipId,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deletePet(String petId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .delete();
  }
}

final petsNotifierProvider =
    AsyncNotifierProvider<PetsNotifier, void>(PetsNotifier.new);
