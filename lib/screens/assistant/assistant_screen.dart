import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../utils/app_colors.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<Map<String, String>> _messages = [];
  Map<String, String> _knowledgeBase = {};

  bool _isLoading = true;
  int _mitrogluIndex = 1;

  @override
  void initState() {
    super.initState();
    _initAssistant();
  }

  // --- 1. CARGA INICIAL Y MENÚ DE BIENVENIDA ---
  Future<void> _initAssistant() async {
    try {
      // Descargar memoria de Supabase
      final data = await _supabase.from('ai_knowledge').select();
      final Map<String, String> freshMemory = {};

      for (var row in data) {
        freshMemory[row['keyword'].toString().toLowerCase()] = row['response']
            .toString();
      }

      if (mounted) {
        setState(() {
          _knowledgeBase = freshMemory;
          _isLoading = false;

          // MOSTRAR MENÚ PRINCIPAL AUTOMÁTICAMENTE
          _messages.add({
            "sender": "mitroglu",
            "text":
                "¡Hola! Soy Mitroglu. Para ayudarte mejor, escribe el nombre de uno de estos temas:\n\n"
                "• *Nutrición* (Conceptos básicos y macros)\n"
                "• *Entrenamiento* (Rutinas y rendimiento)\n"
                "• *Salud* (Bienestar y recuperación)\n"
                "• *Recetas* (Ideas para tus comidas)",
          });
        });
      }
    } catch (e) {
      debugPrint("Error inicializando asistente: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. LÓGICA DE ENVÍO Y BÚSQUEDA ---
  void _sendMessage() async {
    String originalText = _controller.text.trim();
    if (originalText.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": originalText});
      _controller.clear();
      _mitrogluIndex = Random().nextInt(3) + 2; // Cambia pose de Mitroglu
    });
    _scrollToBottom();

    String input = originalText.toLowerCase();
    String response =
        "No lo sé aún, pero ya lo guardé en mi entrenamiento para aprenderlo pronto.";
    bool found = false;

    // Buscar en la base descargada
    if (_knowledgeBase.containsKey(input)) {
      response = _knowledgeBase[input]!;
      found = true;
    } else {
      for (var key in _knowledgeBase.keys) {
        if (input.contains(key)) {
          response = _knowledgeBase[key]!;
          found = true;
          break;
        }
      }
    }

    // Si no lo conoce, registrar en tabla de entrenamiento
    if (!found) {
      await _supabase.from('ai_training').insert({
        'unrecognized_input': originalText,
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _messages.add({"sender": "mitroglu", "text": response}));
      _scrollToBottom();
    }
  }

  // --- 3. DIÁLOGO DE ENTRENAMIENTO MULTI-PALABRA ---
  void _showTrainDialog() {
    final kCtrl = TextEditingController();
    final rCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Entrenamiento Grupal"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kCtrl,
                  decoration: const InputDecoration(
                    labelText: "Palabras clave",
                    helperText: "Separa por comas (ej: hola, hey, buen dia)",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Respuesta única",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCELAR"),
              ),
              if (isSaving)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (kCtrl.text.isNotEmpty && rCtrl.text.isNotEmpty) {
                      setDialogState(() => isSaving = true);

                      List<String> keywords = kCtrl.text
                          .split(',')
                          .map((e) => e.trim().toLowerCase())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final List<Map<String, dynamic>> dataToUpload = keywords
                          .map(
                            (k) => {
                              'keyword': k,
                              'response': rCtrl.text.trim(),
                            },
                          )
                          .toList();

                      await _supabase.from('ai_knowledge').upsert(dataToUpload);
                      await _initAssistant(); // Recargar memoria

                      if (mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text("GUARDAR EN NUBE"),
                ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mitroglu Assistant"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: AppColors.nutveDarkGreen),
            onPressed: _showTrainDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar dinámico
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.nutveSelectionGreen,
                width: 3,
              ),
              image: DecorationImage(
                image: AssetImage('assets/Mitroglu$_mitrogluIndex.png'),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                bool isUser = _messages[i]["sender"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.nutveSelectionGreen
                          : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser
                            ? const Radius.circular(15)
                            : Radius.zero,
                        bottomRight: isUser
                            ? Radius.zero
                            : const Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      _messages[i]["text"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Escribe una opción...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: AppColors.nutveDarkGreen,
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
