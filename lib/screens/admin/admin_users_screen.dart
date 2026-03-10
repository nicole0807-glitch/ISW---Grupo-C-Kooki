import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _users = [];

  // Paleta oscura
  // Paleta dinámica basada en el tema
  Color get bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get cardDark => Theme.of(context).cardColor;
  Color get accentGreen => AppColors.nutveSelectionGreen;
  Color get textWhite => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black87;
  Color get textGrey => Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // Usamos 'Profile' (P mayúscula) según la imagen de la base de datos
      final data = await _supabase.from('Profile').select().order('username');
      setState(() {
        _users = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar usuarios: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, int currentRoleId) async {
    final Map<int, String> roleNames = {
      1: 'USUARIO',
      2: 'NUTRICIONISTA',
      3: 'ADMINISTRADOR',
    };

    // Capturar los colores ANTES de abrir el diálogo, ya que el contexto del diálogo
    // puede no tener acceso a los getters del State padre.
    final dialogBg = cardDark;
    final dialogText = textWhite;
    final dialogAccent = accentGreen;

    int? selectedRoleId = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            "Cambiar Rol",
            style: GoogleFonts.poppins(color: dialogText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roleNames.entries.map((entry) {
              return RadioListTile<int>(
                title: Text(
                  entry.value,
                  style: GoogleFonts.poppins(color: dialogText, fontSize: 14),
                ),
                value: entry.key,
                groupValue: currentRoleId,
                activeColor: dialogAccent,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedRoleId != null && selectedRoleId != currentRoleId) {
      setState(() => _isLoading = true);
      try {
        await _supabase
            .from('Profile')
            .update({'role_id': selectedRoleId})
            .eq('user_id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Rol actualizado correctamente"),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchUsers(); // awaited so loading clears after data arrives
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al cambiar rol: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('Profile')
          .update({'status': !currentStatus})
          .eq('user_id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? "Usuario activado" : "Usuario bloqueado",
            ),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
      await _fetchUsers(); // awaited so loading clears correctly
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, const Color(0xFF0F1412)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentGreen),
                      )
                    : _users.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final username =
                              user['username'] ?? 'Usuario Anónimo';
                          return _buildUserCard(
                            user,
                            username,
                            user['role_id'] ?? 1,
                            user['status'] ?? true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textWhite,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            "Gestión de Usuarios",
            style: GoogleFonts.poppins(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: accentGreen),
            onPressed: _fetchUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, color: textGrey, size: 64),
          const SizedBox(height: 16),
          Text(
            "No se encontraron usuarios",
            style: GoogleFonts.poppins(color: textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    dynamic user,
    String username,
    int roleId,
    bool isActive,
  ) {
    final String roleName = _getRoleName(roleId);
    final Color roleColor = _getRoleColor(roleId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !isActive
                        ? Colors.red.withOpacity(0.1)
                        : accentGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    !isActive ? Icons.block_flipped : Icons.person_rounded,
                    color: !isActive ? Colors.redAccent : accentGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          color: textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  roleColor.withOpacity(0.2),
                                  roleColor.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: roleColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              roleName,
                              style: GoogleFonts.poppins(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isActive)
                            Text(
                              "INACTIVO",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.shield_outlined,
                      Colors.blueAccent,
                      () => _updateUserRole(user['user_id'], roleId),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      isActive
                          ? Icons.gavel_rounded
                          : Icons.check_circle_outline_rounded,
                      isActive ? Colors.orangeAccent : Colors.lightGreenAccent,
                      () => _toggleUserStatus(user['user_id'], isActive),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 3:
        return 'ADMIN';
      case 2:
        return 'NUTRICIONISTA';
      default:
        return 'USUARIO';
    }
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 3:
        return Colors.purpleAccent;
      case 2:
        return Colors.amber;
      default:
        return accentGreen;
    }
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
