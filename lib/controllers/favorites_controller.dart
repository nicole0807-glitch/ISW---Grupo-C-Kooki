import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends ChangeNotifier {
  static const _prefsKey = 'favorite_recipe_ids';
  final Set<int> _favoriteIds = <int>{};
  bool _isLoaded = false;

  Set<int> get favoriteIds => _favoriteIds;
  bool get isLoaded => _isLoaded;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIds = prefs.getStringList(_prefsKey) ?? <String>[];

    _favoriteIds
      ..clear()
      ..addAll(rawIds.map(int.tryParse).whereType<int>());

    _isLoaded = true;
    notifyListeners();
  }

  bool isFavorite(int recipeId) => _favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(int recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      _favoriteIds.remove(recipeId);
    } else {
      _favoriteIds.add(recipeId);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final ordered = _favoriteIds.toList()..sort();
    await prefs.setStringList(
      _prefsKey,
      ordered.map((id) => id.toString()).toList(),
    );
  }
}
