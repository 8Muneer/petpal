import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminImageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  AdminImageService({
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

  /// Gallery-only — `pickMultiImage` has no camera-source variant.
  Future<List<XFile>> pickImages() async {
    return _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  Future<String> uploadPOIImage(String poiId, XFile file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('poi_images/$poiId/$fileName');
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  /// Uploads each file in turn (rather than in parallel) so a mid-batch
  /// failure leaves the caller with a clear count of what already succeeded,
  /// instead of a partially-resolved Future.wait with ambiguous state.
  Future<List<String>> uploadPOIImages(String poiId, List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadPOIImage(poiId, file));
    }
    return urls;
  }

  /// Deletes a previously uploaded POI image given its download URL.
  /// Swallows "object not found" so removing an already-deleted or
  /// externally-managed URL from a POI's list never blocks the save.
  Future<void> deletePOIImage(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

final adminImageServiceProvider = Provider<AdminImageService>((ref) {
  return AdminImageService(storage: FirebaseStorage.instance);
});
