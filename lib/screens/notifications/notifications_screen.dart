import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../controllers/pantry_controller.dart';
import '../../models/ingredient.dart';
import '../../utils/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1A2A1D)
            : AppColors.nutveDarkGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.nutveSelectionGreen,
              ),
            );
          }

          final dbNotifications = snapshot.data ?? [];

          // Obtener notificaciones de la despensa (pantry)
          List<Ingredient> expiringIngredients = [];
          if (Get.isRegistered<PantryController>()) {
            final pantryController = Get.find<PantryController>();
            expiringIngredients =
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
          }

          if (dbNotifications.isEmpty && expiringIngredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No tienes notificaciones",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Aquí aparecerán los avisos y alertas.",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              if (expiringIngredients.isNotEmpty) ...[
                _buildSectionTitle("Alertas de Despensa", isDark),
                const SizedBox(height: 10),
                ...expiringIngredients.map(
                  (item) => _buildPantryAlert(item, isDark),
                ),
                const SizedBox(height: 20),
              ],
              if (dbNotifications.isNotEmpty) ...[
                _buildSectionTitle("Anuncios y Novedades", isDark),
                const SizedBox(height: 10),
                ...dbNotifications.map(
                  (notif) => _buildDbNotification(notif, isDark),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.nutveSelectionGreen
              : AppColors.nutveDarkGreen,
        ),
      ),
    );
  }

  Widget _buildPantryAlert(Ingredient item, bool isDark) {
    final daysLeft = item.daysUntilExpiration ?? 99;
    final isVerySoon = daysLeft <= 2;
    final isExpired = daysLeft < 0;

    Color bgColor = isExpired
        ? Colors.red.withOpacity(0.1)
        : (isVerySoon
              ? Colors.orange.withOpacity(0.1)
              : Colors.amber.withOpacity(0.1));

    Color iconColor = isExpired
        ? Colors.redAccent
        : (isVerySoon ? Colors.orange : Colors.amber);

    IconData icon = isExpired
        ? Icons.error_rounded
        : (isVerySoon ? Icons.warning_rounded : Icons.info_rounded);

    String message = isExpired
        ? "Ya expiró hace ${daysLeft.abs()} días"
        : (daysLeft == 0
              ? "Expira HOY"
              : (daysLeft == 1 ? "Expira mañana" : "Expira en $daysLeft días"));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          item.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            message,
            style: TextStyle(
              color: isExpired
                  ? Colors.redAccent
                  : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDbNotification(Map<String, dynamic> notif, bool isDark) {
    final type = notif['type'] ?? 'general';
    final title = notif['title'] ?? 'Aviso';
    final content = notif['content'] ?? '';
    final createdAt = notif['created_at'];

    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'ai_update':
        icon = Icons.auto_awesome_rounded;
        iconColor = Colors.deepPurpleAccent;
        bgColor = Colors.deepPurpleAccent.withOpacity(0.1);
        break;
      case 'new_pro_recipe':
        icon = Icons.restaurant_menu_rounded;
        iconColor = AppColors.nutveSelectionGreen;
        bgColor = AppColors.nutveSelectionGreen.withOpacity(0.1);
        break;
      case 'manual_admin':
      default:
        icon = Icons.campaign_rounded;
        iconColor = Colors.blueAccent;
        bgColor = Colors.blueAccent.withOpacity(0.1);
        break;
    }

    String timeAgo = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        // Establecer el locale a es (necesitará importación de timeago locales si es posible, pero usaremos default inglés/es si está seteado)
        timeago.setLocaleMessages('es', timeago.EsMessages());
        timeAgo = timeago.format(date, locale: 'es');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
