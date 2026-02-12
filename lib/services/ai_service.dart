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
    await _supabase.from('ai_training').insert({'unrecognized_input': input});
  }
}
