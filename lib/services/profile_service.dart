
import 'package:supabase_flutter/supabase_flutter.dart';
//Se importa supabase para constuir una instancia privada para manejar el perfil. Esto ya incluye auth.

class ProfileService {
  //Instancia de supabase
  final _supabase = Supabase.instance.client;

  //Obtener el usuario actual (Puede no haber usuario iniciado)
  User? get currentUser => _supabase.auth.currentUser;

  //Bool si el usuario está o no iniciado
  bool get isUserLoggedIn => currentUser != null;

  //Se traen los datos del perfil
  Future <Map<String, dynamic>?> getProfileData() async {
    try {
      final userID = currentUser?.id;

      if (userID == null) {
        throw Exception("No hay usuario logueado");
      }

      //Como hay usuario logueado entonces se accede a la BD
      final data = await _supabase
      .from('Profile')
      .select()
      .eq('user_id', userID)
      .single();

      return data; //Devuelve un JSON con los datos pedidos.
    } catch (e) {
      print('Error en ProfileService: $e');
      return null;
    }
  }

  //Se actualiza el Mail de autenticación
  Future<String?> updateAuthMail(String? newEmail) async {
    try {
      // Primero se verifica que haya un usuario logueado
      final userID = currentUser?.id;
      if (userID == null) return "Logged out";

      //Se actualiza el email en auth
      final attribute = UserAttributes (email: newEmail);
      await _supabase.auth.updateUser(attribute);

      //Se actualiza el email en la tabla de perfil
      await _supabase.from('Profile').update({
        'email': newEmail
    }).eq('user_id', userID);

      return null; //Nada falla
    } catch (e) {
      return e.toString(); //Error
    }
  }
  
  //Se actualiza la contraseña de autenticación
  Future<String?> updateAuthPass(String? newPassword) async {
    try {
      //Se actualiza el email en auth
      final attribute = UserAttributes (password: newPassword);
      await _supabase.auth.updateUser(attribute);
    
      return null; //Nada falla
    } catch (e) {
      return e.toString(); //Error
    }
  }

  //Se actualiza el username
  Future<String?> updateUsername(String? newUsername) async {
    try {
      final userID = currentUser?.id;
      if (userID == null) return "Logged out";

      //Se carga a la BD
      await _supabase.from('Profile').update({
        'username': newUsername
      }).eq('user_id', userID);

      return null; //Todo sale bien
    } catch (e) {
      return e.toString();
    }

    
  }

  //Verificación de contraseña actual
  Future <bool> validateCurrentPassword(String password) async {
    final email = currentUser?.email;
    if (email == null) return false;

    try {
      //Intento de inicio de sesión
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true; //Inicio correctamente
    } catch (e) {
      return false; //Falló. Contraseña incorrecta.
    }
  }

}