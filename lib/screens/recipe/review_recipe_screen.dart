import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipe_model.dart';
import '../../models/recipe_validation_model.dart';
import '../../services/recipe_validation_service.dart';

class ReviewRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const ReviewRecipeScreen({super.key, required this.recipe});

  @override
  State<ReviewRecipeScreen> createState() => _ReviewRecipeScreenState();
}

class _ReviewRecipeScreenState extends State<ReviewRecipeScreen> {
  final RecipeValidationService _validationService = RecipeValidationService();
  final _notesController = TextEditingController();

  bool _accuracyChecked = false;
  bool _photoChecked = false;
  bool _clarityChecked = false;
  bool _allergenChecked = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processValidation(String newStatus) async {
    // 1. Prevención de errores: Notas obligatorias para rechazo o cambios
    if ((newStatus == 'rechazado' || newStatus == 'requiere_cambio') &&
        _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debes dejar un comentario para rechazar o solicitar cambios.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final nutritionistId = Supabase.instance.client.auth.currentUser!.id;

      // 2. Creación del modelo limpio (usando los nombres de variable corregidos)
      final validation = RecipeValidation(
        recipeId: widget.recipe.id,
        reviewerId: nutritionistId,
        checkNutritionalAccuracy: _accuracyChecked,
        checkPhotoQuality: _photoChecked,
        checkInstructionClarity: _clarityChecked,
        checkAllergenLabeling: _allergenChecked,
        reviewNotes: _notesController.text.trim(),
      );

      // 3. Llamada al servicio (sin parámetros extra innecesarios)
      await _validationService.submitValidation(
        validation: validation,
        newStatus: newStatus,
      );

      if (mounted) {
        // Retornamos 'true' para que ValidationQueueScreen sepa que debe refrescar la lista
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Receta procesada como: $newStatus")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al validar: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Revisar Receta",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility, color: Color(0xFF61896F)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecipeSummaryCard(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    "Lista de Verificación",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildChecklist(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    "Notas del Revisor",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildNotesField(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildRecipeSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.recipe.imageUrl ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey, width: 64, height: 64),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ENVIADO POR EL CHEF MARCO",
                    style: TextStyle(
                      color: Color(0xFF13EC5B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Receta Saludable Premium",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildCheckItem(
              "Precisión del valor nutricional",
              "Las calorías y macros coinciden con los ingredientes",
              _accuracyChecked,
              (val) => setState(() => _accuracyChecked = val!),
            ),
            _buildCheckItem(
              "Calidad y conformidad de la foto",
              "Alta resolución, sin marcas de agua",
              _photoChecked,
              (val) => setState(() => _photoChecked = val!),
            ),
            _buildCheckItem(
              "Claridad y seguridad de las instrucciones",
              "Los pasos son fáciles de seguir y seguros",
              _clarityChecked,
              (val) => setState(() => _clarityChecked = val!),
            ),
            _buildCheckItem(
              "Correcto etiquetado de alérgenos",
              "Las etiquetas coinciden con los ingredientes listados",
              _allergenChecked,
              (val) => setState(() => _allergenChecked = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF13EC5B),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _notesController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: "Escribe comentarios específicos para el autor...",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC5B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                // Sincronizado con la base de datos: 'aprobado'
                onPressed: _isSubmitting
                    ? null
                    : () => _processValidation('aprobado'),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "Aprobar Receta",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.grey.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Sincronizado con la base de datos: 'rechazado'
                    onPressed: _isSubmitting
                        ? null
                        : () => _processValidation('rechazado'),
                    icon: const Icon(Icons.cancel),
                    label: const Text(
                      "Rechazar",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF61896F),
                      side: BorderSide(color: Colors.grey.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Sincronizado con la base de datos: 'requiere_cambio'
                    onPressed: _isSubmitting
                        ? null
                        : () => _processValidation('requiere_cambio'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      "Solicitar cambios",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
