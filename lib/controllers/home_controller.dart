import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool isAdmin = false;
  bool isLoading = true;

  HomeController() {
    checkAdminStatus();
  }

  Future<void> checkAdminStatus() async {
    isLoading = true;
    notifyListeners();

    isAdmin = await _supabaseService.isUserAdmin();
    
    isLoading = false;
    notifyListeners();
  }
}