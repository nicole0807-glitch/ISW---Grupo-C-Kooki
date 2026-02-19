import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. ENTRENAMIENTO DE IA
  // ==========================================

  /// Simula o dispara el entrenamiento del modelo de IA.
  Future<void> trainAIModel() async {
    try {
      // 1. Actualizamos el flag en la base de datos para que el motor de IA sepa que hay cambios
      await _supabase
          .from('ai_knowledge')
          .update({
            'is_pending_training': true,
            'last_trained_at': DateTime.now().toIso8601String(),
          })
          .eq('id', 1); // Asumiendo fila de control con ID 1

      // 2. Simulamos el tiempo de procesamiento
      await Future.delayed(const Duration(seconds: 3));

      // 3. Enviamos notificación automática de éxito
      await sendGlobalNotification(
        title: "🤖 IA Actualizada",
        content: "Kooki AI ha aprendido nuevas recetas y combinaciones.",
        type: 'ai_update',
      );
    } catch (e) {
      throw Exception("Fallo al entrenar IA: $e");
    }
  }

  // ==========================================
  // 2. SISTEMA DE NOTIFICACIONES
  // ==========================================

  /// Inserta una notificación que llegará a todos los usuarios.
  Future<void> sendGlobalNotification({
    required String title,
    required String content,
    String type = 'manual_admin',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'title': title,
        'content': content,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Error al enviar notificación: $e");
    }
  }

  // ==========================================
  // 3. GESTIÓN DE RECETAS PROFESIONALES
  // ==========================================

  /// Añade una receta a la tabla oficial 'Recipes' e incluye al especialista.
  Future<void> addProfessionalRecipe(Map<String, dynamic> recipeData) async {
    try {
      // 1. Insertar en la tabla Recipes (la de especialistas)
      await _supabase.from('Recipes').insert({
        'title': recipeData['title'],
        'author_name': recipeData['author_name'], // El especialista
        'image_url': recipeData['image_url'],
        'calories': recipeData['calories'],
        'rating': 5.0, // Por defecto al ser Pro
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Notificar a la comunidad del nuevo contenido
      await sendGlobalNotification(
        title: "👨‍🍳 Nueva Receta de Especialista",
        content:
            "El Chef ${recipeData['author_name']} ha publicado: ${recipeData['title']}",
        type: 'new_pro_recipe',
      );
    } catch (e) {
      throw Exception("Error al publicar receta pro: $e");
    }
  }

  // ==========================================
  // 4. ELIMINACIÓN DE RECETAS (TOTAL)
  // ==========================================

  /// Elimina una receta de la comunidad o profesional.
  /// isProfessional determina la tabla de origen.
  Future<void> deleteRecipe(dynamic recipeId, bool isProfessional) async {
    try {
      final String table = isProfessional ? 'Recipes' : 'user_recipes';

      // Intentar borrado
      await _supabase.from(table).delete().eq('id', recipeId);
    } catch (e) {
      // Si hay error de Foreign Key, es porque falta el ON DELETE CASCADE en Supabase
      throw Exception(
        "Error de base de datos: Verifica las dependencias de la receta (comentarios/votos).",
      );
    }
  }
}
