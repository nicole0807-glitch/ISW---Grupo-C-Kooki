import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final _supabase = Supabase.instance.client;

  // --- LEER (Ya lo tenías) ---
  Future<List<Recipe>> fetchRecipes() async {
    try {
      final response = await _supabase.from('Recipes').select('''
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
      ''').order('created_at', ascending: false); // Ordenar por fecha

      // Nota: Eliminé .eq('is_validated', true) porque como ADMIN quieres ver todas,
      // incluso las no validadas para poder editarlas.

      return (response as List).map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      print("Error detallado fetch: $e");
      throw Exception('Error al cargar recetas: $e');
    }
  }

  // --- CREAR ---
  Future<void> createRecipe(Recipe recipe) async {
    try {
      // 1. Insertar la Receta base y obtener el ID generado
      final recipeData = {
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'cooking_time': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'nutrition': recipe.nutrition,
        'is_validated': true, // Como admin, la creamos validada
      };

      final newRecipeRes = await _supabase
          .from('Recipes')
          .insert(recipeData)
          .select('id')
          .single();
      
      final int newRecipeId = newRecipeRes['id'];

      // 2. Insertar relaciones (Pasos, Ingredientes, Tags)
      await _insertRelations(newRecipeId, recipe);

    } catch (e) {
      print("Error creando receta: $e");
      throw Exception('Error al crear receta: $e');
    }
  }

  // --- ACTUALIZAR ---
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      // 1. Actualizar tabla base
      await _supabase.from('Recipes').update({
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'cooking_time': recipe.cookingTime,
        'difficulty': recipe.difficulty,
        'nutrition': recipe.nutrition,
      }).eq('id', recipe.id);

      // 2. Estrategia simple: Borrar relaciones antiguas y crear nuevas
      // (Para evitar lógica compleja de diffing)
      await _supabase.from('Recipe_Ingredients').delete().eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Steps').delete().eq('recipe_id', recipe.id);
      await _supabase.from('Recipe_Tags').delete().eq('recipe_id', recipe.id);

      // 3. Insertar nuevas relaciones
      await _insertRelations(recipe.id, recipe);

    } catch (e) {
      print("Error actualizando receta: $e");
      throw Exception('Error al actualizar receta: $e');
    }
  }

  // --- ELIMINAR ---
  Future<void> deleteRecipe(int recipeId) async {
    try {
      // Borrar relaciones primero (Cascade delete suele configurarse en BD, 
      // pero por seguridad lo hacemos manual si no está configurado)
      await _supabase.from('Recipe_Ingredients').delete().eq('recipe_id', recipeId);
      await _supabase.from('Recipe_Steps').delete().eq('recipe_id', recipeId);
      await _supabase.from('Recipe_Tags').delete().eq('recipe_id', recipeId);
      
      // Borrar receta principal
      await _supabase.from('Recipes').delete().eq('id', recipeId);
    } catch (e) {
      print("Error eliminando receta: $e");
      throw Exception('Error al eliminar receta: $e');
    }
  }

  // --- HELPERS (Lógica privada) ---
  
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

    // C. Insertar Ingredientes (Lógica compleja: Buscar ID por nombre o Crear)
    for (var ing in recipe.ingredients) {
      // 1. Buscar si el ingrediente ya existe
      final existingIng = await _supabase
          .from('Ingredient')
          .select('ingredient_id')
          .ilike('name', ing.name) // Case insensitive
          .maybeSingle();

      int ingredientId;

      if (existingIng != null) {
        ingredientId = existingIng['ingredient_id'];
      } else {
        // 2. Si no existe, crearlo
        final newIng = await _supabase.from('Ingredient').insert({
          'name': ing.name,
          // Valores por defecto si no los tienes en el form
          'exp_time': 7, 
          'density_g/ml': 1,
          'average_weight': 100
        }).select('ingredient_id').single();
        ingredientId = newIng['ingredient_id'];
      }

      // 3. Vincular en Recipe_Ingredients
      await _supabase.from('Recipe_Ingredients').insert({
        'recipe_id': recipeId,
        'ingredient_id': ingredientId,
        'amount': ing.amount,
        'unit_abbreviation': ing.unit, // Asegúrate que esta unidad exista en tabla Unit
      });
    }
  }
}