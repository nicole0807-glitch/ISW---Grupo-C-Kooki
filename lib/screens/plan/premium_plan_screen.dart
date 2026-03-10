import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/premium_controller.dart';
import '../../models/recipe_model.dart';
import '../../services/goal_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_colors.dart';
import '../recipe/recipe_detail_screen.dart';

enum _MealSlot { breakfast, lunch, snack, dinner }

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  final RecipeService _recipeService = RecipeService();
  final GoalService _goalService = GoalService();

  final Map<DateTime, Map<_MealSlot, Recipe?>> _weeklyPlan = {};

  late DateTime _weekStart;
  late List<DateTime> _weekDays;
  late DateTime _selectedDay;

  List<Recipe> _recipes = [];
  int _targetCalories = 2000;
  bool _loadingPlan = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final premium = context.read<PremiumController>();
      await premium.loadStatus();
      if (!mounted) {
        return;
      }
      // Bypassing isPremium check to allow free access as requested by user
      await _loadGoalAndGenerate();
    });
  }

  void _initializeWeek() {
    final now = DateTime.now();
    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(
      7,
      (index) => _weekStart.add(Duration(days: index)),
    );
    _selectedDay = _weekDays.first;
  }

  Future<void> _loadGoalAndGenerate() async {
    if (!mounted || _isChecking) return;
    setState(() {
      _loadingPlan = true;
      _isChecking = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final goal = await _goalService.getUserGoals(userId);
        if (goal != null) {
          _targetCalories = goal.targetCalories.round();
        }
      }

      // Añadimos timeout global de 15 segundos para la carga de recetas
      _recipes = await _recipeService.fetchRecipes().timeout(
        const Duration(seconds: 15),
      );

      _generateWeeklyPlan();
    } catch (e) {
      debugPrint('Error en _loadGoalAndGenerate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el plan: $e'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed:
                  _loadGoalAndGenerate, // Reverted to original as _showReportDialog is not defined and 'AndGenerate' is invalid syntax.
            ),
          ),
        );
      }
    } finally {
      _loadingPlan = false;
      _isChecking = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _generateWeeklyPlan() {
    if (_recipes.isEmpty) {
      return;
    }

    _weeklyPlan.clear();

    final breakfastTarget = _targetCalories * 0.25;
    final lunchTarget = _targetCalories * 0.35;
    final snackTarget = _targetCalories * 0.10;
    final dinnerTarget = _targetCalories * 0.30;

    for (var i = 0; i < _weekDays.length; i++) {
      final day = _weekDays[i];
      final rng = Random(day.millisecondsSinceEpoch);

      _weeklyPlan[day] = {
        _MealSlot.breakfast: _pickRecipeNearCalories(breakfastTarget, rng),
        _MealSlot.lunch: _pickRecipeNearCalories(lunchTarget, rng),
        _MealSlot.snack: rng.nextBool()
            ? _pickRecipeNearCalories(snackTarget, rng)
            : null, // merienda opcional
        _MealSlot.dinner: _pickRecipeNearCalories(dinnerTarget, rng),
      };
    }

    setState(() {});
  }

  Recipe? _pickRecipeNearCalories(double target, Random rng) {
    if (_recipes.isEmpty) {
      return null;
    }

    final sorted = [..._recipes]
      ..sort(
        (a, b) => (_extractCalories(a) - target).abs().compareTo(
          (_extractCalories(b) - target).abs(),
        ),
      );

    final top = sorted.take(min(8, sorted.length)).toList();
    return top[rng.nextInt(top.length)];
  }

  double _extractCalories(Recipe recipe) {
    final n = recipe.nutrition;
    final keys = ['calories', 'kcal', 'energy_kcal', 'cal'];

    for (final key in keys) {
      final value = n[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 450.0;
  }

  Future<void> _editTargetCalories() async {
    final ctrl = TextEditingController(text: _targetCalories.toString());

    final newValue = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar objetivo calórico'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ej: 2000',
            labelText: 'Calorías objetivo / día',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              Navigator.pop(context, parsed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newValue != null && newValue > 0) {
      setState(() => _targetCalories = newValue);
      _generateWeeklyPlan();
    }
  }

  Future<void> _replaceMeal(DateTime day, _MealSlot slot) async {
    if (_recipes.isEmpty) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return ListTile(
                  title: Text(recipe.title),
                  subtitle: Text('${_extractCalories(recipe).round()} kcal'),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () {
                    setState(() {
                      _weeklyPlan[day]?[slot] = recipe;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool get _hasWeeklyPlan =>
      _weeklyPlan.isNotEmpty &&
      _weeklyPlan.values.any(
        (meals) => meals.values.any((recipe) => recipe != null),
      );

  Future<void> _exportWeeklyPlanPdf() async {
    final premium = context.read<PremiumController>();
    if (!premium.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitas membresía premium activa para exportar el plan.',
          ),
        ),
      );
      return;
    }

    if (!_hasWeeklyPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero debes generar un plan semanal para exportarlo.',
          ),
        ),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text(
              'Plan nutricional semanal',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Objetivo diario: $_targetCalories kcal'),
            pw.SizedBox(height: 16),
            ..._weekDays.map((day) {
              final meals = _weeklyPlan[day] ?? {};
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${_weekdayLabel(day.weekday)} ${day.day}/${day.month}/${day.year}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    ..._MealSlot.values.map((slot) {
                      final recipe = meals[slot];
                      final label = _slotLabel(slot);
                      final recipeText = recipe == null
                          ? 'Sin asignar'
                          : '${recipe.title} (${_extractCalories(recipe).round()} kcal)';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text('• $label: $recipeText'),
                      );
                    }),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveAndSharePdf(bytes);
  }

  Future<void> _saveAndSharePdf(Uint8List bytes) async {
    final now = DateTime.now();
    final filename =
        'plan_semanal_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: filename);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generado correctamente.')),
    );
  }

  bool _hasPaid = false; // Mock payment status

  void _onMockPay() {
    setState(() {
      _hasPaid = true;
    });
    _loadGoalAndGenerate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPaid) {
      return _buildMockPaymentGate();
    }

    final premium = context.watch<PremiumController>();

    final untilText = premium.premiumUntil == null
        ? 'No activo'
        : '${premium.premiumUntil!.day}/${premium.premiumUntil!.month}/${premium.premiumUntil!.year}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(premium.isPremium, untilText),
            const SizedBox(height: 16),
            if (_loadingPlan) ...[
              const SizedBox(height: 100),
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.nutveDarkGreen,
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('Cargando tu plan personalizado...')),
            ] else ...[
              _plannerControls(context),
              const SizedBox(height: 16),
              _weekCalendar(),
              const SizedBox(height: 16),
              _dayMeals(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(bool isPremium, String untilText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                isPremium ? 'Premium Activo' : 'Plan Premium',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? 'Tu membresía está activa hasta: $untilText'
                : 'Suscríbete para generar tu plan semanal automático.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // Removed old _paymentBox and _payButton - replaced by _PaymentFormSection

  Widget _plannerControls(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objetivo diario: $_targetCalories kcal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editTargetCalories,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar calorías'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nutveDarkGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _loadingPlan ? null : _loadGoalAndGenerate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Regenerar plan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportWeeklyPlanPdf,
              icon: const Icon(Icons.download),
              label: const Text('Descargar recetas de la semana (PDF)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekCalendar() {
    if (_loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semana actual',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _weekDays.map((day) {
              final selected = _isSameDate(day, _selectedDay);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    '${_weekdayLabel(day.weekday)} ${day.day}/${day.month}',
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDay = day),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dayMeals(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayPlan = _weeklyPlan[_selectedDay];

    if (dayPlan == null) {
      return const Text('No hay plan para este día todavía.');
    }

    final slots = [
      _MealSlot.breakfast,
      _MealSlot.lunch,
      _MealSlot.snack,
      _MealSlot.dinner,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comidas del ${_selectedDay.day}/${_selectedDay.month}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...slots.map((slot) {
          final recipe = dayPlan[slot];
          return Card(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            child: ListTile(
              title: Text(_slotLabel(slot)),
              subtitle: Text(
                recipe == null
                    ? 'Sin asignar'
                    : '${recipe.title} • ${_extractCalories(recipe).round()} kcal',
              ),
              leading: const Icon(Icons.restaurant_menu),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Cambiar comida',
                    onPressed: () => _replaceMeal(_selectedDay, slot),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  IconButton(
                    tooltip: 'Ver receta',
                    onPressed: recipe == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              onTap: recipe == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
            ),
          );
        }),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mie';
      case DateTime.thursday:
        return 'Jue';
      case DateTime.friday:
        return 'Vie';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '-';
    }
  }

  String _slotLabel(_MealSlot slot) {
    switch (slot) {
      case _MealSlot.breakfast:
        return 'Desayuno';
      case _MealSlot.lunch:
        return 'Almuerzo';
      case _MealSlot.snack:
        return 'Merienda (opcional)';
      case _MealSlot.dinner:
        return 'Cena';
    }
  }

  Widget _buildMockPaymentGate() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Plan Premium Kooki',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Obtén acceso a planes nutricionales personalizados, exportación a PDF y más.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                      '\$9.99 / mes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.nutveDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nutveDarkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _onMockPay,
                        child: const Text(
                          'Pagar Membresía',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pago ficticio para fines de demostración',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ──────────────────────────────────────────────
// Realistic Payment Form Widget
