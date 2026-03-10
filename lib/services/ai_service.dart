import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  final _supabase = Supabase.instance.client;

  // Obtener toda la memoria
  Future<Map<String, String>> fetchKnowledge() async {
    final response = await _supabase.from('ai_knowledge').select();
    final Map<String, String> memory = {};
    for (var item in response) {
      memory[item['keyword'].toString().toLowerCase()] = item['response'];
    }
    return memory;
  }

  // Guardar un nuevo conocimiento (Entrenamiento manual)
  Future<void> saveKnowledge(String keyword, String response) async {
    await _supabase.from('ai_knowledge').upsert({
      'keyword': keyword.toLowerCase().trim(),
      'response': response.trim(),
    });
  }

  // Guardar palabra no reconocida
  Future<void> saveUnrecognized(String input) async {
    try {
      await _supabase.from('ai_training').insert({'unrecognized_input': input});
    } catch (e) {
      print('Error saving unrecognized input: $e');
    }
  }

  // Buscar respuesta por palabra clave
  Future<String?> getResponseFor(String input) async {
    final normalizedInput = input.toLowerCase().trim();
    final knowledge = await fetchKnowledge();

    // Intento de coincidencia exacta
    if (knowledge.containsKey(normalizedInput)) {
      return knowledge[normalizedInput];
    }

    // Intento de coincidencia parcial
    for (var entry in knowledge.entries) {
      if (normalizedInput.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}
