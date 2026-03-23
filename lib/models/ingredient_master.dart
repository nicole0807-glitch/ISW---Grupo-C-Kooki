/// Modelo para la tabla maestra de ingredientes
class IngredientMaster {
  final int ingredientId;
  final String name;
  final int? expTime;
  final double? densityGMl;
  final double? averageWeight;

  IngredientMaster({
    required this.ingredientId,
    required this.name,
    this.expTime,
    this.densityGMl,
    this.averageWeight,
  });

  factory IngredientMaster.fromJson(Map<String, dynamic> json) {
    return IngredientMaster(
      ingredientId: json['ingredient_id'] as int,
      name: json['name'] as String,
      expTime: json['exp_time'] as int?,
      densityGMl: json['density_g/ml'] != null 
          ? (json['density_g/ml'] as num).toDouble() 
          : null,
      averageWeight: json['average_weight'] != null 
          ? (json['average_weight'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'name': name,
      'exp_time': expTime,
      'density_g/ml': densityGMl,
      'average_weight': averageWeight,
    };
  }
}