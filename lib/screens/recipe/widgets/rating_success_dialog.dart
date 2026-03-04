import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

/// Dialog de éxito que se muestra tras enviar una calificación.
/// Llama a [RatingSuccessDialog.show] para abrirlo.
class RatingSuccessDialog extends StatelessWidget {
  const RatingSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RatingSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ilustración / Placeholder ─────────────────────────────────
            // El usuario reemplazará este Container por su asset.
            // Ejemplo: Image.asset('assets/rating_success.png', height: 130)
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 70,
                color: Color(0xFFFFC107),
              ),
            ),
            const SizedBox(height: 24),

            // ── Título ────────────────────────────────────────────────────
            const Text(
              'Gracias por tu\nCalificación',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // ── Subtítulo ─────────────────────────────────────────────────
            Text(
              'Al calificarnos, hacer que tu voz se escuche '
              'y nosotros en Kooki escuchemos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Botón cerrar ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '¡Genial!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
