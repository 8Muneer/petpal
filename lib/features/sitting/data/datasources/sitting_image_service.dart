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

  Future<List<String>> uploadPetImages(
      String requestId, List<XFile> files) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      // Flat path — avoids nested-path Firebase Storage rule mismatch
      final ref =
          _storage.ref().child('sitting_pet_images/${requestId}_img$i');
      await ref.putFile(
        File(files[i].path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<List<XFile>> pickImages() async {
    return _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
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
