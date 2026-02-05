import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
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

  Future<int> _getOrCreateIngredientId(String name) async {
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

      final int ingredientId = await _getOrCreateIngredientId(allergy);

      await _client.from('User_allergies').upsert({
        'user_id': userId,
        'ingredient_id': ingredientId,
      });
    }
  }
}