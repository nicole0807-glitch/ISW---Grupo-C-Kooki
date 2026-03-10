import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  SupabaseClient get supabase => _client;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<bool> isUserAdmin() async {
    final user = _client.auth.currentUser;
    
    // 1. Si no hay usuario, no es admin
    if (user == null) {
      print("🔍 [AdminCheck]: No hay usuario logueado.");
      return false;
    }

    try {
      // 2. Usamos !inner para asegurar que el Join se realice correctamente
      // Traemos el campo 'name' de la tabla 'Role'
      final response = await _client
          .from('Profile')
          .select('role_id, Role!inner(name)') 
          .eq('user_id', user.id)
          .maybeSingle();

      print("🔍 [AdminCheck] Respuesta BD: $response");

      if (response == null || response['Role'] == null) {
        print("🔍 [AdminCheck]: No se encontró el perfil o el objeto Role es nulo.");
        return false;
      }

      // 3. Extracción robusta del nombre del rol
      final roleData = response['Role'];
      String? roleName;
      

      if (roleData is Map) {
        roleName = roleData['name']?.toString();
      } else if (roleData is List && roleData.isNotEmpty) {
        roleName = roleData[0]['name']?.toString();
      }

      print("🔍 [AdminCheck] Rol detectado: $roleName");

      // 4. Comparación (asegúrate que en tu BD sea 'admin')
      return roleName?.toLowerCase().trim() == 'admin'; 
      
    } catch (e) {
      print("❌ [AdminCheck] Error fatal: $e");
      return false;
    }
  }
  

  Future<String> uploadAvatar(String userId, File imageFile) async {
    final fileName = '$userId/profile.png';
    await _client.storage.from('avatars').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception("Error en la comunicación con el servidor: $e");
    }
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    await _client.from('Profile').upsert(data);
  }

  Future<int> _getOrCreateTagId(String name) async {
    final existing = await _client
        .from('Tag')
        .select('tag_id')
        .eq('name', name)
        .maybeSingle();
    
    if (existing != null) {
      return existing['tag_id'] as int;
    }

    final created = await _client
        .from('Tag')
        .insert({'name': name})
        .select('tag_id')
        .single();
    
    return created['tag_id'] as int;
  }

  Future<int> _getOrCreateingredient_id(String name) async {
    final existing = await _client
        .from('Ingredient')
        .select('ingredient_id')
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      return existing['ingredient_id'] as int;
    }

    final created = await _client
        .from('Ingredient')
        .insert({'name': name})
        .select('ingredient_id')
        .single();

    return created['ingredient_id'] as int;
  }

  Future<void> saveUserPreferences(String userId, List<String> preferences) async {
    for (String pref in preferences) {
      if (pref.isEmpty || pref == "None") continue;
      
      final int tagId = await _getOrCreateTagId(pref);
      
      await _client.from('User_preferences').upsert({
        'user_id': userId,
        'tag_id': tagId,
      });
    }
  }

  Future<void> saveUserAllergies(String userId, List<String> allergies) async {
    for (String allergy in allergies) {
      if (allergy.isEmpty || allergy == "None") continue;

      final int ingredientId = await _getOrCreateingredient_id(allergy);

      await _client.from('User_allergies').upsert({
        'user_id': userId,
        'ingredient_id': ingredientId,
      });
    }
  }
}