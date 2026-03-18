import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SittingImageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  SittingImageService({
    required FirebaseStorage storage,
    ImagePicker? picker,
  })  : _storage = storage,
        _picker = picker ?? ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  Future<String> uploadPetImage(String requestId, XFile file) async {
    final ref = _storage.ref().child('sitting_pet_images/$requestId');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> deletePetImage(String requestId) async {
    final ref = _storage.ref().child('sitting_pet_images/$requestId');
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
