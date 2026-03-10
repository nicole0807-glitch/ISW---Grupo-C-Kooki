import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

enum AppRole {
  guest,
  user,
  nutritionist,
  support,
  communityContributor,
  admin,
  unknown,
}

enum AppPermission {
  viewRecipes,
  accessAssistant,
  accessPremiumPlan,
  publishCommunityRecipe,
  validateRecipes,
  openAdminDashboard,
  manageUsersRoles,
  moderateCommunityRecipes,
}

class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Ahora manejamos el ID del rol directamente
  int _roleId = 0; 
  String? _roleName;
  bool isLoading = true;

  int get roleId => _roleId;
  String? get roleName => _roleName;

  AppRole get appRole {
    final normalized = _roleName?.toLowerCase().trim();
    if (normalized == 'admin') return AppRole.admin;
    if (normalized == 'nutritionist' || normalized == 'nutricionista') {
      return AppRole.nutritionist;
    }
    if (normalized == 'support') return AppRole.support;
    if (normalized == 'community_contributor' ||
        normalized == 'community contributor') {
      return AppRole.communityContributor;
    }
    if (normalized == 'user') return AppRole.user;

    if (_roleId == 0) return AppRole.guest;
    if (_roleId == 1) return AppRole.user;
    if (_roleId == 2) return AppRole.nutritionist;
    if (_roleId == 3) return AppRole.admin;
    if (_roleId == 4) return AppRole.support;
    if (_roleId == 5) return AppRole.communityContributor;
    return AppRole.unknown;
  }

  // Getters semánticos para facilitar la lectura en la UI
  bool get isNutricionista => _roleId == 2;
  bool get isAdmin => _roleId == 3; // Ajusta este número según tu tabla 'Role'
  bool get canValidate => _roleId == 2 || _roleId == 3;
  bool get canManageUsers => hasPermission(AppPermission.manageUsersRoles);

  bool hasPermission(AppPermission permission) {
    switch (appRole) {
      case AppRole.admin:
        return true;
      case AppRole.nutritionist:
        return {
          AppPermission.viewRecipes,
          AppPermission.accessAssistant,
          AppPermission.accessPremiumPlan,
          AppPermission.publishCommunityRecipe,
          AppPermission.validateRecipes,
          AppPermission.moderateCommunityRecipes,
        }.contains(permission);
      case AppRole.support:
        return {
          AppPermission.viewRecipes,
          AppPermission.accessAssistant,
          AppPermission.accessPremiumPlan,
          AppPermission.publishCommunityRecipe,
          AppPermission.moderateCommunityRecipes,
        }.contains(permission);
      case AppRole.communityContributor:
        return {
          AppPermission.viewRecipes,
          AppPermission.accessAssistant,
          AppPermission.accessPremiumPlan,
          AppPermission.publishCommunityRecipe,
        }.contains(permission);
      case AppRole.user:
        return {
          AppPermission.viewRecipes,
          AppPermission.accessAssistant,
          AppPermission.accessPremiumPlan,
          AppPermission.publishCommunityRecipe,
        }.contains(permission);
      case AppRole.guest:
      case AppRole.unknown:
        return permission == AppPermission.viewRecipes;
    }
  }

  HomeController() {
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final user = _supabaseService.currentUser;
    
    if (user == null) {
      _roleId = 0;
      _roleName = null;
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
          .select('role_id, Role(name)')
          .eq('user_id', user.id)
          .single();

      _roleId = response['role_id'] as int;
      final rawRole = response['Role'];
      if (rawRole is Map<String, dynamic>) {
        _roleName = rawRole['name']?.toString();
      } else if (rawRole is List && rawRole.isNotEmpty) {
        _roleName = rawRole.first['name']?.toString();
      } else {
        _roleName = null;
      }
      print("🔄 Rol cargado: $_roleId");
    } catch (e) {
      print("❌ Error cargando rol: $e");
      _roleId = 1; // Por defecto rol básico si falla
      _roleName = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _roleId = 0;
    _roleName = null;
    isLoading = false;
    notifyListeners();
  }
}
