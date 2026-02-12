// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:kooki/screens/home/home_screen_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart'; // 1. Importar Provider
import 'controllers/recipe_controller.dart'; // 2. Importar el controlador
import 'controllers/auth_controller.dart';
import 'screens/recipe/admin_recipes_screen.dart';
import 'controllers/home_controller.dart';
import 'providers/ingredient_master_provider.dart';
import 'package:get/get.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmpbdtwfyrzjmblfdtcb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcGJkdHdmeXJ6am1ibGZkdGNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1NTg4NTIsImV4cCI6MjA4NTEzNDg1Mn0.2hU6k4MCdpZLo1xzEWCMCbTCHvz3R424d2EHp57Odvg',
  );

  Get.put(IngredientMasterProvider());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeAdminController()),
        ChangeNotifierProvider(create: (_) => HomeController(), child: const HomeScreenContent(),), 
      ],
      child: const NutveApp(),
    ),
  );
}

class NutveApp extends StatelessWidget {
  const NutveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(  
      debugShowCheckedModeBanner: false,
      title: 'Kooki',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.nutveDarkGreen,
        scaffoldBackgroundColor: AppColors.nutveBgGray,
      ),
      home: const SplashScreen(),
    );
  }
}