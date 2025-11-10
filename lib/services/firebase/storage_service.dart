import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference storageRef = _storage.ref().child('profile_photos/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference storageRef = _storage.ref().child('profile_photos/$fileName');
      await storageRef.delete();
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // Upload note attachment (for future use)
  Future<String> uploadNoteAttachment({
    required String noteId,
    required File file,
  }) async {
    try {
      final String fileName = 'note_${noteId}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = _storage.ref().child('note_attachments/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
