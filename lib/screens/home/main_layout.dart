import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
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
  int _selectedIndex = 2;
  int _notificationCount = 0; // Badge contador

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
  }

  // Inicializar notificaciones y verificar ingredientes
  Future<void> _initNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Esperar a que el PantryController esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkExpiringIngredients();
    });
  }

  // Verificar ingredientes y actualizar badge
  Future<void> _checkExpiringIngredients() async {
    try {
      // Intentar obtener el controlador si ya fue registrado
      if (Get.isRegistered<PantryController>()) {
        final pantryController = Get.find<PantryController>();

        // Esperar a que carguen los ingredientes
        await Future.delayed(const Duration(seconds: 2));

        final notificationService = NotificationService();
        final count = await notificationService
            .checkAndNotifyExpiringIngredients(
                pantryController.allIngredients);

        if (mounted) {
          setState(() => _notificationCount = count);
        }
      }
    } catch (e) {
      print('Error verificando notificaciones: $e');
    }
  }

  // Mostrar panel de ingredientes que expiran
  void _showNotificationsPanel() {
    if (!Get.isRegistered<PantryController>()) {
      Get.snackbar('Info', 'No hay ingredientes cargados');
      return;
    }

    final pantryController = Get.find<PantryController>();
    final expiringIngredients = pantryController.allIngredients
        .where((i) =>
            i.expirationDate != null &&
            (i.daysUntilExpiration ?? 99) <= 7)
        .toList()
      ..sort((a, b) =>
          (a.daysUntilExpiration ?? 99).compareTo(b.daysUntilExpiration ?? 99));

    // Limpiar badge al ver notificaciones
    setState(() => _notificationCount = 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                const Text(
                  'Ingredientes por Vencer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (expiringIngredients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${expiringIngredients.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (expiringIngredients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 48),
                      SizedBox(height: 8),
                      Text(
                        '¡Todo en orden!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: expiringIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = expiringIngredients[index];
                    final days = ingredient.daysUntilExpiration ?? 0;

                    Color statusColor;
                    String statusText;
                    IconData statusIcon;

                    if (days < 0) {
                      statusColor = Colors.red;
                      statusText = 'Expirado hace ${days.abs()} días';
                      statusIcon = Icons.error;
                    } else if (days == 0) {
                      statusColor = Colors.red;
                      statusText = 'Expira HOY';
                      statusIcon = Icons.warning;
                    } else if (days <= 3) {
                      statusColor = Colors.orange;
                      statusText = 'Expira en $days días';
                      statusIcon = Icons.warning_amber;
                    } else {
                      statusColor = Colors.amber;
                      statusText = 'Expira en $days días';
                      statusIcon = Icons.info_outline;
                    }

                    return ListTile(
                      leading: Icon(statusIcon, color: statusColor),
                      title: Text(
                        ingredient.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${ingredient.displayQuantity} • ${ingredient.category}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
            const SizedBox(width: 10),
            const Text(
              "Kooki",
              style: TextStyle(
                color: AppColors.nutveDarkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Botón de campana con badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: _showNotificationsPanel,
              ),
              // Badge con contador
              if (_notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificationCount > 99
                          ? '99+'
                          : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) async {
          setState(() => _selectedIndex = i);
          // Actualizar badge al volver a Pantry
          if (i == 0) {
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
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
