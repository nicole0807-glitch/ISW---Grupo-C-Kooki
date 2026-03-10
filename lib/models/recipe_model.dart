class Recipe {
  final dynamic id;
  final double rating;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? cookingTime;
  final String? difficulty;
  final Map<String, dynamic> nutrition;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<int> tagIds;
  final String status;
  final String? cost;
  String? reviewerName;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.cookingTime,
    this.difficulty,
    required this.nutrition,
    required this.ingredients,
    required this.steps,
    required this.tagIds,
    this.reviewerName,
    this.cost,
    this.status = 'pending',
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    // 1. Procesamiento de Pasos
    final rawSteps = List.from(map['Recipe_Steps'] ?? []);
    rawSteps.sort(
      (a, b) => (a['step_order'] as int).compareTo(b['step_order'] as int),
    );

    final List<String> orderedInstructions = rawSteps
        .map((s) => s['instruction'] as String)
        .toList();

    // 2. Procesamiento de Tags
    final List<int> tags = (map['Recipe_Tags'] as List? ?? [])
        .map((t) => t['tag_id'] as int)
        .toList();

    return Recipe(
      id: map['id'],
      title: map['title'] ?? 'Sin título',
      description: map['description'],
      imageUrl: map['image_url'],
      tagIds: tags,
      cookingTime: map['cooking_time'],
      difficulty: map['difficulty'],
      cost: map['cost'],
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      nutrition: map['nutrition'] is Map ? map['nutrition'] : {},
      status: map['status'] ?? 'pendiente',
      ingredients: (map['Recipe_Ingredients'] as List? ?? []).map((i) {
        final ingredientData = i['Ingredient'] as Map<String, dynamic>?;
        return RecipeIngredient(
          ingredientId: i['ingredient_id'] as int? ?? 0,
          name: ingredientData?['name'] ?? 'Ingrediente desconocido',
          amount: (i['amount'] as num?)?.toDouble() ?? 0.0,
          unit: i['unit_abbreviation'] ?? '',
        );
      }).toList(),
      steps: orderedInstructions,
    );
  }
}

class RecipeIngredient {
  final int ingredientId;
  final String name;
  final double amount;
  final String unit;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.amount,
    required this.unit,
  });
}
