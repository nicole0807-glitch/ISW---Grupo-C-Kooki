/// Modelo para la tabla `shopping_list` de Supabase.
/// Soporta JOIN con `Ingredient(name)` para mostrar el nombre en UI.
class ShoppingListItem {
  final int? id;
  final String userId;
  final int ingredientId;
  final double quantity;
  final String unit;
  final bool isBought;
  final DateTime? createdAt;

  /// Nombre del ingrediente, disponible cuando se hace SELECT con JOIN:
  /// `.select('*, Ingredient(name)')`. Puede ser null si no se hizo JOIN.
  final String? ingredientName;

  const ShoppingListItem({
    this.id,
    required this.userId,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.isBought = false,
    this.createdAt,
    this.ingredientName,
  });

  /// Nombre legible para mostrar en UI.
  String get displayName =>
      (ingredientName != null && ingredientName!.isNotEmpty)
      ? ingredientName!
      : 'Ingrediente #$ingredientId';

  /// Cantidad formateada para mostrar en UI, e.g. "200 g".
  String get displayQuantity {
    final qty = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return '$qty $unit';
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'ingredient_id': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'is_bought': isBought,
  };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    // El JOIN trae Ingredient como mapa anidado: { "name": "..." }
    final ingredientData = json['Ingredient'] as Map<String, dynamic>?;
    final String? name = ingredientData?['name'] as String?;

    return ShoppingListItem(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      ingredientId: json['ingredient_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      isBought: json['is_bought'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      ingredientName: name,
    );
  }
}
