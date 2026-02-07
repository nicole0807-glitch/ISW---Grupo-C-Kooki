import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception("Error en la comunicación con el servidor: $e");
    }
  }

  Session? get currentSession => _supabase.auth.currentSession;
}