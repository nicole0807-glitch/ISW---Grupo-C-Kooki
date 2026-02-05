import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'home_screen_content.dart';
import '../Profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 2;
  final List<Widget> _screens = [
    const Center(child: Text("Pantry")),
    const Center(child: Text("Plan")),
    const HomeScreenContent(),
    const Center(child: Text("Search")),
    const ProfileScreen(),
  ];

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
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.nutveDarkGreen,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
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
}