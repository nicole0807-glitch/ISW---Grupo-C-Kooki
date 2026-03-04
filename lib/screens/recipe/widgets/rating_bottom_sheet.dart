import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/app_colors.dart';

/// Bottom sheet interactivo para calificar una receta con estrellas y comentario.
/// Se abre con [RatingBottomSheet.show] y devuelve `true` si el envío fue exitoso.
class RatingBottomSheet extends StatefulWidget {
  final int recipeId;
  final String recipeTitle;
  final int initialRating;

  const RatingBottomSheet({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    this.initialRating = 0,
  });

  /// Abre el bottom sheet y devuelve el número de estrellas elegido
  /// (null si el usuario cerró sin calificar).
  static Future<int?> show(
    BuildContext context, {
    required int recipeId,
    required String recipeTitle,
    int initialRating = 0, // permite pre-seleccionar el voto anterior
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        initialRating: initialRating,
      ),
    );
  }

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _commentCtrl = TextEditingController();

  int _selectedStars = 0; // 0 = ninguna seleccionada
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-cargar voto anterior si existe
    _selectedStars = widget.initialRating;
  }

  static const _starColor = Color(0xFFFFC107); // Amarillo/dorado
  static const _starEmptyColor = Color(0xFFE0E0E0); // Gris claro
  static const _green = AppColors.nutveSelectionGreen;

  // ── Lógica de envío (Optimistic UI) ─────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedStars == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No hay sesión activa.');

      // ① Optimistic: cerramos el sheet INMEDIATAMENTE devolviendo las estrellas.
      //    El padre actualiza la UI al instante sin esperar la red.
      final starsToReturn = _selectedStars;
      final commentText = _commentCtrl.text.trim();
      if (mounted) Navigator.pop(context, starsToReturn);

      // ② Upsert real en Supabase en background.
      //    onConflict garantiza que si el usuario ya votó, actualiza su voto.
      //    El Trigger de Supabase recalcula el promedio automáticamente.
      await _supabase.from('recipe_ratings').upsert({
        'recipe_id': widget.recipeId,
        'user_id': user.id,
        'rating': starsToReturn,
        if (commentText.isNotEmpty) 'comment': commentText,
      }, onConflict: 'recipe_id,user_id');
    } catch (e) {
      debugPrint('❌ Error al calificar: $e');
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedStars > 0 && !_isSubmitting;

    return Padding(
      // Empuja el sheet cuando el teclado aparece
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ────────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // ── Encabezado ────────────────────────────────────────────────
            const Text(
              '¿Cómo calificarías esta receta?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.recipeTitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // ── Estrellas interactivas ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = starValue),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _selectedStars >= starValue
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _selectedStars >= starValue
                          ? _starColor
                          : _starEmptyColor,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),

            // ── Etiqueta de sentimiento ───────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabel(_selectedStars),
                key: ValueKey(_selectedStars),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedStars > 0 ? _starColor : Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Campo de comentario ───────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Care to share more about it?',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Botón Subir Aporte ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA5D6A7), // verde pastel
                  disabledBackgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black54,
                        ),
                      )
                    : const Text(
                        'Subir Aporte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Devuelve una etiqueta de sentimiento según las estrellas seleccionadas.
  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Muy mala 😞';
      case 2:
        return 'Mala 😕';
      case 3:
        return 'Regular 😐';
      case 4:
        return 'Buena 🙂';
      case 5:
        return '¡Excelente! 🤩';
      default:
        return 'Toca una estrella para calificar';
    }
  }
}
