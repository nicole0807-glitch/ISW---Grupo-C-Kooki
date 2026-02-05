import 'dart:io';
import '../services/supabase_service.dart';

class AuthController {
  final SupabaseService _service = SupabaseService();

  bool hasSession() {
    return _service.currentSession != null;
  }

   Future<bool> logout() async {
    try {
      await _service.signOut();
      return true; 
    } catch (e) {
      print(e);
      return false; 
    }
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
      final user_id = authResponse.user?.id;

      if (user_id != null) {
        String avatarUrl = ""; 
        
        if (imageFile != null) {
          avatarUrl = await _service.uploadAvatar(user_id, imageFile);
        }

        await _service.upsertProfile({
          'user_id': user_id,
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