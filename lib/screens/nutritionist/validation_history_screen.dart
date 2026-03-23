import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_validation_service.dart';
import 'widgets/history_recipe_card.dart';

class ValidationHistoryScreen extends StatefulWidget {
  const ValidationHistoryScreen({super.key});

  @override
  State<ValidationHistoryScreen> createState() =>
      _ValidationHistoryScreenState();
}

class _ValidationHistoryScreenState extends State<ValidationHistoryScreen> {
  final RecipeValidationService _service = RecipeValidationService();
  String _searchQuery = "";
  String _activeFilter = "Todas";

  final List<String> _filters = [
    "Todas",
    "Aprobadas",
    "Rechazadas",
    "Últimos 30 Días",
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF102216)
        : const Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            _buildFilters(),
            Expanded(child: _buildHistoryList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC5B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Color(0xFF13EC5B)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Historial de Validaciones",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "Revisa tus auditorías de recetas",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: "Buscar por título o autor...",
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF13EC5B)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter;

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filter == "Aprobadas") _buildDot(const Color(0xFF10B981)),
                if (filter == "Rechazadas") _buildDot(const Color(0xFFF43F5E)),
                if (filter == "Últimos 30 Días")
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                if (filter == "Last 30 Days") const SizedBox(width: 4),
                Text(
                  filter,
                  style: TextStyle(
                    color: isActive
                        ? Colors.black
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (filter == "Últimos 30 Días")
                  const Icon(Icons.expand_more, size: 14, color: Colors.grey),
              ],
            ),
            selected: isActive,
            onSelected: (val) => setState(
              () => _activeFilter = filter,
            ), // rebuild dispara nuevo FutureBuilder
            backgroundColor: Colors.transparent,
            selectedColor: const Color(0xFF13EC5B),
            checkmarkColor: Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: isActive ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Mapea el filtro activo al valor de status en Supabase
  String? get _statusFilterValue {
    switch (_activeFilter) {
      case 'Aprobadas':
        return 'aprobado';
      case 'Rechazadas':
        return 'rechazado';
      default:
        return null;
    }
  }

  Widget _buildHistoryList(bool isDark) {
    return FutureBuilder<List<Recipe>>(
      future: _service.fetchValidatedRecipes(statusFilter: _statusFilterValue),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF13EC5B)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading history: ${snapshot.error}"),
          );
        }

        final recipes = (snapshot.data ?? [])
            .where(
              (r) => r.title.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

        if (recipes.isEmpty) {
          return const Center(child: Text("No se encontraron registros"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return HistoryRecipeCard(recipe: recipe, onTap: () {});
          },
        );
      },
    );
  }
}
