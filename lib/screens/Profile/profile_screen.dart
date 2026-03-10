// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kooki/screens/Profile/diet_preferences_screen.dart';
import 'package:kooki/screens/Profile/personal_info_screen.dart';
import 'package:kooki/services/supabase_service.dart';
// Necesario para limpiar el estado
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/goal_controller.dart';
import '../../controllers/premium_controller.dart';
import '../auth/login_screen.dart';
import '../../services/profile_service.dart';
import '../goals/goal_registration_screen.dart';
import '../recipe/widgets/macro_chart_widget.dart';
import '../plan/premium_plan_screen.dart';
import '../../models/recipe_model.dart';
import '../../models/user_recipe_model.dart';
import '../../services/recipe_service.dart';
import '../recipe/widgets/recipe_card.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/theme_controller.dart';
import 'saved_recipes_screen.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Prepare future for FutureBuilder
    _profileFuture = _profileService.getProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PremiumController>().loadStatus();
    });
  }

  // --- CARGA DE DATOS ---

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final error = await _profileService.updateAvatar(bytes);

      if (error == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Foto de perfil actualizada!")),
        );
        // Recargar datos
        setState(() {
          _profileFuture = _profileService.getProfileData();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

      // 1. Ejecutar logout en Supabase
      context.read<HomeController>().clearStatus();

      // 2. Sign out de Supabase
      final supabaseService = SupabaseService();
      await supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  //Variables de sesión
  /*
  String? _userName;
  String? _avatarURL;
  */

  //Instancia del backen de profile
  late Future<Map<String, dynamic>?> _profileFuture;
  // final ProfileService _profileService = ProfileService();

  // @override
  // void initState() {
  //   super.initState();
  //   _profileFuture = _profileService.getProfileData();
  // }

  /*
  //Función para cargar los datos del usuario
  Future<void> _loadUserData() async {
    //Si no hay usuario logueado no se ejecuta
    if (!_profileService.isUserLoggedIn) {
      setState(() {
      _userName = "Desarrollador Test";
      _avatarURL = "https://i.pravatar.cc/300"; // Una imagen aleatoria de internet
      });
      return;
    }
    
    //Si hay usuario registrado se obtienen sus datos
    final data = await _profileService.getProfileData();
    
    if (data != null && mounted) {
      //Se asignan los datos a las variables:
      _userName = data['username'] ?? 'Usuario';
      _avatarURL = data['avatar_url'];
    }
    
  }
  */

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

                            // SECCIÓN DE METAS (HU-27)
                            _buildSectionHeader(
                              title: "Mi Resumen Nutricional",
                              onAction: () => _refreshGoals(context),
                            ),

                            const SizedBox(height: 10),
                            MacroChartWidget(goal: goalController.currentGoal),

                            if (goalController.currentGoal == null)
                              _buildSetupButton(() => _refreshGoals(context)),

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

                            const SizedBox(height: 10),
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

                            // OPCIONES DE CONFIGURACIÓN
                            const Text(
                              "Configuración",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildMenuButton(
                              text: "Gestionar Suscripción",
                              icon: Icons.star_outline,
                              baseColor: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PremiumPlanScreen(),
                                  ),
                                );
                              },
                            ),

                            _buildMenuButton(
                              text: "Gestión de Tutorial",
                              icon: Icons.help_outline_rounded,
                              baseColor: AppColors.nutveDarkGreen,
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

                  //Lógica por si el url es NULL o ""
                  backgroundImage: (avatarURL != null && avatarURL.isNotEmpty)
                      ? NetworkImage(
                          '$avatarURL?t=${DateTime.now().millisecondsSinceEpoch}',
                        )
                      : null,
                  child: (avatarURL == null || avatarURL.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF13EC5B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
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

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
        ),
      ),
    );
  }

  Widget _buildSetupButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF13EC5B), width: 1.5),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              const Text(
                "Guarda tus recetas favoritas y gestiona tu despensa personalizando tu perfil.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13EC5B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      future: Future.wait([
        RecipeService().fetchRecipes(),
        RecipeService().fetchCommunityRecipes(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
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
              id: ur.id.hashCode,
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
