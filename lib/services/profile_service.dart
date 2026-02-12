
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

  //Se actualizan los datos de la tabla (Excepto user_id y email)
  
}