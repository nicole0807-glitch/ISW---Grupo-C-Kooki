import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe_model.dart';
import '../models/user_recipe_model.dart';

class RecipeService {
  final _supabase = Supabase.instance.client;

  String _buildPostgrestError(PostgrestException e) {
    final parts = <String>[e.message];
    return parts.join(' | ');
  }

  // ==========================================
  // 1. RECETAS DE LA COMUNIDAD (user_recipes)
  // ==========================================

  Future<List<UserRecipe>> fetchCommunityRecipes() async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => UserRecipe.fromMap(data))
          .toList();
    } catch (e) {
      print('Error fetching community: $e');
      return [];
    }
  }

  Future<String?> uploadRecipeImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      await _supabase.storage
          .from('recipe_images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _supabase.storage.from('recipe_images').getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image: $e');
      if (e.toString().contains('Bucket not found')) {
        print(
          '❌ [ERROR]: El bucket "recipe_images" no existe en Supabase Storage.',
        );
      }
      return null;
    }
  }

  Future<void> saveRecipe(UserRecipe recipe) async {
    final recipeData = <String, dynamic>{
      'user_id': recipe.userId,
      'user_name': recipe.userName,
      'title': recipe.title,
      'image_url': recipe.imageUrl,
      'duration': recipe.duration,
      'cost': recipe.cost,
      'difficulty': recipe.difficulty,
      'ingredients': recipe.ingredients,
      'steps': recipe.steps,
      'nutrition': recipe.nutrition,
      'preference': '',
      'avg_rating': recipe.dbAvgRating ?? 0.0,
    };

    final payload = Map<String, dynamic>.from(recipeData);
    const missingColumnRegex =
        r'column "([^"]+)" of relation "user_recipes" does not exist';

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await _supabase.from('user_recipes').insert(payload);
        return;
      } on PostgrestException catch (e) {
        final message = e.message.toLowerCase();
        final match = RegExp(missingColumnRegex).firstMatch(message);
        final missingColumn = match?.group(1);

        if (missingColumn != null && payload.containsKey(missingColumn)) {
          payload.remove(missingColumn);
          continue;
        }

        final pgError = _buildPostgrestError(e);
        print('❌ Error saving recipe (postgrest): $pgError');
        print('Detaills: ${e.details} | Hint: ${e.hint}');
        throw Exception('No se pudo guardar la receta: $pgError');
      } catch (e) {
        print('❌ Error fatal saving recipe: $e');
        throw Exception('No se pudo guardar la receta: $e');
      }
    }

    throw Exception(
      'No se pudo guardar la receta: esquema incompatible de user_recipes',
    );
  }

  Future<void> addCommunityRating(String recipeId, int score) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('recipe_ratings').insert({
        'recipe_id': recipeId,
        'user_id': user?.id,
        'rating': score,
      });
    } catch (e) {
      print('Error al calificar: $e');
    }
  }

  Future<void> addCommunityComment(String recipeId, String text) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('recipe_comments').insert({
        'recipe_id': recipeId,
        'user_id': user?.id,
        'user_name': user?.userMetadata?['full_name'] ?? 'Anonimo',
        'comment': text,
      });
    } catch (e) {
      print('Error al comentar: $e');
    }
  }

  // ==========================================
  // 2. RECETAS DEL SISTEMA / ADMIN (Recipes)
  // ==========================================

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
        ),
        "Recipe_Validation" (
          reviewer_id,
          "Profile" ( username )
        )
      ''');

      if (onlyApproved) {
        query = query.eq('status', 'aprobado');
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      print('Error detallado fetch: $e');
      throw Exception('Error al cargar recetas: $e');
    }
  }

  Future<void> createRecipe(Recipe recipe) async {
    try {
      final recipeData = {
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'cooking_time': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'nutrition': recipe.nutrition,
        'status': 'pendiente',
        'is_validated': false,
      };

      final newRecipeRes = await _supabase
          .from('Recipes')
          .insert(recipeData)
          .select('id')
          .single();

      final int newRecipeId = newRecipeRes['id'];
      await _insertRelations(newRecipeId, recipe);
    } catch (e) {
      throw Exception('Error al crear receta: $e');
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _supabase
          .from('Recipes')
          .update({
            'title': recipe.title,
            'description': recipe.description,
            'image_url': recipe.imageUrl,
            'cooking_time': recipe.cookingTime,
            'difficulty': recipe.difficulty,
            'nutrition': recipe.nutrition,
            'status': 'pendiente',
          })
          .eq('id', recipe.id);

      await _supabase
          .from('Recipe_Ingredients')
          .delete()
          .eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Steps').delete().eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Tags').delete().eq('recipe_id', recipe.id);

      await _insertRelations(recipe.id, recipe);
    } catch (e) {
      throw Exception('Error al actualizar receta: $e');
    }
  }

  Future<void> deleteRecipe(int recipeId) async {
    try {
      await _supabase.from('Recipes').delete().eq('id', recipeId);
    } catch (e) {
      throw Exception('Error al eliminar receta: $e');
    }
  }

  Future<void> _insertRelations(int recipeId, Recipe recipe) async {
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

    if (recipe.tagIds.isNotEmpty) {
      final tagsData = recipe.tagIds
          .map((tagId) => {'recipe_id': recipeId, 'tag_id': tagId})
          .toList();
      await _supabase.from('Recipe_Tags').insert(tagsData);
    }

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
        final newIng = await _supabase
            .from('Ingredient')
            .insert({
              'name': ing.name,
              'exp_time': 7,
              'density_g/ml': 1,
              'average_weight': 100,
            })
            .select('ingredient_id')
            .single();
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
