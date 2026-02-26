import 'package:flutter/material.dart';

import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';

enum RecipeSearchSort { recent, alphabetical }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RecipeService _recipeService = RecipeService();
  late final Future<List<Recipe>> _recipesFuture;

  String _query = '';
  RecipeSearchSort _selectedSort = RecipeSearchSort.recent;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _recipeService.fetchRecipes();
  }

  List<Recipe> _filterAndSort(List<Recipe> recipes) {
    final filtered = recipes.where((recipe) {
      return _query.isEmpty ||
          recipe.title.toLowerCase().contains(_query) ||
          recipe.ingredients.any((i) => i.name.toLowerCase().contains(_query));
    }).toList();

    if (_selectedSort == RecipeSearchSort.alphabetical) {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o ingrediente',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<RecipeSearchSort>(
              value: _selectedSort,
              items: const [
                DropdownMenuItem(
                  value: RecipeSearchSort.recent,
                  child: Text('Más recientes'),
                ),
                DropdownMenuItem(
                  value: RecipeSearchSort.alphabetical,
                  child: Text('A-Z'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSort = value);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar recetas: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No se encontraron recetas.'));
                }

                final filteredRecipes = _filterAndSort(snapshot.data!);

                if (filteredRecipes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin resultados para tu búsqueda.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredRecipes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(recipe.title),
                      subtitle: Text(
                        recipe.ingredients.map((i) => i.name).take(3).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text('⭐ ${recipe.rating.toStringAsFixed(1)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
