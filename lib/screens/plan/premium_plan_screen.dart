import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/premium_controller.dart';
import '../../models/recipe_model.dart';
import '../../models/user_goal_model.dart';
import '../../services/goal_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_colors.dart';
import '../goals/goal_registration_screen.dart';
import '../recipe/recipe_detail_screen.dart';
import '../recipe/widgets/macro_chart_widget.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/guest_view_placeholder.dart';

enum _MealSlot { breakfast, lunch, snack, dinner }

class PremiumPlanScreen extends StatefulWidget {
  final bool showAppBar;
  const PremiumPlanScreen({super.key, this.showAppBar = false});

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
  UserGoalModel? _userGoal;
  int _targetCalories = 2000;
  bool _loadingPlan = false;
  bool _isChecking = false;
  String? _errorMessage;
  String _selectedPaymentMethod = 'Tarjeta';

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
    try {
      if (!mounted) return;
      setState(() {
        _loadingPlan = true;
        _isChecking = true;
        _errorMessage = null;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final goal = await _goalService.getUserGoals(userId);
        if (goal != null) {
          _userGoal = goal;
          _targetCalories = goal.targetCalories.round();
        } else {
          _userGoal = null;
          _targetCalories = 2000;
        }
      }

      // Añadimos timeout global de 15 segundos para la carga de recetas
      _recipes = await _recipeService.fetchRecipes().timeout(
        const Duration(seconds: 15),
      );

      if (mounted) _generateWeeklyPlan();
    } catch (e) {
      debugPrint('Error en _loadGoalAndGenerate: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'No pudimos cargar tu plan. Revisa tu conexión a internet.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlan = false;
          _isChecking = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (!AuthController().hasSession()) {
      return Scaffold(
        appBar: widget.showAppBar ? _simpleAppBar(context) : null,
        body: const GuestViewPlaceholder(
          title: "Planes Nutricionales",
          description:
              "Inicia sesión para ver tu plan de dieta y, si quieres, activar Premium para exportarlo en PDF y obtener beneficios extra.",
          icon: Icons.auto_awesome_mosaic_outlined,
        ),
      );
    }

    final premium = context.watch<PremiumController>();

    final untilText = premium.premiumUntil == null
        ? 'No activo'
        : '${premium.premiumUntil!.day}/${premium.premiumUntil!.month}/${premium.premiumUntil!.year}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar ? _simpleAppBar(context) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMembershipSection(premium, untilText),
            const SizedBox(height: 16),
            _buildPlanSeparationCard(),
            const SizedBox(height: 16),
            _buildDietProfileCard(),
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
            ] else if (_errorMessage != null) ...[
              const SizedBox(height: 60),
              _buildErrorState(_errorMessage!, _loadGoalAndGenerate),
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

  Future<void> _openGoalRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalRegistrationScreen()),
    );
    if (!mounted) {
      return;
    }
    await _loadGoalAndGenerate();
  }

  Future<void> _handlePremiumSubscription() async {
    final premium = context.read<PremiumController>();
    final success = await premium.subscribeMonthly();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          premium.lastMessage ??
              (success
                  ? 'Premium activado correctamente.'
                  : 'No se pudo procesar el pago.'),
        ),
        backgroundColor: success
            ? AppColors.nutveSelectionGreen
            : Colors.redAccent,
      ),
    );

    if (success) {
      await _loadGoalAndGenerate();
    }
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
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

  Widget _buildMembershipSection(PremiumController premium, String untilText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentMethods = ['Tarjeta', 'Pago móvil', 'PayPal'];

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
              const Text(
                'Premium Kooki',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            premium.isPremium
                ? 'Tu membresía está activa hasta: $untilText'
                : 'Premium desbloquea la exportación PDF del plan semanal y otros beneficios de apoyo.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _BenefitChip(icon: Icons.download_outlined, label: 'PDF semanal'),
              _BenefitChip(
                icon: Icons.auto_awesome_rounded,
                label: 'Extras premium',
              ),
              _BenefitChip(
                icon: Icons.support_agent_outlined,
                label: 'Soporte',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (premium.isPremium) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado de la membresía',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activa hasta el $untilText',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Renovación automática',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Switch(
                        value: premium.autoRenewEnabled,
                        activeThumbColor: Colors.amber,
                        onChanged: (value) => context
                            .read<PremiumController>()
                            .setAutoRenew(value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Método de pago',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: paymentMethods.map((method) {
                return ChoiceChip(
                  label: Text(method),
                  selected: _selectedPaymentMethod == method,
                  onSelected: (_) {
                    setState(() => _selectedPaymentMethod = method);
                  },
                  selectedColor: Colors.amber,
                  labelStyle: TextStyle(
                    color: _selectedPaymentMethod == method
                        ? Colors.black
                        : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _selectedPaymentMethod == method
                        ? Colors.amber
                        : Colors.white24,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.08),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: premium.isLoading
                    ? null
                    : _handlePremiumSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: premium.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(
                  premium.isLoading
                      ? 'Procesando pago...'
                      : 'Activar Premium por \$9.99',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo local: el método seleccionado se usa para simular el cobro y validar el flujo premium.',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanSeparationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark ? Colors.white70 : AppColors.nutveDarkGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu perfil nutricional define calorías, macros y enfoque de dieta. Premium es aparte: solo suma beneficios como PDF y soporte.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietProfileCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goal = _userGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: isDark
                    ? AppColors.nutveSelectionGreen
                    : AppColors.nutveDarkGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resumen nutricional',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openGoalRegistration,
                icon: const Icon(Icons.edit_outlined),
                label: Text(goal == null ? 'Configurar' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (goal == null) ...[
            Text(
              'Aún no has configurado tus metas. Puedes generar un plan base y luego completar tu perfil para personalizarlo de verdad.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _openGoalRegistration,
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: const Text('Completar perfil nutricional'),
            ),
          ] else ...[
            MacroChartWidget(goal: goal),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GoalMetricChip(
                  icon: Icons.local_fire_department_outlined,
                  label: '${goal.targetCalories.toStringAsFixed(0)} kcal/día',
                ),
                _GoalMetricChip(
                  icon: Icons.flag_outlined,
                  label: _goalTypeLabel(goal.goalType),
                ),
                _GoalMetricChip(
                  icon: Icons.monitor_weight_outlined,
                  label: '${goal.currentWeight.toStringAsFixed(0)} kg',
                ),
                _GoalMetricChip(
                  icon: Icons.height_outlined,
                  label: '${goal.height.toStringAsFixed(0)} cm',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
            _userGoal == null
                ? 'Plan base activo: $_targetCalories kcal por día'
                : 'Objetivo diario según tu perfil: $_targetCalories kcal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _userGoal == null
                ? 'Completa tu perfil nutricional para que el plan deje de usar un valor de referencia.'
                : 'Tu dieta real se basa en las metas registradas en tu perfil.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openGoalRegistration,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    _userGoal == null
                        ? 'Configurar perfil'
                        : 'Actualizar perfil',
                  ),
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

  String _goalTypeLabel(String goalType) {
    switch (goalType) {
      case 'lose':
        return 'Bajar de peso';
      case 'gain':
        return 'Subir de peso';
      case 'maintain':
        return 'Mantener peso';
      default:
        return 'Meta personalizada';
    }
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  PreferredSizeWidget _simpleAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GoalMetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? AppColors.nutveSelectionGreen
                : AppColors.nutveDarkGreen,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
