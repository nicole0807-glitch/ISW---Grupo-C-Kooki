import 'dart:typed_data';
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
  /// Retorna un mapa con {success: bool, roleId: int?, roleName: String?}
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      print('🔵 Intentando login...');
      print('👤 Username: $username');

      // PASO 1: JOIN entre Profile y Role para obtener el nombre
      final profileResponse = await _service.supabase
          .from('Profile')
          .select('''
            user_id, 
            email, 
            role_id, 
            Role ( name )
          ''')
          .eq('username', username)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (profileResponse == null) {
        throw Exception('Usuario no encontrado');
      }

      final email = profileResponse['email'] as String;
      final roleId = profileResponse['role_id'] as int;

      // EXTRACCIÓN ROBUSTA DEL NOMBRE DEL ROL
      String roleName = 'Sin rol';
      final rawRoleData = profileResponse['Role'];

      if (rawRoleData != null) {
        if (rawRoleData is List && rawRoleData.isNotEmpty) {
          roleName = rawRoleData[0]['name']?.toString() ?? 'Sin nombre';
        } else if (rawRoleData is Map) {
          roleName = rawRoleData['name']?.toString() ?? 'Sin nombre';
        }
      }

      print('✅ Usuario encontrado');
      print('📧 Email: $email');
      print('🎭 Nombre de Rol: $roleName');

      // PASO 2: Autenticar con Supabase usando email y password
      final authResponse = await _service.supabase.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      if (authResponse.user == null) {
        throw Exception('Error en autenticación');
      }

      print('✅ Autenticación exitosa');
      return {
        'success': true,
        'roleId': roleId,
        'roleName': roleName,
      };
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
    Uint8List? imageBytes,
  }) async {
    try {
      final authResponse = await _service.signUp(email, password);
      final userId = authResponse.user?.id;

      if (userId == null) throw Exception('No se pudo crear el usuario');

      // Inicializamos como null explícitamente
      String? avatarUrl;

      if (imageBytes != null) {
        avatarUrl = await _service.uploadAvatar(userId, imageBytes);
      }

      await _service.supabase.from('Profile').insert({
        'user_id': userId,
        'username': username,
        'email': email,
        'role_id': 1,
        'status': true,
        'avatar_url': avatarUrl, // Enviará null si no hay imagen
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
