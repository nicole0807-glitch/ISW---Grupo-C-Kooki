import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/home_controller.dart';
import '../../models/user_recipe_model.dart';
import '../../utils/app_colors.dart';

class UserRecipeDetailScreen extends StatefulWidget {
  final UserRecipe recipe;

  const UserRecipeDetailScreen({super.key, required this.recipe});

  @override
  State<UserRecipeDetailScreen> createState() => _UserRecipeDetailScreenState();
}

class _UserRecipeDetailScreenState extends State<UserRecipeDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  final Set<dynamic> _autoModeratedIds = <dynamic>{};

  // Algoritmo básico con palabras ofensivas pre-cargadas.
  static const List<String> _offensiveWords = [
    'idiota',
    'estupido',
    'estúpido',
    'imbecil',
    'imbécil',
    'pendejo',
    'mierda',
    'carajo',
    'fuck',
    'shit',
    'bitch',
  ];

  // --- 1. FUNCIÓN PARA GUARDAR CALIFICACIÓN (STARS) ---
  Future<void> _rateRecipe(int ratingValue) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('recipe_ratings').upsert({
        'recipe_id': widget.recipe.id,
        'user_id': user.id,
        'rating': ratingValue,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Calificado con $ratingValue estrellas!")),
        );
      }
    } catch (e) {
      debugPrint("Error al calificar: $e");
    }
  }

  // --- 2. DIÁLOGO PARA SELECCIONAR ESTRELLAS ---
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int selectedStars = 5;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Califica esta receta",
                textAlign: TextAlign.center,
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedStars = index + 1),
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nutveDarkGreen,
                  ),
                  onPressed: () {
                    _rateRecipe(selectedStars);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Enviar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. FUNCIÓN PARA ENVIAR COMENTARIO (EVITA "ANÓNIMO") ---
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final user = supabase.auth.currentUser;
      // Extraemos el nombre real de los metadatos de Auth para evitar el anonimato
      final String realUserName =
          user?.userMetadata?['full_name'] ??
          user?.userMetadata?['display_name'] ??
          'Usuario kooki';

      await supabase.from('recipe_comments').insert({
        'recipe_id': widget.recipe.id,
        'user_id': user?.id,
        'user_name': realUserName, // Se guarda el nombre real
        'comment': text,
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _containsOffensiveLanguage(String text) {
    final normalized = text.toLowerCase();
    return _offensiveWords.any((word) => normalized.contains(word));
  }

  Future<void> _deleteComment(dynamic commentId, {bool silent = false}) async {
    try {
      await supabase.from('recipe_comments').delete().eq('id', commentId);
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comentario eliminado.')));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  Future<void> _confirmAndDeleteComment(dynamic commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text(
          '¿Confirmas eliminar este comentario de forma definitiva?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComment(commentId);
    }
  }

  Future<void> _autoModerateComments(
    List<Map<String, dynamic>> comments,
  ) async {
    for (final comment in comments) {
      final commentId = comment['id'];
      final text = (comment['comment'] ?? '').toString();
      if (commentId == null || _autoModeratedIds.contains(commentId)) {
        continue;
      }
      if (_containsOffensiveLanguage(text)) {
        _autoModeratedIds.add(commentId);
        await _deleteComment(commentId, silent: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(context),
          ],
          body: Column(
            children: [
              _buildRecipeSummary(),
              const TabBar(
                labelColor: AppColors.nutveDarkGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.nutveDarkGreen,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Ingredientes"),
                  Tab(text: "Pasos"),
                  Tab(text: "Opiniones"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildIngredientsList(),
                    _buildStepsList(),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.nutveDarkGreen,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: widget.recipe.imageUrl.isNotEmpty
            ? Image.network(widget.recipe.imageUrl, fit: BoxFit.cover)
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
      ),
    );
  }

  Widget _buildRecipeSummary() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.nutveDarkGreen,
              ),
              const SizedBox(width: 5),
              Text(
                "Subida por ${widget.recipe.userName}",
                style: const TextStyle(
                  color: AppColors.nutveDarkGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(
                  Icons.bolt,
                  widget.recipe.difficulty,
                  "Dificultad",
                ),
                _summaryItem(
                  Icons.payments_outlined,
                  widget.recipe.cost,
                  "Costo",
                ),
                _summaryItem(Icons.schedule, widget.recipe.duration, "Tiempo"),

                // RATING DINÁMICO
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('recipe_ratings')
                      .stream(primaryKey: ['id'])
                      .eq('recipe_id', widget.recipe.id!),
                  builder: (context, snapshot) {
                    double displayRating = 0.0;
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final ratings = snapshot.data!
                          .map((r) => r['rating'] as int)
                          .toList();
                      displayRating =
                          ratings.reduce((a, b) => a + b) / ratings.length;
                    }
                    return GestureDetector(
                      onTap: _showRatingDialog,
                      child: _summaryItem(
                        Icons.star,
                        displayRating.toStringAsFixed(1),
                        "Calificación",
                        isStar: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String value,
    String label, {
    bool isStar = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isStar ? Colors.amber : AppColors.nutveDarkGreen,
          size: 22,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.recipe.ingredients.length,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(
          Icons.check_circle,
          color: AppColors.nutveSelectionGreen,
          size: 20,
        ),
        title: Text(widget.recipe.ingredients[index].toString()),
      ),
    );
  }

  Widget _buildStepsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.recipe.steps.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.nutveDarkGreen,
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                widget.recipe.steps[index].toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final isAdmin = context.watch<HomeController>().isAdmin;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('recipe_comments')
                .stream(primaryKey: ['id'])
                .eq('recipe_id', widget.recipe.id!)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final comments = snapshot.data!;

              // Moderación automática para admins con algoritmo local de palabras ofensivas.
              if (isAdmin) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _autoModerateComments(comments);
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.only(bottom: 10),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.nutveSelectionGreen,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      c['user_name'] ?? 'Usuario Nutve',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c['comment'] ?? ''),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar comentario',
                            onPressed: () => _confirmAndDeleteComment(c['id']),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
              decoration: InputDecoration(
                hintText: "Escribe tu opinión...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.nutveDarkGreen),
                  onPressed: _sendComment,
                ),
        ],
      ),
    );
  }
}
