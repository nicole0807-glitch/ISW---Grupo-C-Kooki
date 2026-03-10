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
      if (premium.isPremium) {
        await _loadGoalAndGenerate();
      }
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
              onPressed: _loadGoalAndGenerate,
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
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
            if (!premium.isPremium) ...[
              _benefit('Plan semanal automático basado en metas/calorías'),
              _benefit('Edición y reemplazo manual de comidas'),
              _benefit('Calendario interactivo con recetas por día'),
              const SizedBox(height: 20),
              _PaymentFormSection(onSuccess: _loadGoalAndGenerate),
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.nutveSelectionGreen),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Realistic Payment Form Widget
// ──────────────────────────────────────────────
class _PaymentFormSection extends StatefulWidget {
  final Future<void> Function() onSuccess;
  const _PaymentFormSection({required this.onSuccess});

  @override
  State<_PaymentFormSection> createState() => _PaymentFormSectionState();
}

class _PaymentFormSectionState extends State<_PaymentFormSection> {
  final _cardNumberCtrl = TextEditingController(text: '');
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _isProcessing = false;
  String _selectedMethod = 'Visa';
  final List<String> _methods = ['Visa', 'Mastercard', 'AMEX'];

  String get _maskedNumber {
    final raw = _cardNumberCtrl.text.replaceAll(' ', '');
    if (raw.isEmpty) return '**** **** **** ****';
    // Show last 4 digits, mask the rest
    final padded = raw.padRight(16, '*');
    final masked = '**** **** **** ${padded.substring(12, 16)}';
    return masked;
  }

  void _formatCardNumber(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 16));
    final formatted = limited.replaceAllMapped(
      RegExp(r'.{4}'),
      (m) => '${m.group(0)} ',
    );
    if (formatted.trimRight() != val.trimRight()) {
      _cardNumberCtrl.value = TextEditingValue(
        text: formatted.trimRight(),
        selection: TextSelection.collapsed(
          offset: formatted.trimRight().length,
        ),
      );
    }
    setState(() {});
  }

  void _formatExpiry(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;
    if (digits.length > 2) {
      formatted =
          '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
    }
    if (formatted != val) {
      _expiryCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  Future<void> _handlePay() async {
    // Only require name + some number entered (allows fictitious/demo numbers)
    if (_cardNameCtrl.text.trim().isEmpty ||
        _cardNumberCtrl.text.replaceAll(' ', '').length < 4) {
      _showPayError(
        'Por favor ingresa el número de tarjeta y el nombre del titular.',
      );
      return;
    }
    if (_expiryCtrl.text.isEmpty) {
      _showPayError('Ingresa la fecha de vencimiento de tu tarjeta.');
      return;
    }
    if (_cvvCtrl.text.isEmpty) {
      _showPayError('Ingresa el código de seguridad (CVV).');
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final premium = context.read<PremiumController>();
    final success = await premium.subscribeMonthly();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!success) {
      _showPayError(premium.lastMessage ?? 'Error al procesar el pago.');
      return;
    }

    await widget.onSuccess();

    // Show realistic dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF1B4332)),
            SizedBox(width: 8),
            Text('Pago en Revisión'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu solicitud fue registrada correctamente.\n\nLa pasarela de pago estará habilitada muy pronto para completar la transacción de forma segura.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14),
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 40,
              color: Color(0xFF2D6A4F),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showPayError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Credit Card Preview ──
        Container(
          width: double.infinity,
          height: 195,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF0D6A3B), Color(0xFF0A2E1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4332).withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedMethod,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.wifi_rounded,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _maskedNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TITULAR',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        Text(
                          _cardNameCtrl.text.isEmpty
                              ? 'NOMBRE APELLIDO'
                              : _cardNameCtrl.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VENCE',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        Text(
                          _expiryCtrl.text.isEmpty ? 'MM/AA' : _expiryCtrl.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Price summary ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B4332).withOpacity(0.2)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.nutveSelectionGreen.withOpacity(0.3)
                  : Colors.green.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plan Premium mensual',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'USD 9.99',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: isDark
                          ? AppColors.nutveSelectionGreen
                          : const Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Payment method selector ──
        Text(
          'Tarjeta de pago',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _methods.map((m) {
            final sel = _selectedMethod == m;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedMethod = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF1B4332) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF1B4332)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    m,
                    style: TextStyle(
                      color: sel
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Card Number ──
        _payField(
          'Número de tarjeta',
          _cardNumberCtrl,
          hint: '1234 5678 9012 3456',
          icon: Icons.credit_card_rounded,
          isDark: isDark,
          onChanged: _formatCardNumber,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _payField(
          'Titular de la tarjeta',
          _cardNameCtrl,
          hint: 'Nombre como aparece en la tarjeta',
          icon: Icons.person_rounded,
          isDark: isDark,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _payField(
                'Vencimiento',
                _expiryCtrl,
                hint: 'MM/AA',
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
                onChanged: _formatExpiry,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _payField(
                'CVV',
                _cvvCtrl,
                hint: '•••',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                onChanged: (_) {},
                keyboardType: TextInputType.number,
                obscure: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Pay Button ──
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            onPressed: _isProcessing ? null : _handlePay,
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Procesando...'),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Pagar USD 9.99',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Pago seguro con cifrado SSL de 256 bits',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _payField(
    String label,
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
    required bool isDark,
    required void Function(String) onChanged,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.shade50,
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
          borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
