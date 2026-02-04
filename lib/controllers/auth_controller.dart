import 'dart:io';
import '../services/supabase_service.dart';

class AuthController {
  final SupabaseService _service = SupabaseService();

  bool hasSession() {
    return _service.currentSession != null;
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    File? imageFile,
  }) async {
    try {
      final authResponse = await _service.signUp(email, password);
      final userId = authResponse.user?.id;

      if (userId != null) {
        String avatarUrl = ""; 
        
        if (imageFile != null) {
          avatarUrl = await _service.uploadAvatar(userId, imageFile);
        }

        await _service.upsertProfile({
          'user_id': userId,
          'username': username,
          'email': email,
          'role_id': 1, 
          'status': true,
          'avatar_url': avatarUrl, 
        });
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}