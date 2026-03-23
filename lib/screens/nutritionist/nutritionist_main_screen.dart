import 'package:flutter/material.dart';
import '../recipe/validation_queue_screen.dart';
import '../Profile/profile_screen.dart';
import 'validation_history_screen.dart';
import 'nutritionist_stats_screen.dart';

class NutritionistMainScreen extends StatefulWidget {
  const NutritionistMainScreen({super.key});

  @override
  State<NutritionistMainScreen> createState() => _NutritionistMainScreenState();
}

class _NutritionistMainScreenState extends State<NutritionistMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ValidationQueueScreen(),
    const ValidationHistoryScreen(),
    const NutritionistStatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color navBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 85,
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.playlist_add_check, "Cola", isDark),
            _buildNavItem(1, Icons.history, "Historial", isDark),
            _buildNavItem(2, Icons.bar_chart, "Estadísticas", isDark),
            _buildNavItem(3, Icons.person, "Perfil", isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final bool isActive = _selectedIndex == index;
    final Color activeColor = const Color(0xFF13EC5B);
    final Color inactiveColor = isDark ? Colors.white38 : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Active Indicator (Line at the top)
            if (isActive)
              Positioned(
                top: 0,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
