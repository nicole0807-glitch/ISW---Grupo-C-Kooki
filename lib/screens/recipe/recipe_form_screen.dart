import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kooki/controllers/recipe_controller.dart';
import 'package:kooki/models/recipe_model.dart';
import 'package:kooki/widgets/ingredient_selector.dart';
import 'package:kooki/models/ingredient_master.dart';
import 'package:kooki/utils/app_colors.dart';
import 'package:kooki/services/image_service.dart';
import 'package:kooki/widgets/kooki_remote_image.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _imgUrlCtrl;
  String? _difficulty;

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;

  bool _isUrlMode = false;

  final List<String> _difficultyOptions = ["Fácil", "Media", "Difícil"];
  List<RecipeIngredient> _ingredients = [];
  List<String> _steps = [];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _timeCtrl = TextEditingController(text: r?.cookingTime ?? '');
    _imgUrlCtrl = TextEditingController(text: r?.imageUrl ?? '');

    if (r?.imageUrl != null && r!.imageUrl!.isNotEmpty) {
      _isUrlMode = true;
    }

    if (r?.difficulty != null && _difficultyOptions.contains(r!.difficulty)) {
      _difficulty = r.difficulty;
    } else {
      _difficulty = null;
    }

    if (r != null) {
      _ingredients = List.from(r.ingredients);
      _steps = List.from(r.steps);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 30),
      helpText: 'Selecciona el tiempo de preparación',
    );
    if (picked != null) {
      setState(() {
        final totalMinutes = picked.hour * 60 + picked.minute;
        _timeCtrl.text = "$totalMinutes";
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final compressedBytes = await ImageService().compressRecipeImage(image);
      if (compressedBytes != null) {
        setState(() {
          _selectedImageBytes = compressedBytes;
          _selectedFileName =
              'recipe_${DateTime.now().millisecondsSinceEpoch}.webp';
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUrlMode) {
      _selectedImageBytes = null;
      _selectedFileName = null;
    } else {
      _imgUrlCtrl.clear();
    }

    if ((!_isUrlMode && _selectedImageBytes == null) ||
        (_isUrlMode && _imgUrlCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Debes agregar una imagen (Sube un archivo o pega una URL)",
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_ingredients.isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Añade al menos un ingrediente y un paso"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final recipeToProcess = Recipe(
      id: widget.recipe?.id ?? 0,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      imageUrl: _imgUrlCtrl.text,
      cookingTime: _timeCtrl.text,
      difficulty: _difficulty,
      nutrition: widget.recipe?.nutrition ?? {},
      ingredients: _ingredients,
      steps: _steps,
      tagIds: widget.recipe?.tagIds ?? [],
      rating: widget.recipe?.rating ?? 0.0,
      status: widget.recipe?.status ?? 'pendiente',
    );

    final success = await context
        .read<RecipeAdminController>()
        .createOrUpdateRecipe(
          recipeToProcess,
          isEdit: widget.recipe != null,
          imageBytes: _selectedImageBytes,
          fileName: _selectedFileName,
        );

    if (success && mounted) Navigator.pop(context);
  }

  void _addIngredientDialog() async {
    IngredientMaster? selectedInsumo;
    String amount = '';
    String unit = 'g';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Añadir Ingrediente",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IngredientSelector(
                    isDark: isDark,
                    onSelected: (val) {
                      setDialogState(() {
                        selectedInsumo = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: _inputDecoration("Cantidad"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => amount = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: _inputDecoration("Unidad (ej: g, ml, pza)"),
                    onChanged: (v) => unit = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveDarkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (selectedInsumo != null && amount.trim().isNotEmpty) {
                    setState(() {
                      _ingredients.add(
                        RecipeIngredient(
                          ingredientId: selectedInsumo!.ingredientId,
                          name: selectedInsumo!.name,
                          amount: double.tryParse(amount) ?? 0,
                          unit: unit.trim(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Añadir"),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.nutveDarkGreen)
          : null,
      labelStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.nutveDarkGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? "Nueva Receta" : "Editar Receta",
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 110, 24, 140),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN DE IMAGEN ---
                  const Text(
                    "Fotografía del platillo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 1. SELECTOR DE MODO
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isUrlMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isUrlMode
                                    ? Theme.of(context).cardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isUrlMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Subir Archivo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isUrlMode
                                      ? AppColors.nutveDarkGreen
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isUrlMode = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isUrlMode
                                    ? Theme.of(context).cardColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isUrlMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Usar URL",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isUrlMode
                                      ? AppColors.nutveDarkGreen
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. CONTENIDO CONDICIONAL (Muestra uno u otro)
                  if (!_isUrlMode) ...[
                    // MODO SUBIR ARCHIVO
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppColors.nutveDarkGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _selectedImageBytes != null
                                ? Colors.transparent
                                : AppColors.nutveDarkGreen.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 54,
                                    color: AppColors.nutveDarkGreen,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Toca para seleccionar de galería",
                                    style: TextStyle(
                                      color: AppColors.nutveDarkGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    // MODO URL
                    TextFormField(
                      controller: _imgUrlCtrl,
                      decoration: _inputDecoration(
                        "Enlace de la imagen",
                        hint: "https://ejemplo.com/imagen.jpg",
                        icon: Icons.link_rounded,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                    if (_imgUrlCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: KookiRemoteImage(
                            imageUrl: _imgUrlCtrl.text,
                            bucketHint: 'recipe_images',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                            placeholder: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "URL inválido",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),

                  const Text(
                    "Información Principal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration(
                      "Nombre de la Receta",
                      icon: Icons.restaurant_menu_rounded,
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? "El título es obligatorio" : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descCtrl,
                    decoration: _inputDecoration(
                      "Breve descripción (opcional)",
                      icon: Icons.short_text_rounded,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timeCtrl,
                          readOnly: true,
                          onTap: _selectTime,
                          decoration: _inputDecoration(
                            "Tiempo (min)",
                            icon: Icons.timer_rounded,
                          ),
                          validator: (v) =>
                              v!.trim().isEmpty ? "Requerido" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _difficulty,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          dropdownColor: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          items: _difficultyOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _difficulty = v),
                          decoration: _inputDecoration(
                            "Dificultad",
                            icon: Icons.speed_rounded,
                          ),
                          validator: (v) => v == null ? "Requerido" : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _sectionHeader("Ingredientes", _addIngredientDialog),
                  const SizedBox(height: 12),

                  if (_ingredients.isEmpty)
                    _buildEmptyState(
                      "Sin ingredientes",
                      "Añade los insumos necesarios para tu receta.",
                    ),

                  ..._ingredients.asMap().entries.map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.nutveDarkGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.nutveDarkGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          e.value.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "${e.value.amount} ${e.value.unit}",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              setState(() => _ingredients.removeAt(e.key)),
                          tooltip: "Eliminar ingrediente",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionHeader("Pasos de Preparación", () {
                    String step = '';
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: const Text(
                          "Nuevo Paso",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: TextField(
                          onChanged: (v) => step = v,
                          decoration: _inputDecoration(
                            "Escribe la instrucción...",
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              "Cancelar",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.nutveDarkGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (step.trim().isNotEmpty)
                                setState(() => _steps.add(step.trim()));
                              Navigator.pop(ctx);
                            },
                            child: const Text("Añadir"),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  if (_steps.isEmpty)
                    _buildEmptyState(
                      "Sin instrucciones",
                      "Registra el paso a paso detallado.",
                    ),

                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _steps.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (oldIdx < newIdx) newIdx -= 1;
                        final item = _steps.removeAt(oldIdx);
                        _steps.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, i) {
                      return Container(
                        key: ValueKey("step_$i"),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.nutveDarkGreen,
                            radius: 14,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            _steps[i],
                            style: const TextStyle(height: 1.4),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _steps.removeAt(i)),
                              ),
                              Icon(
                                Icons.drag_indicator_rounded,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // --- FLOATING ACTION BUTTON AREA (PREMIUM) ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    top: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF13EC5B), Color(0xFF0FCE4E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13EC5B).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: controller.isLoading ? null : _submit,
                        child: Center(
                          child: controller.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      widget.recipe == null
                                          ? Icons.auto_awesome_rounded
                                          : Icons.save_rounded,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.recipe == null
                                          ? "PUBLICAR RECETA"
                                          : "GUARDAR CAMBIOS",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 1.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Material(
          color: AppColors.nutveDarkGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: AppColors.nutveDarkGreen,
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Añadir",
                    style: TextStyle(
                      color: AppColors.nutveDarkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.02)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
