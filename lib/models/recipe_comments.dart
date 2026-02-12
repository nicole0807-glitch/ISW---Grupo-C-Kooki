class RecipeComment {
  final String id;
  final String userName;
  final String comment;
  final DateTime createdAt;

  RecipeComment({
    required this.id,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory RecipeComment.fromMap(Map<String, dynamic> map) {
    return RecipeComment(
      id: map['id'],
      userName: map['user_name'] ?? 'Anónimo',
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
