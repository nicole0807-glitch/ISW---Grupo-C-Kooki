import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Ahora manejamos el ID del rol directamente
  int _roleId = 0; 
  bool isLoading = true;

  int get roleId => _roleId;
  
  // Getters semánticos para facilitar la lectura en la UI
  bool get isNutricionista => _roleId == 2;
  bool get isAdmin => _roleId == 3; // Ajusta este número según tu tabla 'Role'
  bool get canValidate => _roleId == 2 || _roleId == 3;

  HomeController() {
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final user = _supabaseService.currentUser;
    
    if (user == null) {
      _roleId = 0;
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Consultamos el role_id directamente desde el perfil del usuario
      final response = await _supabaseService.supabase
          .from('Profile')
          .select('role_id')
          .eq('user_id', user.id)
          .single();

      _roleId = response['role_id'] as int;
      print("🔄 Rol cargado: $_roleId");
    } catch (e) {
      print("❌ Error cargando rol: $e");
      _roleId = 1; // Por defecto rol básico si falla
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _roleId = 0;
    isLoading = false;
    notifyListeners();
  }
}