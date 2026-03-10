class UserRecipe {
  final String? id;
  final String userId;
  final String userName; // Nombre del autor
  final String title;
  final String imageUrl;
  final String duration;
  final String cost;
  final String difficulty;
  final List<dynamic> ingredients;
  final List<dynamic> steps;
  final Map<String, dynamic> nutrition;
  final List<double> ratings; // Lista de calificaciones para el promedio
  final double? dbAvgRating; // Calificación promedio desde la DB

  UserRecipe({
    this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.cost,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    this.ratings = const [],
    this.dbAvgRating,
  });

  // --- GETTER PARA EL PROMEDIO ---
  double get avgRating {
    if (dbAvgRating != null && dbAvgRating! > 0) return dbAvgRating!;
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.reduce((a, b) => a + b);
    return double.parse((sum / ratings.length).toStringAsFixed(1));
  }

  // --- CONVERTIR DE SUPABASE A DART ---
  factory UserRecipe.fromMap(Map<String, dynamic> map) {
    // Manejo de la lista de ratings
    List<double> parsedRatings = [];
    if (map['recipe_ratings'] != null) {
      parsedRatings = (map['recipe_ratings'] as List)
          .map((r) => (r['rating'] as num).toDouble())
          .toList();
    }

    return UserRecipe(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Usuario Kooki',
      title: map['title'] ?? 'Sin título',
      imageUrl: map['image_url'] ?? '',
      duration: map['duration'] ?? '---',
      cost: map['cost'] ?? '---',
      difficulty: map['difficulty'] ?? '---',
      dbAvgRating: (map['avg_rating'] as num?)?.toDouble(),

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
      'ingredients': ingredients,
      'steps': steps,
      'nutrition': nutrition,
      'avg_rating': dbAvgRating ?? 0.0,
    };
  }
}
