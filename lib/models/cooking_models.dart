/// Representa un ingrediente que falta en la despensa para poder cocinar una receta.
class MissingIngredient {
  final int ingredientId;
  final String name;
  final double missingQuantity;
  final String unit;

  MissingIngredient({
    required this.ingredientId,
    required this.name,
    required this.missingQuantity,
    required this.unit,
  });

  @override
  String toString() =>
      'MissingIngredient(id: $ingredientId, name: $name, missing: $missingQuantity $unit)';
}

/// Resultado de la validación de inventario contra los requisitos de una receta.
class CookingValidationResult {
  /// true si el usuario tiene TODOS los ingredientes en cantidad suficiente.
  final bool canCook;

  /// Lista de ingredientes faltantes (vacía si canCook == true).
  final List<MissingIngredient> missing;

  const CookingValidationResult({required this.canCook, required this.missing});

  /// Constructor de conveniencia para "todo ok".
  const CookingValidationResult.allGood() : canCook = true, missing = const [];
}
