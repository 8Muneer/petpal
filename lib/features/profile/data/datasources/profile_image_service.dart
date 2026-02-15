import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  ProfileImageService({
    required FirebaseStorage storage,
    ImagePicker? picker,
  })  : _storage = storage,
        _picker = picker ?? ImagePicker();

  /// Pick image from gallery or camera, returns the [XFile] or null if cancelled.
  Future<XFile?> pickImage(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
  }

  /// Upload the picked image to Firebase Storage and return the download URL.
  Future<String> uploadProfileImage(String uid, XFile file) async {
    final ref = _storage.ref().child('profile_images/$uid');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Delete the profile image from Firebase Storage.
  Future<void> deleteProfileImage(String uid) async {
    final ref = _storage.ref().child('profile_images/$uid');
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore "object-not-found" — image may not exist
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
