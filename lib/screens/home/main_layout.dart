import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/pantry_controller.dart';
import '../../services/notification_service.dart';
import 'home_screen_content.dart';
import 'search_screen.dart';
import '../Profile/profile_screen.dart';
import '../pantry/pantry_screen.dart';
import '../assistant/assistant_screen.dart';
import '../plan/premium_plan_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Estado de Navegación y Notificaciones
  int _selectedIndex = 2;
  int _notificationCount = 0;

  // Estado del Asistente Mitroglu
  bool _isAiExpanded = false;

  final List<Widget> _screens = [
    const PantryScreen(),
    const PremiumPlanScreen(),
    const HomeScreenContent(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _triggerAiWelcome();
  }

  // --- LÓGICA DE MITROGLU (IA) ---
  void _triggerAiWelcome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isAiExpanded = true);
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() => _isAiExpanded = false);
  }

  // --- LÓGICA DE NOTIFICACIONES (PANTRY) ---
  Future<void> _initNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkExpiringIngredients();
    });
  }

  Future<void> _checkExpiringIngredients() async {
    try {
      if (Get.isRegistered<PantryController>()) {
        final pantryController = Get.find<PantryController>();
        await Future.delayed(const Duration(seconds: 2));
        final notificationService = NotificationService();
        final count = await notificationService
            .checkAndNotifyExpiringIngredients(pantryController.allIngredients);
        if (mounted) setState(() => _notificationCount = count);
      }
    } catch (e) {
      debugPrint('Error verificando notificaciones: $e');
    }
  }

  void _showNotificationsPanel() {
    if (!Get.isRegistered<PantryController>()) {
      Get.snackbar('Info', 'No hay ingredientes cargados');
      return;
    }

    final pantryController = Get.find<PantryController>();
    final expiringIngredients =
        pantryController.allIngredients
            .where(
              (i) =>
                  i.expirationDate != null &&
                  (i.daysUntilExpiration ?? 99) <= 7,
            )
            .toList()
          ..sort(
            (a, b) => (a.daysUntilExpiration ?? 99).compareTo(
              b.daysUntilExpiration ?? 99,
            ),
          );

    setState(() => _notificationCount = 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildNotificationSheet(expiringIngredients),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 75,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Avatar de la App
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
            const SizedBox(width: 12),
            // Burbuja de Mitroglu Animada
            _buildAiBubble(),
          ],
        ),
        actions: [
          // Campana de Notificaciones con Badge
          _buildNotificationIcon(),
          const SizedBox(width: 10),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) async {
          setState(() => _selectedIndex = i);
          if (i == 0) {
            // Al ir al Pantry, refrescar vencimientos
            await Future.delayed(const Duration(milliseconds: 500));
            await _checkExpiringIngredients();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.nutveDarkGreen,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: AppColors.nutveDarkGreen,
              child: Icon(Icons.home, color: Colors.white),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

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
          color: _isAiExpanded ? AppColors.nutveDarkGreen : Colors.white,
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
                  "¡Hola! Soy Mitroglu",
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

  Widget _buildNotificationIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.black,
            size: 28,
          ),
          onPressed: _showNotificationsPanel,
        ),
        if (_notificationCount > 0)
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
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

  Widget _buildNotificationSheet(List expiringIngredients) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.orange),
              const SizedBox(width: 10),
              const Text(
                'Vencimientos Próximos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${expiringIngredients.length} items',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const Divider(),
          if (expiringIngredients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("¡Todo al día!"),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: expiringIngredients.length,
                itemBuilder: (context, index) {
                  final item = expiringIngredients[index];
                  return ListTile(
                    title: Text(item.displayName),
                    subtitle: Text("Vence en ${item.daysUntilExpiration} días"),
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
