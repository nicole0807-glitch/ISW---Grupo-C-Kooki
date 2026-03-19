import 'package:flutter/material.dart';

import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_colors.dart';
import '../recipe/recipe_detail_screen.dart';

enum RecipeSearchSort { recent, alphabetical }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RecipeService _recipeService = RecipeService();
  late final Future<List<Recipe>> _recipesFuture;

  String _query = '';
  RecipeSearchSort _selectedSort = RecipeSearchSort.recent;

  // Active filters
  String? _selectedDifficulty;
  String? _selectedCost;
  int? _minMinutes; // null = any time

  bool get _hasActiveFilters =>
      _selectedDifficulty != null ||
      _selectedCost != null ||
      _minMinutes != null;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    setState(() {
      _recipesFuture = _recipeService.fetchRecipes();
    });
  }

  List<Recipe> _filterAndSort(List<Recipe> recipes) {
    final filtered = recipes.where((recipe) {
      final matchesQuery =
          _query.isEmpty ||
          recipe.title.toLowerCase().contains(_query) ||
          recipe.ingredients.any((i) => i.name.toLowerCase().contains(_query));

      // Comparación robusta (insensible a mayúsculas/minúsculas, acentos y espacios)
      final matchesDifficulty =
          _selectedDifficulty == null ||
          _normalize(recipe.difficulty) == _normalize(_selectedDifficulty);

      final matchesCost =
          _selectedCost == null ||
          _normalize(recipe.cost) == _normalize(_selectedCost);

      final cookingMinutes = _parseCookingTime(recipe.cookingTime);
      final matchesTime =
          _minMinutes == null ||
          (cookingMinutes != null && cookingMinutes <= _minMinutes!);

      return matchesQuery && matchesDifficulty && matchesCost && matchesTime;
    }).toList();

    if (_selectedSort == RecipeSearchSort.alphabetical) {
      filtered.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  }

  int? _parseCookingTime(String? time) {
    if (time == null) return null;
    final match = RegExp(r'\d+').firstMatch(time);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  String _normalize(String? text) {
    if (text == null) return '';
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? tempDifficulty = _selectedDifficulty;
        String? tempCost = _selectedCost;
        int? tempTime = _minMinutes;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final sheetBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
            final titleColor = isDark ? Colors.white : Colors.black87;
            final labelColor = isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600;

            Widget chipRow(
              String label,
              List<String> options,
              String? selected,
              Function(String?) onTap,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: labelColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...options.map((op) {
                        final sel = selected == op;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => onTap(sel ? null : op)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.nutveSelectionGreen
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.nutveSelectionGreen
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey.shade200),
                              ),
                            ),
                            child: Text(
                              op,
                              style: TextStyle(
                                color: sel
                                    ? Colors.black87
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filtros",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          tempDifficulty = null;
                          tempCost = null;
                          tempTime = null;
                        }),
                        child: const Text(
                          "Limpiar todo",
                          style: TextStyle(
                            color: AppColors.nutveSelectionGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  chipRow(
                    "Dificultad",
                    ["Fácil", "Media", "Difícil"],
                    tempDifficulty,
                    (v) => tempDifficulty = v,
                  ),
                  const SizedBox(height: 20),
                  chipRow(
                    "Costo",
                    ["Bajo", "Medio", "Alto"],
                    tempCost,
                    (v) => tempCost = v,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Tiempo máximo",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: labelColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 45, 60].map((mins) {
                      final sel = tempTime == mins;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => tempTime = sel ? null : mins),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.nutveSelectionGreen
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.nutveSelectionGreen
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            "≤ $mins min",
                            style: TextStyle(
                              color: sel
                                  ? Colors.black87
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nutveSelectionGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDifficulty = tempDifficulty;
                          _selectedCost = tempCost;
                          _minMinutes = tempTime;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Aplicar Filtros",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
      ),
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF52B788)),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(
                    'No se pudieron cargar las recetas.',
                    _loadRecipes,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("No se encontraron recetas.");
                }

                final filteredRecipes = _filterAndSort(snapshot.data!);

                if (filteredRecipes.isEmpty) {
                  return _buildEmptyState("Sin resultados para tu búsqueda.");
                }

                return ListView.builder(
                  itemCount: filteredRecipes.length,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) =>
                      _buildModernRecipeTile(filteredRecipes[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Nombre o ingrediente...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.nutveSelectionGreen,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sort + Filter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Resultados",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              Row(
                children: [
                  // Filter button with active indicator
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.nutveSelectionGreen
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hasActiveFilters
                              ? AppColors.nutveSelectionGreen
                              : (isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _hasActiveFilters
                                ? Colors.black87
                                : (isDark
                                      ? Colors.white70
                                      : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _hasActiveFilters ? "Filtros activos" : "Filtrar",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _hasActiveFilters
                                  ? Colors.black87
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort dropdown
                  DropdownButtonHideUnderline(
                    child: DropdownButton<RecipeSearchSort>(
                      value: _selectedSort,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF1B4332),
                      ),
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1B4332),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(
                          value: RecipeSearchSort.recent,
                          child: Text('Recientes'),
                        ),
                        DropdownMenuItem(
                          value: RecipeSearchSort.alphabetical,
                          child: Text('A - Z'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSort = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernRecipeTile(Recipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(recipe: recipe),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.grey.shade50,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          child: Icon(
                            Icons.image_outlined,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade400,
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        child: Icon(
                          Icons.image_outlined,
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade400,
                          size: 30,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.ingredients.map((i) => i.name).take(3).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            recipe.cookingTime ?? "-- min",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                recipe.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Intentar de nuevo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
