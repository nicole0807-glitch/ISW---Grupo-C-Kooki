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

  /// Login con username y password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      print('🔵 Intentando login...');
      print('👤 Username: $username');
      
      // PASO 1: Buscar el user_id y email desde User_profile usando el username
      final profileResponse = await _service.supabase
          .from('Profile')
          .select('user_id, email')
          .eq('username', username)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Usuario no encontrado');
      }

      final email = profileResponse['email'] as String;
      final userId = profileResponse['user_id'] as String;

      print('✅ Usuario encontrado');
      print('📧 Email: $email');
      print('🆔 User ID: $userId');

      // PASO 2: Autenticar con Supabase usando email y password
      final authResponse = await _service.supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Error en autenticación');
      }

      print('✅ Autenticación exitosa');
      print('🔐 Session: ${authResponse.session != null}');

      return true;
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
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
      print('🔵 Registrando usuario...');
      
      // PASO 1: Registrar en Supabase Auth
      final authResponse = await _service.signUp(email, password);
      final user_id = authResponse.user?.id;

      if (user_id == null) {
        throw Exception('No se pudo crear el usuario');
      }

      print('✅ Usuario creado en Auth');
      print('🆔 User ID: $user_id');

      // PASO 2: Subir avatar si existe
      String avatarUrl = ""; 
      if (imageFile != null) {
        print('📸 Subiendo avatar...');
        avatarUrl = await _service.uploadAvatar(user_id, imageFile);
        print('✅ Avatar subido: $avatarUrl');
      }

      // PASO 3: Crear perfil en User_profile
      print('📝 Creando perfil...');
      await _service.supabase.from('Profile').insert({
        'user_id': user_id,
        'username': username,
        'email': email,
        'role_id': 1, 
        'status': true,
        'avatar_url': avatarUrl.isEmpty ? null : avatarUrl, 
      });

      print('✅ Registro completado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error en registro: $e');
      rethrow;
    }
  }
}