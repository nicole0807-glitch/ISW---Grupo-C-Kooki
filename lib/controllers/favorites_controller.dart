import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/favorite_service.dart';

class FavoritesController extends ChangeNotifier {
  static const _prefsKey = 'favorite_recipe_ids';
  static const _communityPrefsKey = 'favorite_community_ids';
  final Set<String> _favoriteIds = {};
  final Set<String> _communityIds = {};
  bool _isLoaded = false;
  final FavoriteService _favoriteService = FavoriteService();
  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoaded => _isLoaded;

  FavoritesController() {
    // Escuchar cambios de autenticación para sincronizar cuando el usuario inicia sesión
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // El usuario acaba de iniciar sesión — recargar favoritos desde la nube
        loadFavorites();
      } else if (event == AuthChangeEvent.signedOut) {
        // Limpiar favoritos de la nube al cerrar sesión (quedar solo con los locales vacíos)
        _favoriteIds.clear();
        _isLoaded = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    // 1. Cargar desde Local (SharedPreferences) para rapidez
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_prefsKey) ?? <String>[];
    final rawCommIds = prefs.getStringList(_communityPrefsKey) ?? <String>[];

    _favoriteIds.clear();
    _favoriteIds.addAll(rawIds);

    _communityIds.clear();
    _communityIds.addAll(rawCommIds);

    // 2. Si el usuario está Logueado, sincronizar con Supabase (la fuente de verdad)
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final remoteItems = await _favoriteService.fetchFavoriteIds(user.id);
        _favoriteIds.clear();
        _communityIds.clear();

        for (var item in remoteItems) {
          final String idStr = item.toString();
          _favoriteIds.add(idStr);
          // Si el ID no es numérico, asumimos que es de comunidad (UUID)
          if (int.tryParse(idStr) == null) {
            _communityIds.add(idStr);
          }
        }
        await _persist();
      } catch (e) {
        debugPrint('Error syncing favorites from Supabase: $e');
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(dynamic recipeId) =>
      _favoriteIds.contains(recipeId.toString());
  bool isCommunity(dynamic recipeId) =>
      _communityIds.contains(recipeId.toString());

  Future<void> toggleFavorite(dynamic recipeId) async {
    final user = _supabase.auth.currentUser;
    final String idStr = recipeId.toString();

    if (_favoriteIds.contains(idStr)) {
      _favoriteIds.remove(idStr);
      _communityIds.remove(idStr);
      if (user != null) {
        try {
          await _favoriteService.removeFavorite(user.id, idStr);
        } catch (e) {
          _favoriteIds.add(idStr);
          if (int.tryParse(idStr) == null) _communityIds.add(idStr);
          debugPrint('Error removing favorite: $e');
        }
      }
    } else {
      _favoriteIds.add(idStr);
      if (int.tryParse(idStr) == null) _communityIds.add(idStr);
      if (user != null) {
        try {
          await _favoriteService.addFavorite(user.id, idStr);
        } catch (e) {
          _favoriteIds.remove(idStr);
          _communityIds.remove(idStr);
          debugPrint('Error adding favorite: $e');
        }
      }
    }

    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favoriteIds.toList());
    await prefs.setStringList(_communityPrefsKey, _communityIds.toList());
  }
}
