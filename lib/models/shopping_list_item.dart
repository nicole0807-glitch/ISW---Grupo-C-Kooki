/// Modelo para la tabla `shopping_list` de Supabase.
class ShoppingListItem {
  final int? id;
  final String userId;
  final int ingredientId;
  final double quantity;
  final String unit;
  final bool isBought;
  final DateTime? createdAt;

  const ShoppingListItem({
    this.id,
    required this.userId,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.isBought = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'ingredient_id': ingredientId,
    'quantity': quantity,
    'unit': unit,
    'is_bought': isBought,
  };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
