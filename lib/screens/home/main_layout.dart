import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/notification_service.dart';
import 'home_screen_content.dart';
import 'search_screen.dart';
import '../Profile/profile_screen.dart';
import '../pantry/pantry_screen.dart';
import '../assistant/assistant_screen.dart';
import '../plan/premium_plan_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── DATA CLASS PARA ITEMS DE NAV ─────────────────────────────────────────────
class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ─── WIDGET PRINCIPAL ──────────────────────────────────────────────────────────
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  MainLayoutState createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 2;
  int _notificationCount = 0;
  bool _isAiExpanded = false;

  // Guided Tour State
  bool _showTour = false;
  int _tourStep = 0;

  final List<Map<String, dynamic>> _tourSteps = [
    {
      'index': 2,
      'text':
          '¡Hola! Soy tu Maestro Nutricionista. Bienvenido a Kooki. Aquí en el Inicio verás recetas sugeridas y lo que publica la comunidad.',
      'image': 'assets/Mitroglu1.png',
    },
    {
      'index': 3,
      'text':
          'Usa el buscador para encontrar recetas increíbles por ingredientes o categorías. ¡Explora nuevos sabores!',
      'image': 'assets/Mitroglu3.png',
    },
    {
      'index': 1,
      'text':
          'Aquí puedes gestionar tu calendario nutricional y acceder a tus planes premium. ¡Organiza tu semana!',
      'image': 'assets/Mitroglu1.png',
    },
    {
      'index': 0,
      'text':
          '¡Mi sección favorita! Registra lo que tienes en tu despensa y te avisaré antes de que tus ingredientes caduquen.',
      'image': 'assets/Mitroglu3.png',
    },
    {
      'index': 4,
      'text':
          'Finalmente, aquí puedes personalizar tus metas, alergias y revisar todas tus recetas guardadas.',
      'image': 'assets/Mitroglu1.png',
    },
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.kitchen_rounded, Icons.kitchen_outlined, 'Despensa'),
    _NavItem(
      Icons.calendar_today_rounded,
      Icons.calendar_today_outlined,
      'Plan',
    ),
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Inicio'),
    _NavItem(Icons.explore_rounded, Icons.explore_outlined, 'Explorar'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Perfil'),
  ];

  final List<Widget> _screens = const [
    PantryScreen(),
    PremiumPlanScreen(),
    HomeScreenContent(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _triggerAiWelcome();
    // Tour no longer starts automatically in initState
  }

  void startManualTour() {
    setState(() {
      _showTour = true;
      _tourStep = 0;
      _selectedIndex = _tourSteps[0]['index'];
    });
  }

  /// Navigate directly to the Plan (Premium) tab
  void navigateToPlan() {
    setState(() => _selectedIndex = 1);
  }

  void _nextTourStep() {
    setState(() {
      if (_tourStep < _tourSteps.length - 1) {
        _tourStep++;
        _selectedIndex = _tourSteps[_tourStep]['index'];
      } else {
        _finishTour();
      }
    });
  }

  Future<void> _finishTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    setState(() {
      _showTour = false;
      _tourStep = 0;
    });
  }

  void _triggerAiWelcome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isAiExpanded = true);
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _isAiExpanded = false);
  }

  Future<void> _initNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<PantryController>()) {
        final pantryController = Get.find<PantryController>();
        if (!pantryController.isLoading.value) {
          _checkExpiringIngredients();
        }
        ever(pantryController.isLoading, (bool isLoading) {
          if (!isLoading) {
            _checkExpiringIngredients();
          }
        });
      }
    });
  }

  Future<void> _checkExpiringIngredients() async {
    try {
      if (Get.isRegistered<PantryController>()) {
        final pantryController = Get.find<PantryController>();
        final notificationService = NotificationService();
        final count = await notificationService
            .checkAndNotifyExpiringIngredients(pantryController.allIngredients);
        if (mounted) setState(() => _notificationCount = count);
      }
    } catch (e) {
      debugPrint('Error verificando notificaciones: $e');
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final isDark = themeCtrl.isDarkMode;
    final navBg = isDark ? const Color(0xFF1A2A1D) : AppColors.nutveDarkGreen;

    return Scaffold(
      extendBody: false,
      appBar: _buildAppBar(themeCtrl, isDark),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_showTour) _buildTourOverlay(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(navBg, isDark),
    );
  }

  Widget _buildTourOverlay() {
    final step = _tourSteps[_tourStep];
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Stack(
        children: [
          // Personaje (Maestro Nutricionista)
          Positioned(
            right: -50,
            bottom: 0,
            child: Image.asset(step['image'], height: 450, fit: BoxFit.contain),
          ),

          // Burbuja de diálogo
          Positioned(
            left: 20,
            right: 120,
            bottom: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        step['text'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.nutveDarkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _finishTour,
                            child: const Text(
                              'Saltar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _nextTourStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.nutveDarkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              _tourStep == _tourSteps.length - 1
                                  ? '¡Finalizar!'
                                  : 'Siguiente',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Triangulito de la burbuja
                Padding(
                  padding: const EdgeInsets.only(left: 150),
                  child: ClipPath(
                    clipper: _BubbleClipper(),
                    child: Container(
                      width: 20,
                      height: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeController themeCtrl, bool isDark) {
    return AppBar(
      backgroundColor:
          Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/logo.png'),
          ),
          const SizedBox(width: 12),
          _buildAiBubble(),
        ],
      ),
      actions: [
        // ── Toggle Modo Oscuro (tipo switch animado) ────────────────────
        Tooltip(
          message: isDark ? 'Modo claro' : 'Modo oscuro',
          child: GestureDetector(
            onTap: () => themeCtrl.toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.nutveSelectionGreen.withOpacity(0.85)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Íconos de fondo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.amber.shade700,
                      ),
                      Icon(
                        Icons.dark_mode_rounded,
                        size: 14,
                        color: isDark ? Colors.white : Colors.grey.shade500,
                      ),
                    ],
                  ),
                  // Círculo deslizante
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: isDark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.nutveSelectionGreen
                            : Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Campana de Notificaciones ──────────────────────────────────
        _buildNotificationIcon(),
        const SizedBox(width: 6),
      ],
    );
  }

  // ─── BARRA DE NAV INFERIOR ────────────────────────────────────────────────
  Widget _buildNavBar(Color navBg, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.nutveDarkGreen.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) => _buildNavItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];
    const selectedColor = AppColors.nutveSelectionGreen;
    final unselectedColor = Colors.white.withOpacity(0.55);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Píldora con icono
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.nutveSelectionGreen.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  size: isSelected ? 26 : 22,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BURBUJA IA ────────────────────────────────────────────────────────────
  Widget _buildAiBubble() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssistantScreen()),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
        height: 45,
        width: _isAiExpanded ? 180 : 45,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _isAiExpanded
              ? AppColors.nutveDarkGreen
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.nutveSelectionGreen, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 33,
              height: 33,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/Mitroglu1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_isAiExpanded) ...[
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '¡Hola! Soy Mitroglu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── ÍCONO NOTIFICACIONES ─────────────────────────────────────────────────
  Widget _buildNotificationIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Theme.of(context).iconTheme.color,
            size: 28,
          ),
          onPressed: () {
            // Reset local notification count
            setState(() => _notificationCount = 0);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        if (_notificationCount > 0)
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_notificationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ─── PANEL DE NOTIFICACIONES ──────────────────────────────────────────────
}

class _BubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
