import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
//Se importa supabase para constuir una instancia privada para manejar el perfil. Esto ya incluye auth.

class ProfileService {
  //Instancia de supabase
  final _supabase = Supabase.instance.client;

  //Obtener el usuario actual (Puede no haber usuario iniciado)
  User? get currentUser => _supabase.auth.currentUser;

  //Bool si el usuario está o no iniciado
  bool get isUserLoggedIn => currentUser != null;

  //Se traen los datos del perfil
  Future<Map<String, dynamic>?> getProfileData() async {
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

  Future<List<Map<String, dynamic>>> getAvailableRoles() async {
    try {
      final res = await _supabase
          .from('Role')
          .select('role_id, name')
          .order('role_id', ascending: true);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> updateUserRole({
    required String userId,
    required int roleId,
  }) async {
    try {
      await _supabase
          .from('Profile')
          .update({'role_id': roleId})
          .eq('user_id', userId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  //Se actualiza el Mail de autenticación
  Future<String?> updateAuthMail(String? newEmail) async {
    try {
      // Primero se verifica que haya un usuario logueado
      final userID = currentUser?.id;
      if (userID == null) return "Logged out";

      //Se actualiza el email en auth
      final attribute = UserAttributes(email: newEmail);
      await _supabase.auth.updateUser(attribute);

      //Se actualiza el email en la tabla de perfil
      await _supabase
          .from('Profile')
          .update({'email': newEmail})
          .eq('user_id', userID);

      //Refrescar sesión
      await _supabase.auth.refreshSession();

      return null; //Nada falla
    } catch (e) {
      return e.toString(); //Error
    }
  }

  //Se actualiza la contraseña de autenticación
  Future<String?> updateAuthPass(String? newPassword) async {
    try {
      //Se actualiza el email en auth
      final attribute = UserAttributes(password: newPassword);
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
      await _supabase
          .from('Profile')
          .update({'username': newUsername})
          .eq('user_id', userID);

      //Refrescar sesión
      await _supabase.auth.refreshSession();

      return null; //Todo sale bien
    } catch (e) {
      return e.toString();
    }
  }

  //Verificación de contraseña actual
  Future<bool> validateCurrentPassword(String password) async {
    final email = currentUser?.email;
    if (email == null) return false;

    try {
      //Intento de inicio de sesión
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true; //Inicio correctamente
    } catch (e) {
      return false; //Falló. Contraseña incorrecta.
    }
  }

  //  ---- DATOS DE PREFERENCIAS DE DIETA ---

  //Importación del catálogo de tags
  Future<List<Map<String, dynamic>>> getDietTags() async {
    return await _supabase
        .from('Tag')
        .select('tag_id, name')
        .eq('type', 'Diet');
  }

  //Importación de los tags del usuario
  Future<List<int>> getUserDietTags() async {
    final userID = currentUser?.id ?? "";
    if (userID.isNotEmpty) {
      final res = await _supabase
          .from('User_preferences')
          .select('tag_id')
          .eq('user_id', userID);

      return (res as List).map((item) => item['tag_id'] as int).toList();
    }

    return [1];
  }

  //Obtener las alergias del usuario
  Future<List<Map<String, dynamic>>> getUserAllergies() async {
    final userID = currentUser?.id ?? "";

    if (userID.isNotEmpty) {
      return await _supabase
          .from('User_allergies')
          .select('ingredient_id, Ingredient(ingredient_id, name)')
          .eq('user_id', userID);
    }
    return [
      {'ingredient_id': 1, 'name': 'nil'},
    ];
  }

  //Buscador de ingredients
  Future<List<Map<String, dynamic>>> searchIngredients(String query) async {
    if (query.isEmpty) return [];
    return await _supabase
        .from('Ingredient')
        .select('ingredient_id, name')
        .ilike('name', '%$query%')
        .limit(5);
  }

  //Guardar actualizaciones a User_allergies y User_preferences
  Future<void> saveDietaryProfile(
    List<int> newTagIDs,
    List<int> ingredientIDs,
  ) async {
    final userID = currentUser?.id ?? "";
    final oldDietIDs = await getUserDietTags();

    if (userID.isNotEmpty) {
      if (oldDietIDs.isNotEmpty) {
        await _supabase
            .from('User_preferences')
            .delete()
            .eq('user_id', userID)
            .inFilter('tag_id', oldDietIDs);
      }

      if (newTagIDs.isNotEmpty) {
        await _supabase
            .from('User_preferences')
            .insert(
              newTagIDs.map((id) => {'user_id': userID, 'tag_id': id}).toList(),
            );
      }

      await _supabase.from('User_allergies').delete().eq('user_id', userID);
      if (ingredientIDs.isNotEmpty) {
        await _supabase
            .from('User_allergies')
            .insert(
              ingredientIDs
                  .map((id) => {'user_id': userID, 'ingredient_id': id})
                  .toList(),
            );
      }
    }
  }

  // --- MI PERFIL: ACTUALIZAR URL DE FOTO ---
  Future<String?> updateAvatarUrl(String url) async {
    try {
      final userID = currentUser?.id;
      if (userID == null) return "No hay sesión activa";

      await _supabase
          .from('Profile')
          .update({'avatar_url': url}).eq('user_id', userID);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}
