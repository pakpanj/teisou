import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a gallery photo, has [ImagePicker] downscale it to fit within
/// 512x512 client-side (avoiding a separate native compression plugin),
/// and uploads it to Storage at `avatars/{uid}.jpg`.
class AvatarUploadService {
  final ImagePicker _picker;
  final FirebaseStorage _storage;

  AvatarUploadService({ImagePicker? picker, FirebaseStorage? storage})
      : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance;

  /// Returns the uploaded avatar's download URL, or null if the user
  /// cancelled the gallery picker.
  Future<String?> pickAndUpload(String uid) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
