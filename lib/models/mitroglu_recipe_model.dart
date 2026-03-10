class MitrogluRecipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final int calories;

  MitrogluRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    required this.calories,
  });

  factory MitrogluRecipe.fromJson(Map<String, dynamic> json) {
    return MitrogluRecipe(
      id: json['id'] ?? '',
      title: json['recipe_name'] ?? 'Receta de Mitroglu',
      description: json['summary'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['steps'] ?? []),
      imageUrl: json['image'],
      calories: json['nutrition']?['calories'] ?? 0,
    );
  }
}
