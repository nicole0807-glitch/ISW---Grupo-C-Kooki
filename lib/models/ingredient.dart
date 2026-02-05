class Ingredient {
  final String? ingredient_id;
  final String user_id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expirationDate;
  final String? imageUrl;
  final String status; // 'Fresh', 'Low Stock', 'Expiring Soon'
  final DateTime createdAt;

  Ingredient({
    required this.ingredient_id,
    required this.user_id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.imageUrl,
    this.status = 'Fresh',
    required this.createdAt,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      ingredient_id: json['ingredient_id'] as String?,
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'Fresh',
      createdAt: DateTime.parse(json['created_at'] as String),
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (ingredient_id != null) 'ingredient_id': ingredient_id,
      'user_id': user_id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String(),
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Ingredient copyWith({
    String? ingredient_id,
    String? user_id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return Ingredient(
      ingredient_id: ingredient_id ?? this.ingredient_id,
      user_id: user_id ?? this.user_id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}