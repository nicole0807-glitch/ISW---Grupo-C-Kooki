import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool isAdmin = false;
  bool isLoading = true;

  HomeController() {
    checkAdminStatus();
  }

  // Método para forzar la actualización (llámalo tras el login)
  Future<void> checkAdminStatus() async {
    final user = _supabaseService.currentUser;
    
    if (user == null) {
      isAdmin = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    isAdmin = await _supabaseService.isUserAdmin();
    
    isLoading = false;
    notifyListeners();
    print("🔄 Estado de Admin actualizado: $isAdmin");
  }

  // Método para limpiar al cerrar sesión
  void clearStatus() {
    isAdmin = false;
    isLoading = false;
    notifyListeners();
  }
}