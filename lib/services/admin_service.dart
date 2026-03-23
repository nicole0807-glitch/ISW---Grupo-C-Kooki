import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. ENTRENAMIENTO DE IA
  // ==========================================

  /// Simula o dispara el entrenamiento del modelo de IA.
  /// Ahora recibe una lista de palabras clave (separadas por comitas) y una respuesta
  Future<void> trainAIModelWithData(
    String keywordsInput,
    String responseText,
  ) async {
    try {
      // 1. Limpiamos y preparamos las palabras clave
      final keywords = keywordsInput
          .split(',')
          .map((k) => k.trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toList();

      if (keywords.isEmpty || responseText.trim().isEmpty) {
        throw Exception(
          "Las palabras clave y la respuesta no pueden estar vacías.",
        );
      }

      // 2. Insertamos o actualizamos en ai_knowledge para cada palabra clave
      for (String kw in keywords) {
        await _supabase.from('ai_knowledge').upsert({
          'keyword': kw,
          'response': responseText.trim(),
        });
      }

      // 3. Registramos el entrenamiento en la tabla de logs (ai_training)
      await _supabase.from('ai_training').insert({
        'status': 'completed',
        'details':
            'Entrenamiento manual: ${keywords.length} palabras clave actualizadas.',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. Enviamos notificación automática de éxito
      await sendGlobalNotification(
        title: "🤖 IA Actualizada",
        content:
            "Kooki AI ha aprendido nuevas respuestas para: ${keywords.join(', ')}",
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
  // ==========================================
  // 5. SISTEMA DE REPORTES Y BANEO
  // ==========================================

  /// Reportar una receta por comportamiento inapropiado.
  Future<void> reportRecipe({
    required String recipeId,
    required bool isCommunity,
    required String reason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      print('🚩 Intentando reportar receta ID: $recipeId');
      print('👤 Reporter ID: ${user?.id}');
      print('📝 Motivo: $reason');

      await _supabase.from('recipe_reports').insert({
        'recipe_id': recipeId,
        'is_community': isCommunity,
        'reporter_id': user?.id,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Reporte insertado correctamente en recipe_reports');
    } catch (e) {
      print('❌ Error al reportar receta: $e');
      throw Exception("No se pudo enviar el reporte: $e");
    }
  }

  /// Obtener todas las recetas reportadas de forma optimizada.
  Future<List<Map<String, dynamic>>> getReportedRecipes() async {
    try {
      print('🔍 [DEBUG] AdminService: Iniciando consulta de reportes...');
      
      // 1. OBTENER REPORTES BASE
      // Si la tabla no existe o no hay permisos, esto lanzará una excepción o devolverá []
      final response = await _supabase
          .from('recipe_reports')
          .select('*')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      print('🔍 [DEBUG] AdminService: Respuesta cruda recibida: $response');

      final List<Map<String, dynamic>> reports =
          List<Map<String, dynamic>>.from(response);

      if (reports.isEmpty) {
        print('🔍 [DEBUG] AdminService: No se encontraron reportes en la base de datos (o RLS los bloqueó).');
        return [];
      }

      print('🔍 [DEBUG] AdminService: Procesando ${reports.length} reportes...');

      // 2. OBTENER NOMBRES DE LOS REPORTEROS (Opcional, no debe bloquear)
      final reporterIds = reports
          .map((r) => r['reporter_id'])
          .where((id) => id != null)
          .toSet()
          .map((id) => id.toString())
          .toList();

      Map<String, String> reporterNames = {};
      try {
        if (reporterIds.isNotEmpty) {
          final profileRes = await _supabase
              .from('Profile')
              .select('id, full_name')
              .filter('id', 'in', reporterIds);
          for (var p in profileRes) {
            reporterNames[p['id'].toString()] = p['full_name']?.toString() ?? "Usuario";
          }
        }
      } catch (pe) {
        print('⚠️ [DEBUG] AdminService: Error obteniendo perfiles de reporteros: $pe');
      }

      // 3. OBTENER TÍTULOS DE RECETAS (Masivo)
      final communityIds = reports
          .where((r) => r['is_community'] == true)
          .map((r) => r['recipe_id'])
          .toList();

      final proIds = reports
          .where((r) => r['is_community'] == false)
          .map((r) => r['recipe_id'])
          .toList();

      Map<String, String> titles = {};

      try {
        if (communityIds.isNotEmpty) {
          final res = await _supabase
              .from('user_recipes')
              .select('id, title')
              .filter('id', 'in', communityIds);
          for (var item in res) {
            titles['c_${item['id']}'] = item['title'].toString();
          }
        }
        if (proIds.isNotEmpty) {
          final res = await _supabase
              .from('Recipes')
              .select('id, title')
              .filter('id', 'in', proIds);
          for (var item in res) {
            titles['p_${item['id']}'] = item['title'].toString();
          }
        }
      } catch (re) {
        print('⚠️ [DEBUG] AdminService: Error obteniendo títulos de las recetas: $re');
      }

      // 4. ENRIQUECER RESULTADOS
      for (var report in reports) {
        final id = report['recipe_id'];
        final isComm = report['is_community'] == true;
        final key = isComm ? 'c_$id' : 'p_$id';
        report['recipe_title'] = titles[key] ?? "No se pudo cargar el título ($id)";

        final rId = report['reporter_id']?.toString();
        report['reporter'] = {
          'full_name': reporterNames[rId] ?? "Anónimo"
        };
      }

      print('✅ [DEBUG] AdminService: Carga de reportes finalizada.');
      return reports;
    } catch (e) {
      print('❌ [ERROR] AdminService.getReportedRecipes: $e');
      // Importante: No devolver lista vacía silenciosamente si es un error fatal de conexión/tabla
      rethrow; 
    }
  }

  /// Banear (eliminar) una receta reportada.
  Future<void> banRecipe(
    dynamic recipeId,
    bool isCommunity,
    dynamic reportId,
  ) async {
    try {
      // 1. Eliminar la receta
      await deleteRecipe(recipeId, !isCommunity);

      // 2. Eliminar el reporte asociado
      await _supabase.from('recipe_reports').delete().eq('id', reportId);

      // 3. Notificar globalmente (opcional)
      await sendGlobalNotification(
        title: "🛡️ Moderación de Contenido",
        content: "Se ha eliminado una receta que no cumplía con las normas.",
        type: 'moderation',
      );
    } catch (e) {
      throw Exception("Error al banear receta: $e");
    }
  }

  /// Descartar un reporte sin eliminar la receta.
  Future<void> dismissReport(dynamic reportId) async {
    try {
      await _supabase.from('recipe_reports').delete().eq('id', reportId);
    } catch (e) {
      throw Exception("Error al descartar reporte: $e");
    }
  }
}
