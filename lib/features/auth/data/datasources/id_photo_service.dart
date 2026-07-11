import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class IdPhotoService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  IdPhotoService({
    required FirebaseStorage storage,
    ImagePicker? picker,
  })  : _storage = storage,
        _picker = picker ?? ImagePicker();

  /// Pick the ID photo from gallery or camera, returns the [XFile] or null if cancelled.
  Future<XFile?> pickImage(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  }

  /// Upload the picked ID photo to Firebase Storage and return the download URL.
  Future<String> uploadIdPhoto(String uid, XFile file) async {
    final ref = _storage.ref().child('id_photos/$uid');
    final bytes = await file.readAsBytes();
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
