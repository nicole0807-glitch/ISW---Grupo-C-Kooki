import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../models/user_recipe_model.dart';
import '../../services/recipe_service.dart';

class PublishRecipeScreen extends StatefulWidget {
  const PublishRecipeScreen({super.key});

  @override
  State<PublishRecipeScreen> createState() => _PublishRecipeScreenState();
}

class _PublishRecipeScreenState extends State<PublishRecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final SupabaseClient supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionController = TextEditingController();

  String _difficulty = 'Medio';
  String _cost = 'Medio';

  final List<Map<String, dynamic>> _ingredientRows = [
    {
      'name': TextEditingController(),
      'amount': TextEditingController(),
      'unit': 'g',
    },
  ];

  final List<String> _units = [
    'g',
    'kg',
    'mL',
    'L',
    'Tazas',
    'Cdas',
    'Piezas',
    'Otro',
  ];

  Uint8List? _selectedImageBytes;
  String? _imageName;
  bool _isUploading = false;

  void _showAviso(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError
                ? Colors.redAccent.shade700
                : AppColors.nutveDarkGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _imageName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  void _addIngredient() => setState(
    () => _ingredientRows.add({
      'name': TextEditingController(),
      'amount': TextEditingController(),
      'unit': 'g',
    }),
  );

  void _removeIngredient(int index) {
    if (_ingredientRows.length > 1) {
      setState(() => _ingredientRows.removeAt(index));
    } else {
      _showAviso("¡Necesitas al menos un ingrediente!");
    }
  }

  Future<void> _handlePublish() async {
    final hasIngredient = _ingredientRows.any(
      (r) => r['name']!.text.trim().isNotEmpty,
    );
    final instructions = _instructionController.text.trim();

    if (_titleController.text.trim().isEmpty || _selectedImageBytes == null) {
      _showAviso("Necesito un título y una foto.", isError: true);
      return;
    }
    if (!hasIngredient) {
      _showAviso("Agrega al menos un ingrediente.", isError: true);
      return;
    }
    if (instructions.isEmpty) {
      _showAviso("Escribe al menos un paso de preparación.", isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No hay sesión activa.");

      final String realUserName =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['display_name'] ??
          'Chef Kooki';

      final String? imageUrl = await _recipeService.uploadRecipeImage(
        _selectedImageBytes!,
        _imageName!,
      );
      if (imageUrl == null) throw Exception("Error al guardar la imagen.");

      final ingredientsList = _ingredientRows
          .where((e) => (e['name'] as TextEditingController).text.isNotEmpty)
          .map(
            (e) => {
              'name': (e['name'] as TextEditingController).text,
              'amount':
                  '${(e['amount'] as TextEditingController).text} ${e['unit']}',
            },
          )
          .toList();

      final newRecipe = UserRecipe(
        userId: user.id,
        userName: realUserName,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        duration: _durationController.text.isEmpty
            ? "15 min"
            : _durationController.text,
        cost: _cost,
        difficulty: _difficulty,
        ingredients: ingredientsList,
        steps: instructions
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList(),
        nutrition: {},
      );

      await _recipeService.saveRecipe(newRecipe);
      _showAviso("¡Tu receta ya está disponible en la comunidad! 🎉");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showAviso(
        "Error: ${e.toString().replaceFirst('Exception: ', '')}",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7F5);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          "Publicar en Comunidad",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? Colors.black.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.75),
        foregroundColor: isDark ? Colors.white : Colors.black87,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.nutveSelectionGreen,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Publicando tu receta...",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HERO IMAGE SECTION
                      _buildImageHero(isDark),
                      const SizedBox(height: 28),

                      // TITLE SECTION
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              "📝 Título de la receta",
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildPremiumTextField(
                              _titleController,
                              "Ej: Pasta al Pesto con Albahaca",
                              isDark: isDark,
                              hintColor: hintColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // DETAILS SECTION
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("⚙️ Detalles", isDark),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChoiceRow(
                                    "Dificultad",
                                    ['Fácil', 'Medio', 'Difícil'],
                                    _difficulty,
                                    (v) => setState(() => _difficulty = v),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildChoiceRow(
                                    "Costo",
                                    ['Bajo', 'Medio', 'Alto'],
                                    _cost,
                                    (v) => setState(() => _cost = v),
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSectionTitle("⏱ Duración", isDark),
                            const SizedBox(height: 10),
                            _buildPremiumTextField(
                              _durationController,
                              "Ej: 30 min",
                              isDark: isDark,
                              hintColor: hintColor,
                              icon: Icons.timer_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // INGREDIENTS SECTION
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle("🥕 Ingredientes", isDark),
                                GestureDetector(
                                  onTap: _addIngredient,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.nutveSelectionGreen
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: AppColors.nutveSelectionGreen,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Añadir",
                                          style: TextStyle(
                                            color:
                                                AppColors.nutveSelectionGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ..._ingredientRows.asMap().entries.map((entry) {
                              final i = entry.key;
                              final row = entry.value;
                              final nameCtrl =
                                  row['name'] as TextEditingController;
                              final amountCtrl =
                                  row['amount'] as TextEditingController;
                              String unit = row['unit'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.nutveSelectionGreen
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: const TextStyle(
                                            color:
                                                AppColors.nutveSelectionGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: _buildPremiumTextField(
                                        nameCtrl,
                                        "Ingrediente",
                                        isDark: isDark,
                                        hintColor: hintColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 54,
                                      child: _buildPremiumTextField(
                                        amountCtrl,
                                        "Cant.",
                                        isDark: isDark,
                                        hintColor: hintColor,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.grey.shade200,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: unit,
                                          isDense: true,
                                          dropdownColor: isDark
                                              ? const Color(0xFF1C1C1E)
                                              : Colors.white,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          items: _units
                                              .map(
                                                (u) => DropdownMenuItem(
                                                  value: u,
                                                  child: Text(u),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _ingredientRows[i]['unit'] =
                                                    val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeIngredient(i),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // STEPS SECTION
                      _buildSectionCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("👨‍🍳 Preparación", isDark),
                            const SizedBox(height: 12),
                            _buildPremiumTextField(
                              _instructionController,
                              "Describe paso a paso cómo preparar tu receta...",
                              isDark: isDark,
                              hintColor: hintColor,
                              maxLines: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // FLOATING PUBLISH BUTTON
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
                          top: 14,
                          bottom: 30,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.65)
                              : Colors.white.withValues(alpha: 0.85),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14E85C), Color(0xFF0DCF4D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF14E85C,
                                ).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _handlePublish,
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "PUBLICAR EN COMUNIDAD",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 0.8,
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

  Widget _buildImageHero(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          image: _selectedImageBytes != null
              ? DecorationImage(
                  image: MemoryImage(_selectedImageBytes!),
                  fit: BoxFit.cover,
                )
              : null,
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: _selectedImageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.nutveSelectionGreen.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 34,
                      color: AppColors.nutveSelectionGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Toca para añadir una foto de tu plato",
                    style: TextStyle(
                      color: AppColors.nutveSelectionGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "JPG, PNG — Máx 5MB",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Cambiar foto",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Color cardColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: isDark ? Colors.white : const Color(0xFF1B3A2D),
      ),
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController controller,
    String hint, {
    required bool isDark,
    required Color hintColor,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        prefixIcon: icon != null
            ? Icon(icon, color: hintColor, size: 18)
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.nutveSelectionGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceRow(
    String label,
    List<String> options,
    String selected,
    Function(String) onSelect,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: options.map((op) {
            final isSelected = selected == op;
            return GestureDetector(
              onTap: () => onSelect(op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.nutveSelectionGreen
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.nutveSelectionGreen
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  op,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black87
                        : (isDark ? Colors.white70 : Colors.black54),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
