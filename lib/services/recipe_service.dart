import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final _supabase = Supabase.instance.client;

  /// LEER RECETAS
  /// [onlyApproved] si es true (por defecto), solo trae recetas validadas para el Home.
  /// Si es false, trae todas (útil para el panel de Admin).
  Future<List<Recipe>> fetchRecipes({bool onlyApproved = true}) async {
    try {
      var query = _supabase.from('Recipes').select('''
        *,
        "Recipe_Ingredients" (
          amount,
          unit_abbreviation,
          "Ingredient" ( name )
        ),
        "Recipe_Steps" (
          step_order,
          instruction
        ),
        "Recipe_Tags" (
          tag_id
        )
      ''');

    
      if (onlyApproved) {
        query = query.eq('status', 'aprobado');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      print("Error detallado fetch: $e");
      throw Exception('Error al cargar recetas: $e');
    }
  }

  /// CREAR RECETA
  Future<void> createRecipe(Recipe recipe) async {
    try {
      // 1. Insertar la Receta base
      final recipeData = {
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'cooking_time': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'nutrition': recipe.nutrition,
        // CAMBIO: Al crearla, el estado inicial es 'pending' para que el nutricionista la vea
        'status': 'pendiente', 
        'is_validated': false, 
      };

      final newRecipeRes = await _supabase
          .from('Recipes')
          .insert(recipeData)
          .select('id')
          .single();
      
      final int newRecipeId = newRecipeRes['id'];

      // 2. Insertar relaciones
      await _insertRelations(newRecipeId, recipe);

    } catch (e) {
      print("Error creando receta: $e");
      throw Exception('Error al crear receta: $e');
    }
  }

  /// ACTUALIZAR RECETA
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _supabase.from('Recipes').update({
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'cooking_time': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'nutrition': recipe.nutrition,
        // Al editar, la receta vuelve a estado 'pending' para re-validación
        'status': 'pendiente',
        'is_validated': false,
      }).eq('id', recipe.id);

      await _supabase.from('Recipe_Ingredients').delete().eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Steps').delete().eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Tags').delete().eq('recipe_id', recipe.id);

      await _insertRelations(recipe.id, recipe);
    } catch (e) {
      throw Exception('Error al actualizar receta: $e');
    }
  }

  /// ELIMINAR RECETA
  Future<void> deleteRecipe(int recipeId) async {
    try {
      await _supabase.from('Recipes').delete().eq('id', recipeId);
    } catch (e) {
      throw Exception('Error al eliminar receta: $e');
    }
  }

  /// HELPERS
  Future<void> _insertRelations(int recipeId, Recipe recipe) async {
    // A. Insertar Pasos
    if (recipe.steps.isNotEmpty) {
      final stepsData = recipe.steps.asMap().entries.map((entry) {
        return {
          'recipe_id': recipeId,
          'step_order': entry.key + 1,
          'instruction': entry.value,
        };
      }).toList();
      await _supabase.from('Recipe_Steps').insert(stepsData);
    }

    // B. Insertar Tags
    if (recipe.tagIds.isNotEmpty) {
      final tagsData = recipe.tagIds.map((tagId) => {
        'recipe_id': recipeId,
        'tag_id': tagId,
      }).toList();
      await _supabase.from('Recipe_Tags').insert(tagsData);
    }

    // C. Insertar Ingredientes
    for (var ing in recipe.ingredients) {
      final existingIng = await _supabase
          .from('Ingredient')
          .select('ingredient_id')
          .ilike('name', ing.name)
          .maybeSingle();

      int ingredientId;
      if (existingIng != null) {
        ingredientId = existingIng['ingredient_id'];
      } else {
        final newIng = await _supabase.from('Ingredient').insert({
          'name': ing.name,
          'exp_time': 7, 
          'density_g/ml': 1,
          'average_weight': 100
        }).select('ingredient_id').single();
        ingredientId = newIng['ingredient_id'];
      }

      await _supabase.from('Recipe_Ingredients').insert({
        'recipe_id': recipeId,
        'ingredient_id': ingredientId,
        'amount': ing.amount,
        'unit_abbreviation': ing.unit,
      });
    }
  }
}