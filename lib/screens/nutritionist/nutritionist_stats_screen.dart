import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/nutritionist_stats_model.dart';
import '../../services/recipe_validation_service.dart';

class NutritionistStatsScreen extends StatefulWidget {
  const NutritionistStatsScreen({super.key});

  @override
  State<NutritionistStatsScreen> createState() =>
      _NutritionistStatsScreenState();
}

class _NutritionistStatsScreenState extends State<NutritionistStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _entryAnim;

  static const Color _primary = Color(0xFF13EC5B);

  final RecipeValidationService _service = RecipeValidationService();
  late Future<NutritionistStats> _statsFuture;

  static const List<String> _dayLabels = [
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
    'DOM',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _statsFuture = _service.fetchStatsForCurrentNutritionist();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _statsFuture = _service.fetchStatsForCurrentNutritionist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1B12)
          : const Color(0xFFF6F8F6),
      body: FutureBuilder<NutritionistStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar estadísticas:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;

          // Disparar animación al recibir datos
          _animController.forward(from: 0);

          return CustomScrollView(
            slivers: [
              _buildAppBar(isDark),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryGrid(stats, isDark),
                    const SizedBox(height: 20),
                    _buildApprovalSection(stats, isDark),
                    const SizedBox(height: 20),
                    _buildWeeklyChart(stats, isDark),
                    const SizedBox(height: 20),
                    _buildTipCard(stats, isDark),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF102216).withOpacity(0.95)
          : Colors.white.withOpacity(0.95),
      title: Text(
        'Estadísticas',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: _reload,
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  // ─── Summary Grid ─────────────────────────────────────────────────────────────

  Widget _buildSummaryGrid(NutritionistStats stats, bool isDark) {
    // Formatear total con separador de miles
    final String totalStr = stats.totalValidated >= 1000
        ? '${stats.totalValidated ~/ 1000},${(stats.totalValidated % 1000).toString().padLeft(3, '0')}'
        : stats.totalValidated.toString();

    // Porcentaje de aprobación para mostrar como tendencia
    final int approvalPct = (stats.approvalRatio * 100).round();

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Validadas',
            value: totalStr,
            trend: '$approvalPct% aprob.',
            trendUp: approvalPct >= 50,
            isDark: isDark,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.cancel_outlined,
            label: 'Rechazadas',
            value: stats.rejected.toString(),
            trend: '${100 - approvalPct}% rechazo',
            trendUp: false,
            isDark: isDark,
            highlighted: false,
          ),
        ),
      ],
    );
  }

  // ─── Approval Ratio ───────────────────────────────────────────────────────────

  Widget _buildApprovalSection(NutritionistStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasa de Aprobación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Todas tus validaciones',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${stats.totalValidated} total',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut
              AnimatedBuilder(
                animation: _entryAnim,
                builder: (_, __) => _DonutChart(
                  ratio: stats.approvalRatio * _entryAnim.value,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildRatioRow(
                      label: 'Aprobadas',
                      count: stats.approved.toString(),
                      ratio: stats.totalValidated == 0
                          ? 0
                          : stats.approved / stats.totalValidated,
                      color: _primary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildRatioRow(
                      label: 'Rechazadas',
                      count: stats.rejected.toString(),
                      ratio: stats.totalValidated == 0
                          ? 0
                          : stats.rejected / stats.totalValidated,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioRow({
    required String label,
    required String count,
    required double ratio,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _entryAnim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio * _entryAnim.value,
                    backgroundColor: isDark
                        ? Colors.white12
                        : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Weekly Chart ─────────────────────────────────────────────────────────────

  Widget _buildWeeklyChart(NutritionistStats stats, bool isDark) {
    final int maxCount = stats.weekMax;
    final int todayIndex = DateTime.now().weekday - 1; // 0=lun

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actividad Semanal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Esta semana',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = stats.weekdayCounts[i];
                final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                final isToday = i == todayIndex;
                return _buildBar(
                  label: _dayLabels[i],
                  ratio: ratio.toDouble(),
                  count: count,
                  isToday: isToday,
                  isDark: isDark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required double ratio,
    required int count,
    required bool isToday,
    required bool isDark,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedBuilder(
          animation: _entryAnim,
          builder: (_, __) {
            final displayRatio = (ratio * _entryAnim.value).clamp(0.0, 1.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Conteo encima de la barra
                Text(
                  count > 0 ? count.toString() : '',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? _primary
                        : isDark
                        ? Colors.white38
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: displayRatio == 0 ? 0.04 : displayRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? _primary
                              : _primary.withOpacity(isDark ? 0.35 : 0.25),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? _primary
                        : isDark
                        ? Colors.white38
                        : Colors.grey.shade400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Tip Card ─────────────────────────────────────────────────────────────────

  Widget _buildTipCard(NutritionistStats stats, bool isDark) {
    // Calcular el día más productivo
    String tip;
    if (stats.totalValidated == 0) {
      tip =
          '¡Todavía no tienes validaciones registradas esta semana. ¡Empieza hoy!';
    } else {
      final maxIdx = stats.weekdayCounts
          .asMap()
          .entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      final bestDay = _dayLabels[maxIdx];
      final pct = (stats.approvalRatio * 100).round();
      tip =
          'Tu día más productivo es el ${_fullDay(bestDay)}. Tasa de aprobación: $pct%.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A22) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de tu actividad',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fullDay(String abbr) {
    const map = {
      'LUN': 'lunes',
      'MAR': 'martes',
      'MIÉ': 'miércoles',
      'JUE': 'jueves',
      'VIE': 'viernes',
      'SÁB': 'sábado',
      'DOM': 'domingo',
    };
    return map[abbr] ?? abbr;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF1A2820) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final bool isDark;
  final bool highlighted;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.isDark,
    required this.highlighted,
  });

  static const Color _primary = Color(0xFF13EC5B);

  @override
  Widget build(BuildContext context) {
    final Color borderColor = highlighted
        ? _primary.withOpacity(0.25)
        : (isDark ? Colors.white10 : Colors.grey.shade100);
    final Color bgColor = highlighted
        ? _primary.withOpacity(0.05)
        : (isDark ? const Color(0xFF1A2820) : Colors.white);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: highlighted ? _primary : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: trendUp ? _primary : Colors.red.shade400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendUp ? _primary : Colors.red.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Donut Chart ──────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final double ratio;
  final bool isDark;

  const _DonutChart({required this.ratio, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _DonutPainter(ratio: ratio, isDark: isDark),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'APROBACIÓN',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double ratio;
  final bool isDark;

  const _DonutPainter({required this.ratio, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 12;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.grey.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (ratio <= 0) return;

    final fgPaint = Paint()
      ..color = const Color(0xFF13EC5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * ratio, false, fgPaint);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.ratio != ratio || old.isDark != isDark;
}
