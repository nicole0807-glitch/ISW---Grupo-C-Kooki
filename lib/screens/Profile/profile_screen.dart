// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kooki/screens/Profile/diet_preferences_screen.dart';
import 'package:kooki/screens/Profile/personal_info_screen.dart';
// Necesario para limpiar el estado
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/goal_controller.dart';
import '../../controllers/premium_controller.dart';
import '../auth/welcome_screen.dart';
import '../../services/profile_service.dart';
import '../goals/goal_registration_screen.dart';
import '../plan/premium_plan_screen.dart';
import '../../models/recipe_model.dart';
import '../../models/user_goal_model.dart';
import '../../models/user_recipe_model.dart';
import '../../services/recipe_service.dart';
import '../recipe/widgets/recipe_card.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/theme_controller.dart';
import 'saved_recipes_screen.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';
import '../../widgets/kooki_remote_image.dart';
import '../../widgets/guest_view_placeholder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<dynamic>> _savedRecipesFuture;

  @override
  void initState() {
    super.initState();
    // Prepare future for FutureBuilder
    _profileFuture = _profileService.getProfileData();
    _loadSavedRecipes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PremiumController>().loadStatus();
    });
  }

  void _loadSavedRecipes() {
    setState(() {
      _savedRecipesFuture = Future.wait([
        RecipeService().fetchRecipes(),
        RecipeService().fetchCommunityRecipes(),
      ]);
    });
  }

  // --- CARGA DE DATOS ---
  // MÉTODO PARA REINICIAR / REFRESCAR DATOS (HU-27)
  Future<void> _refreshGoals(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalRegistrationScreen()),
    );

    // Al volver, forzamos la recarga de las metas
    if (mounted) {
      context.read<GoalController>().loadExistingGoals();
    }
  }

  // --- LÓGICA DE CIERRE DE SESIÓN ---

  Future<void> _handleLogout() async {
    final authController = AuthController();
    final homeController = context.read<HomeController>();

    setState(() => _isLoading = true);

    try {
      await authController.logout();
      homeController.clearStatus();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al cerrar sesión: $e")));
      }
    }
  }

  // --- DISEÑO CIERRE DE SESIÓN ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("¿Cerrar sesión?"),
          content: const Text(
            "Tu sesión actual finalizará y tendrás que ingresar tus credenciales nuevamente.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleLogout();
              },
              child: const Text(
                "SÍ, SALIR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    if (!_profileService.isUserLoggedIn) return _buildGuestView(context);

    return ChangeNotifierProvider(
      create: (_) => GoalController()..loadExistingGoals(),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        body: Consumer<GoalController>(
          builder: (context, goalController, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Scaffold(
              // --- LÓGICA CIERRE DE SESIÓN ---
              // Si _isLoading es true, muestra el círculo.
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- TUS PLACEHOLDERS Y DISEÑO ---
                            _buildProfileHeader(),
                            const SizedBox(height: 16),
                            _buildMembershipStatusCard(),
                            const SizedBox(height: 25),
                            _buildDietPlanCard(goalController.currentGoal),
                            const SizedBox(height: 25),
                            _buildSectionHeader(
                              title: "Mis Recetas Guardadas",
                              onAction: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SavedRecipesScreen(),
                                  ),
                                );
                              }, // Función ver todas
                            ),
                            const SizedBox(height: 10),
                            _buildSavedRecipesList(),
                            const SizedBox(height: 25),

                            _buildMenuButton(
                              text: "Preferencias de Dieta",
                              icon: Icons.flatware,
                              baseColor: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DietPreferencesScreen(),
                                  ),
                                ).then((_) {
                                  //Se recarga la página cuando el usuario vuelva
                                  setState(() {
                                    _profileFuture = _profileService
                                        .getProfileData();
                                  });
                                });
                              },
                            ),

                            _buildSectionHeader(
                              title: "Configuración",
                              onAction: null,
                            ),
                            const SizedBox(height: 10),

                            // Botón de información personal
                            _buildMenuButton(
                              text: "Información Personal",
                              icon: Icons.person,
                              baseColor: Colors.blueAccent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PersonalInfoScreen(),
                                  ),
                                ).then((_) {
                                  //Se recarga la página cuando el usuario vuelva
                                  setState(() {
                                    _profileFuture = _profileService
                                        .getProfileData();
                                  });
                                });
                              },
                            ),
                            _buildMenuButton(
                              text: "Plan y Suscripción",
                              icon: Icons.star_outline,
                              baseColor: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PremiumPlanScreen(
                                      showAppBar: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildMenuButton(
                              text: context.watch<ThemeController>().isDarkMode
                                  ? "Modo Claro"
                                  : "Modo Oscuro",
                              icon: context.watch<ThemeController>().isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              baseColor: Colors.orangeAccent,
                              onTap: () {
                                context.read<ThemeController>().toggleTheme();
                              },
                            ),

                            _buildMenuButton(
                              text: "Gestión de Tutorial",
                              icon: Icons.help_outline_rounded,
                              baseColor: isDark
                                  ? AppColors.nutveSelectionGreen
                                  : AppColors.nutveDarkGreen,
                              onTap: () {
                                // Trigger the tour in MainLayout
                                context
                                    .findAncestorStateOfType<MainLayoutState>()
                                    ?.startManualTour();
                              },
                            ),

                            const SizedBox(height: 30),
                            _buildLogoutButton(
                              onTap: () => _showLogoutDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS COMPONENTES ---

  Widget _buildProfileHeader() {
    //Se usa futureBuilder para esperar los datos
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        //Aún está cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        //Error
        if (snapshot.hasError) {
          return const Text("Error al cargar perfil");
        }

        //Los datos ya fueron recibidos
        final data = snapshot.data;

        //Se verifica que data no sea null
        final userName = (data != null && data['username'] != null)
            ? data['username']
            : "Usuario";

        final avatarURL = (data != null) ? data['avatar_url'] : null;

        // email obtenido de auth
        final email =
            _profileService.currentUser?.email ?? 'Sin correo electrónico';

        //Se crea la UI
        return Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: (avatarURL != null && avatarURL.isNotEmpty)
                      ? ClipOval(
                          child: KookiRemoteImage(
                            imageUrl: avatarURL,
                            bucketHint: 'avatars',
                            bustCache: true,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (onAction != null)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.blueAccent),
            onPressed: onAction,
          ),
      ],
    );
  }

  Widget _buildMembershipStatusCard() {
    final premium = context.watch<PremiumController>();
    final active = premium.isPremium;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1E1E20)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Estado de tu Suscripción",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              active
                  ? "Tiempo restante: ${premium.daysRemaining} días"
                  : "Membresía inactiva",
              style: TextStyle(
                color: active ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Renovación Automática",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: premium.autoRenewEnabled,
                    onChanged: (value) =>
                        context.read<PremiumController>().setAutoRenew(value),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDietPlanCard(UserGoalModel? goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasGoal = goal != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Plan de dieta",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasGoal
                ? "Tu resumen nutricional y el plan semanal ahora se gestionan desde la pestaña Plan."
                : "Completa tu perfil nutricional para que el plan semanal se base en tus metas reales.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          if (hasGoal) ...[
            const SizedBox(height: 10),
            Text(
              "Objetivo actual: ${goal.targetCalories.toStringAsFixed(0)} kcal por día",
              style: TextStyle(
                color: isDark
                    ? AppColors.nutveSelectionGreen
                    : AppColors.nutveDarkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumPlanScreen(showAppBar: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveDarkGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text("Ver plan"),
              ),
              OutlinedButton.icon(
                onPressed: () => _refreshGoals(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(hasGoal ? "Editar metas" : "Configurar metas"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.nutveSelectionGreen
                : const Color(0xFF13EC5B),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(
          Icons.add_chart,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        label: Text(
          "Configurar Metas Nutricionales",
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMenuButton({
    required String text,
    required IconData icon,
    required Color baseColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.only(
          left: 12,
          right: 16,
          top: 4,
          bottom: 4,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: baseColor, size: 26),
        ),
        title: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? Colors.red.withOpacity(0.1)
              : Colors.red.shade50,
          foregroundColor: Colors.redAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          "Cerrar Sesión",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return const Scaffold(
      body: GuestViewPlaceholder(
        title: "Tu Perfil",
        description:
            "Guarda tus recetas favoritas y gestiona tu despensa personalizando tu perfil.",
      ),
    );
  }

  Widget _buildSavedRecipesList() {
    final favorites = context.watch<FavoritesController>();
    if (favorites.favoriteIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(
          child: Text(
            "Aún no tienes recetas guardadas.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _savedRecipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Error al cargar recetas",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: _loadSavedRecipes,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      "Reintentar",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.nutveSelectionGreen,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) return const SizedBox();

        final allRecipes = snapshot.data![0] as List<Recipe>;
        final communityRecipes = snapshot.data![1] as List<UserRecipe>;

        final List<Widget> cards = [];

        // Agregar recetas oficiales
        for (var r in allRecipes) {
          if (favorites.isFavorite(r.id)) {
            cards.add(
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: RecipeCard(recipe: r),
              ),
            );
          }
        }

        // Agregar recetas de la comunidad (mapeadas a Recipe para visualización)
        for (var ur in communityRecipes) {
          // Nota: Las recetas de comunidad usan IDs String, FavoritesController usa int.
          // Si FavoritesController solo soporta int, las de comunidad no se marcarán.
          // FIX: FavoritesController debería soportar String si las recetas de comunidad lo usan.
          if (favorites.isFavorite(ur.id)) {
            // Mapeo completo para que al abrir la receta se vea todo
            final r = Recipe(
              id: ur.id,
              title: ur.title,
              imageUrl: ur.imageUrl,
              rating: ur.avgRating,
              cookingTime: ur.duration,
              difficulty: ur.difficulty,
              nutrition: ur.nutrition,
              ingredients: ur.ingredients
                  .map(
                    (i) => RecipeIngredient(
                      ingredientId: 0,
                      name: i.toString(),
                      amount: 0,
                      unit: '',
                    ),
                  )
                  .toList(),
              steps: ur.steps.map((s) => s.toString()).toList(),
              tagIds: [],
            );
            cards.add(
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: RecipeCard(recipe: r),
              ),
            );
          }
        }

        if (cards.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No hay recetas guardadas que mostrar"),
            ),
          );
        }

        return SizedBox(
          height: 360,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: cards,
          ),
        );
      },
    );
  }
}
