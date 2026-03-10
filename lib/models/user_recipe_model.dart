class UserRecipe {
  final String? id;
  final String userId;
  final String userName; // Nombre del autor
  final String title;
  final String imageUrl;
  final String duration;
  final String cost;
  final String difficulty;
  final String instructions;
  final List<dynamic> ingredients;
  final List<dynamic> steps;
  final Map<String, dynamic> nutrition;
  final List<double> ratings; // Lista de calificaciones para el promedio

  UserRecipe({
    this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.cost,
    required this.difficulty,
    required this.instructions,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    this.ratings = const [],
  });

  // --- GETTER PARA EL PROMEDIO (Se usa en Home y Detalle) ---
  double get avgRating {
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.reduce((a, b) => a + b);
    return double.parse((sum / ratings.length).toStringAsFixed(1));
  }

  // --- CONVERTIR DE SUPABASE A DART ---
  factory UserRecipe.fromMap(Map<String, dynamic> map) {
    // Manejo de la lista de ratings (si vienen como objetos de una relación)
    List<double> parsedRatings = [];
    if (map['recipe_ratings'] != null) {
      parsedRatings = (map['recipe_ratings'] as List)
          .map((r) => (r['rating'] as num).toDouble())
          .toList();
    } else if (map['ratings'] != null) {
      parsedRatings = (map['ratings'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return UserRecipe(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      // Prioriza 'user_name' de la DB, si no, usa el metadato
      userName: map['user_name'] ?? 'Chef Nutve',
      title: map['title'] ?? 'Sin título',
      imageUrl: map['image_url'] ?? '',
      duration: map['duration'] ?? '---',
      cost: map['cost'] ?? '---',
      difficulty: map['difficulty'] ?? '---',
      instructions: map['instructions'] ?? '',

      // Limpieza de listas para evitar errores de tipo JSON
      ingredients:
          (map['ingredients'] as List?)?.map((item) {
            if (item is Map) return item['name'] ?? item.toString();
            return item.toString();
          }).toList() ??
          [],

      steps:
          (map['steps'] as List?)?.map((item) {
            if (item is Map) return item['step'] ?? item.toString();
            return item.toString();
          }).toList() ??
          [],

      nutrition: map['nutrition'] is Map ? map['nutrition'] : {},
      ratings: parsedRatings,
    );
  }

  // --- CONVERTIR DE DART A SUPABASE ---
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'image_url': imageUrl,
      'duration': duration,
      'cost': cost,
      'difficulty': difficulty,
      'instructions': instructions,
      'ingredients': ingredients,
      'steps': steps,
      'nutrition': nutrition,
      // Los ratings no se suelen guardar aquí, sino en su propia tabla
    };
  }
}
