import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FeedImageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  FeedImageService({
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

  Future<String> uploadPostImage(String postId, XFile file) async {
    final ref = _storage.ref().child('post_images/$postId');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<List<String>> uploadPostImages(
      String postId, List<XFile> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = _storage.ref().child('post_images/${postId}_$i');
      await ref.putFile(
        File(files[i].path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> deletePostImage(String postId) async {
    final ref = _storage.ref().child('post_images/$postId');
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
