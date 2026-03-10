// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:kooki/screens/home/home_screen_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/recipe_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/recipe/admin_recipes_screen.dart';
import 'controllers/home_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/premium_controller.dart';
import 'providers/ingredient_master_provider.dart';
import 'controllers/cooking_controller.dart';
import 'controllers/pantry_controller.dart';
import 'package:get/get.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmpbdtwfyrzjmblfdtcb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcGJkdHdmeXJ6am1ibGZkdGNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1NTg4NTIsImV4cCI6MjA4NTEzNDg1Mn0.2hU6k4MCdpZLo1xzEWCMCbTCHvz3R424d2EHp57Odvg',
  );

  Get.put(IngredientMasterProvider());
  Get.put(CookingController());
  Get.put(PantryController());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => RecipeAdminController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(
          create: (_) => FavoritesController()..loadFavorites(),
        ),
        ChangeNotifierProvider(
          create: (_) => PremiumController()..loadStatus(),
        ),
      ],
      child: const NutveApp(),
    ),
  );
}

class NutveApp extends StatelessWidget {
  const NutveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kooki',
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.nutveDarkGreen,
        scaffoldBackgroundColor: AppColors.nutveBgGray,
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.nutveSelectionGreen,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
