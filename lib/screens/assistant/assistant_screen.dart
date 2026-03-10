import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import '../../utils/app_colors.dart';
import '../../services/ai_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;
  final AiService _aiService = AiService();

  // AnimatedList key for smooth message additions
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Entrance Animations
  late AnimationController _animController;
  late Animation<Offset> _slideBottomAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  int _mitrogluIndex = 1;

  // Gemini Model
  late final GenerativeModel _model;
  // TODO: Add your Gemini API Key here
  final String _apiKey = "TU_API_KEY_AQUI";

  @override
  void initState() {
    super.initState();

    // Configurar animaciones iniciales
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideBottomAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _initAssistant();
  }

  void _initAssistant() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        "Eres Mitroglu, un experto entrenador personal y nutriólogo amigable y carismático. "
        "Tus respuestas deben ser claras, concisas, motivadoras y utilizando algunos emojis. "
        "Siempre te presentas y te despides con entusiasmo. Si no sabes algo, admítelo pero "
        "ofrece buscar una solución relacionada al fitness y bienestar.",
      ),
    );

    setState(() {
      _isLoading = false;
    });

    // Iniciar animación de pantalla
    _animController.forward();

    // Añadir mensaje de bienvenida con animación tras un pequeño retraso
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _addMessage(
          "mitroglu",
          "¡Hola! Soy Mitroglu. Estoy aquí para ayudarte con nutrición, entrenamiento y recetas. ¿Qué duda tienes hoy?",
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String sender, String text) {
    _messages.add({"sender": sender, "text": text});
    if (_listKey.currentState != null) {
      _listKey.currentState!.insertItem(_messages.length - 1);
    }
    _scrollToBottom();
  }

  // --- LÓGICA DE ENVÍO Y RESPUESTA (GEMINI) ---
  Future<void> _sendMessage() async {
    String originalText = _controller.text.trim();
    if (originalText.isEmpty) return;

    _controller.clear();
    _addMessage("user", originalText);

    setState(() {
      _isTyping = true;
      _mitrogluIndex = Random().nextInt(3) + 2; // Cambia pose de Mitroglu
    });
    _scrollToBottom();

    try {
      // 1. Intentar buscar en la base de conocimientos (ai_knowledge)
      final localResponse = await _aiService.getResponseFor(originalText);

      if (localResponse != null) {
        setState(() => _mitrogluIndex = 1);
        _addMessage("mitroglu", localResponse);
      }
      // 2. Si no hay coincidencia, intentar con Gemini (si hay API Key)
      else if (_apiKey != "TU_API_KEY_AQUI") {
        final content = [Content.text(originalText)];
        final response = await _model.generateContent(content);

        setState(() => _mitrogluIndex = 1);
        _addMessage(
          "mitroglu",
          response.text ?? "Lo siento, me he quedado sin palabras.",
        );
      }
      // 3. Fallback final y registrar como no reconocido
      else {
        await _aiService.saveUnrecognized(originalText);
        await Future.delayed(const Duration(seconds: 1));
        _addMessage(
          "mitroglu",
          "Interesante... todavía estoy aprendiendo sobre eso. ¡Pero te prometo que pronto tendré una respuesta para ti! 🏋️‍♂️",
        );
      }
    } catch (e) {
      debugPrint("Error Mitroglu: $e");
      _addMessage(
        "mitroglu",
        "He tenido un pequeño mareo técnico... ¿Puedes intentar preguntarme de nuevo? 😅",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent +
              100, // Extra space for typing indicator
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Mitroglu Assistant",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.nutveSelectionGreen.withOpacity(0.05),
              AppColors.nutveDarkGreen.withOpacity(0.08),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Avatar dinámico con transición suave y FadeIn inicial
              FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1.0,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: Container(
                    key: ValueKey<int>(_mitrogluIndex),
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.nutveSelectionGreen.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                      image: DecorationImage(
                        image: AssetImage('assets/Mitroglu$_mitrogluIndex.png'),
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  initialItemCount: _messages.length,
                  itemBuilder: (context, index, animation) {
                    return _buildMessageItem(_messages[index], animation);
                  },
                ),
              ),
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.nutveSelectionGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Mitroglu está pensando...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Slide In up from bottom for Input Area
              SlideTransition(
                position: _slideBottomAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInputArea(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    Map<String, String> message,
    Animation<double> animation,
  ) {
    bool isUser = message["sender"] == "user";

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 1.0,
      child: FadeTransition(
        opacity: animation,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isUser ? AppColors.nutveSelectionGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: isUser ? const Radius.circular(24) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isUser ? AppColors.nutveSelectionGreen : Colors.black)
                      .withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message["text"]!,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 15,
        bottom: 25,
      ), // bottom padding for modern phones
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: "Pregúntale a Mitroglu...",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isTyping
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [
                          AppColors.nutveSelectionGreen,
                          AppColors.nutveDarkGreen,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _isTyping
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.nutveSelectionGreen.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
