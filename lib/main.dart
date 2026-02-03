import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'screens/profile_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
    url: 'https://sedhrzxgquyzckvlglac.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlZGhyenhncXV5emNrdmxnbGFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2MzE3OTYsImV4cCI6MjA4NTIwNzc5Nn0.pOhBWtYCE5HmY3pqga3UxiDdBMNa9q-bAf3iJXEWj7k',
  );

  runApp(const NutveApp());
}

final supabase = Supabase.instance.client;

// --- CONFIGURACIÓN DE COLORES ---
const Color nutveDarkGreen = Color(0xFF1B4332);
const Color nutveSelectionGreen = Color(0xFF52B788);
const Color nutveBgGray = Color(0xFFF5F5F5);

// --- CLASE PARA TRANSPORTAR DATOS ---
class UserOnboardingData {
  static String? goal;
  static List<String> diets = [];
  static List<String> allergies = [];
}

class NutveApp extends StatelessWidget {
  const NutveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutve App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: nutveDarkGreen,
        scaffoldBackgroundColor: nutveBgGray,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nutveDarkGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// --- 2. LOGIN SCREEN ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/imagen_main.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField("Username", Icons.person_outline, null),
                    const SizedBox(height: 15),
                    _buildField(
                      "Password",
                      Icons.lock_outline,
                      null,
                      isPass: true,
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: nutveDarkGreen,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainLayout()),
                      ),
                      child: const Text("INGRESAR"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        "¿No tienes cuenta? Crear perfil",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController? controller, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white60),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// --- 3. REGISTER SCREEN ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_imageFile == null) return null;
    try {
      final fileName = '$userId/profile.png';
      await supabase.storage
          .from('avatars')
          .upload(
            fileName,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<void> _signUp() async {
    final String email = _emailController.text.trim();
    final String password = _passController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final userId = authResponse.user?.id;
      if (userId != null) {
        String? avatarUrl = await _uploadAvatar(userId);
        List<String> nameParts = _nameController.text.trim().split(' ');
        await supabase.from('profiles').upsert({
          'id': userId,
          'first_name': nameParts.isNotEmpty ? nameParts[0] : '',
          'last_name': nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : '',
          'username': _userController.text.trim(),
          'email': email,
          'avatar_url': avatarUrl,
        });
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const GoalSelectionScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nutveDarkGreen,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              "CREAR PERFIL",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white10,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildInput("Nombre y Apellido", Icons.badge, _nameController),
            _buildInput(
              "Username (Único)",
              Icons.alternate_email,
              _userController,
            ),
            _buildInput("Email (Único)", Icons.email, _emailController),
            _buildInput(
              "Contraseña",
              Icons.lock,
              _passController,
              isPass: true,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: nutveDarkGreen,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _signUp,
                    child: const Text("REGISTRAR CUENTA"),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
      ),
    );
  }
}

// --- 4. ONBOARDING 1/3: GOALS ---
class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});
  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? _selectedGoal;
  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Eat Healthier',
      'desc': 'Focus on nutritious, whole foods.',
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Lose Weight',
      'desc': 'Manage calories and macros.',
      'icon': Icons.monitor_weight_rounded,
    },
    {
      'title': 'Save Money',
      'desc': 'Reduce waste and dining out costs.',
      'icon': Icons.savings_rounded,
    },
    {
      'title': 'Learn to Cook',
      'desc': 'Master new recipes and techniques.',
      'icon': Icons.restaurant_menu_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("1 of 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 0.33, color: nutveDarkGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What is your main goal?",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isSelected = _selectedGoal == goal['title'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGoal = goal['title']),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? nutveSelectionGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? nutveSelectionGreen
                                    : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  goal['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    goal['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nutveDarkGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _selectedGoal == null
                  ? null
                  : () {
                      UserOnboardingData.goal = _selectedGoal;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DietSelectionScreen(),
                        ),
                      );
                    },
              child: const Text("CONTINUAR"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. ONBOARDING 2/3: DIET & ALLERGIES ---
class DietSelectionScreen extends StatefulWidget {
  const DietSelectionScreen({super.key});
  @override
  State<DietSelectionScreen> createState() => _DietSelectionScreenState();
}

class _DietSelectionScreenState extends State<DietSelectionScreen> {
  final List<String> _diets = [
    "Vegan",
    "Keto",
    "Vegetarian",
    "Paleo",
    "Low Carb",
    "Mediterranean",
  ];
  final List<String> _allergies = [
    "Dairy",
    "Gluten",
    "Soy",
    "Shellfish",
    "Nuts",
    "None",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("2 of 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 0.66, color: nutveDarkGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What is your diet?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Dietary patterns:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectionGrid(_diets, UserOnboardingData.diets),
                    const SizedBox(height: 30),
                    const Text(
                      "Allergies:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectionGrid(
                      _allergies,
                      UserOnboardingData.allergies,
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nutveDarkGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed:
                  (UserOnboardingData.diets.isEmpty ||
                      UserOnboardingData.allergies.isEmpty)
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CookingSkillScreen(),
                        ),
                      );
                    },
              child: const Text("CONTINUAR"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGrid(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (val) => setState(() {
            if (option == "None") {
              selectedList.clear();
              selectedList.add("None");
            } else {
              selectedList.remove("None");
              val ? selectedList.add(option) : selectedList.remove(option);
            }
          }),
          selectedColor: nutveSelectionGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }
}

// --- 6. ONBOARDING 3/3: COOKING SKILLS & SAVE ---
class CookingSkillScreen extends StatefulWidget {
  const CookingSkillScreen({super.key});
  @override
  State<CookingSkillScreen> createState() => _CookingSkillScreenState();
}

class _CookingSkillScreenState extends State<CookingSkillScreen> {
  String? _selectedTime;
  String? _selectedSkill;
  bool _isFinalizing = false;

  final List<Map<String, dynamic>> _skills = [
    {
      'title': 'Beginner',
      'desc': 'I am just starting to cook.',
      'icon': Icons.egg_outlined,
    },
    {
      'title': 'Intermediate',
      'desc': 'I know the basics.',
      'icon': Icons.soup_kitchen_outlined,
    },
    {
      'title': 'Pro',
      'desc': 'I am a kitchen master.',
      'icon': Icons.outdoor_grill_outlined,
    },
  ];

  Future<void> _saveAndFinish() async {
    setState(() => _isFinalizing = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('user_preferences').upsert({
          'id': user.id,
          'goal': UserOnboardingData.goal,
          'diets': UserOnboardingData.diets,
          'allergies': UserOnboardingData.allergies,
          'cooking_time': _selectedTime,
          'cooking_skill': _selectedSkill,
        });
        if (mounted)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuccessScreen()),
            (route) => false,
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("3 of 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 1.0, color: nutveDarkGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN DE TIEMPO ---
                    const Text(
                      "How much time do you have to cook?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['15 min', '30 min', '+60 min'].map((time) {
                        final isSelected = _selectedTime == time;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = time),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.26,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? nutveSelectionGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? nutveSelectionGreen
                                    : Colors.black12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    // --- SECCIÓN DE HABILIDAD ---
                    const Text(
                      "Cooking Skill",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Menciona tu nivel de habilidad de cocina",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ..._skills.map((skill) {
                      final isSelected = _selectedSkill == skill['title'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSkill = skill['title']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? nutveSelectionGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? nutveSelectionGreen
                                  : Colors.black12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                skill['icon'],
                                size: 30,
                                color: isSelected
                                    ? Colors.white
                                    : nutveDarkGreen,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    skill['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    skill['desc'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            _isFinalizing
                ? const CircularProgressIndicator(color: nutveDarkGreen)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nutveDarkGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: (_selectedTime == null || _selectedSkill == null)
                        ? null
                        : _saveAndFinish,
                    child: const Text("FINALIZAR"),
                  ),
          ],
        ),
      ),
    );
  }
}

// --- 7. SUCCESS SCREEN ---
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 100,
              color: nutveSelectionGreen,
            ),
            const SizedBox(height: 20),
            const Text(
              "¡Todo listo!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: nutveDarkGreen,
              ),
            ),
            const Text("Tu perfil ha sido configurado."),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: nutveDarkGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainLayout()),
              ),
              child: const Text("IR AL HOME"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 8. MAIN LAYOUT ---
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
              "NUTVE",
              style: TextStyle(
                color: nutveDarkGreen,
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
        selectedItemColor: nutveDarkGreen,
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
              backgroundColor: nutveDarkGreen,
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

// --- 9. HOME CONTENT ---
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: nutveDarkGreen,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Unlock Your\nHealth Potential",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: nutveDarkGreen,
                  ),
                  onPressed: () {},
                  child: const Text("MEJORAR PLAN"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: "Search recipes...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
