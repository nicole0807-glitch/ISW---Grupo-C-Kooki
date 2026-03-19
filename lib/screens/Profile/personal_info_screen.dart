import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../services/profile_service.dart';
import '../../services/image_service.dart';
import '../../utils/app_colors.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _profileService = ProfileService();
  final _imageService = ImageService();
  late Future<Map<String, dynamic>?> _userDataFuture;
  List<Map<String, dynamic>> _roles = [];
  int? _selectedRoleId;
  bool _rolesLoading = false;
  bool _savingRole = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRolesIfAdmin();
    });
  }

  //Recarga los datos cuando son actualizados
  void _refreshData() {
    setState(() {
      _userDataFuture = _profileService.getProfileData();
    });
  }

  Future<void> _loadRolesIfAdmin() async {
    final canManageRoles = context.read<HomeController>().canManageUsers;
    if (!canManageRoles) return;

    setState(() => _rolesLoading = true);
    final roles = await _profileService.getAvailableRoles();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _rolesLoading = false;
    });
  }

  Future<void> _saveRoleForCurrentUser() async {
    final user = _profileService.currentUser;
    final roleId = _selectedRoleId;
    if (user == null || roleId == null) return;

    setState(() => _savingRole = true);
    final error = await _profileService.updateUserRole(
      userId: user.id,
      roleId: roleId,
    );
    if (!mounted) return;

    setState(() => _savingRole = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? "Rol actualizado correctamente."
              : "No se pudo actualizar el rol: $error",
        ),
      ),
    );

    if (error == null) {
      await context.read<HomeController>().loadUserRole();
      _refreshData();
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final imageFile = await _imageService.pickImage();
      if (imageFile == null) return;

      setState(() => _isLoading = true);

      final imageUrl = await _imageService.uploadAvatar(imageFile);

      if (imageUrl != null) {
        final error = await _profileService.updateAvatarUrl(imageUrl);
        if (error == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Foto de perfil actualizada!")),
          );
          _refreshData();
        } else {
          throw Exception(error);
        }
      } else {
        throw Exception("Error al subir la imagen");
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

  bool _isLoading = false;
  //Widget principal
  @override
  Widget build(BuildContext context) {
    final canManageRoles = context.watch<HomeController>().canManageUsers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Información Personal",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

      ),

      //FutureBuilder para esperar a que los datos carguen
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _userDataFuture,
            builder: (context, snapshot) {
          //Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //ERROR
          if (snapshot.hasError) {
            return _buildErrorState(
              "No pudimos cargar tus datos. Revisa tu conexión.",
              _refreshData,
            );
          }

          //Datos cargados
          final data = snapshot.data;
          _selectedRoleId ??= data?['role_id'] as int?;

          //Se verifica que data no sea null
          final userName = (data != null && data['username'] != null)
              ? data['username']
              : "Usuario";

          final avatarURL = (data != null) ? data['avatar_url'] : null;

          // email obtenido de auth
          final email = _profileService.currentUser?.email ?? 'Sin email';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                //Tarjeta de imagen y username
                _buildTopSection(userName, avatarURL),
                const SizedBox(height: 20),

                //Tarjeta de email y contraseña
                _buildSensitiveSection(email),
                if (canManageRoles) ...[
                  const SizedBox(height: 20),
                  _buildRoleSection(),
                ],
              ],
            ),
          );
        },
      ),
      if (_isLoading)
        const Center(child: CircularProgressIndicator()),
    ],
  ),
);
}

  Widget _buildRoleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownValue =
        _roles.where((r) => r['role_id'] == _selectedRoleId).isNotEmpty
        ? _selectedRoleId
        : null;

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gestión de Rol (Admin)",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (_rolesLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                initialValue: dropdownValue,
                decoration: const InputDecoration(
                  labelText: "Seleccionar rol",
                  border: OutlineInputBorder(),
                ),
                items: _roles
                    .map(
                      (role) => DropdownMenuItem<int>(
                        value: role['role_id'] as int,
                        child: Text(role['name']?.toString() ?? 'Rol'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRoleId = value),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_savingRole || _selectedRoleId == null)
                    ? null
                    : _saveRoleForCurrentUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _savingRole
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Guardar rol",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //WIDGETS Secundarios
  Widget _buildTopSection(String username, String? avatarURL) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            //La imagen va a la izquierda
            Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (avatarURL != null && avatarURL.isNotEmpty)
                      ? NetworkImage(avatarURL)
                      : null,
                  child: (avatarURL == null || avatarURL.isEmpty)
                      ? const Icon(Icons.person, size: 35, color: Colors.grey)
                      : null,
                ),
                //Botón de editar foto
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.nutveSelectionGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),

            //Username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nombre de usuario",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.nutveSelectionGreen,
                        ),
                        onPressed: () {
                          _showEditDialog(
                            title: "Editar Nombre",
                            currentValue: username,
                            onSave: (newValue) async {
                              await _profileService.updateUsername(newValue);
                              _refreshData();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitiveSection(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Email
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Correo Electrónico"),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.nutveSelectionGreen,
              ),
              onPressed: () {
                _showEditDialog(
                  title: "Editar Correo",
                  currentValue: email,
                  onSave: (newValue) async {
                    await _profileService.updateAuthMail(newValue);
                    _refreshData();
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Contraseña
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Contraseña"),
            subtitle: const Text("••••••••••"),
            trailing: IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.nutveSelectionGreen,
              ),
              onPressed: () {
                _showPasswordDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  // DIALOG GENÉRICO
  Future<void> _showEditDialog({
    required String title,
    required String currentValue,
    required Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await onSave(controller.text);

              messenger.showSnackBar(
                const SnackBar(content: Text("Cambio realizado exitosamente.")),
              );
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  //DIALOGO de contraseña
  Future<void> _showPasswordDialog() async {
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    final currentPassController = TextEditingController();
    String? errorText;
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Cambiar Contraseña"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Contraseña actual
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña Actual",
                      prefixIcon: Icon(Icons.lock_open),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Nueva Contraseña
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nueva Contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  //Confirmación de Contraseña
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirmar Nueva Contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  //Botón de cancelar
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                //Botón para realizar cambios
                ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          //Contraseña actual vacía
                          if (currentPassController.text.isEmpty) {
                            setDialogState(
                              () => errorText = "Ingresa tu contraseña actual",
                            );
                          }

                          //La contraseña nueva y la confirmación no coinciden
                          if (passController.text != confirmController.text) {
                            setDialogState(() {
                              errorText =
                                  "La confirmación no coincide con la contraseña nueva. Intentelo de nuevo.";
                            });
                            return;
                          }

                          //Longitud mínima para la contraseña nueva
                          if (passController.text.length < 6) {
                            setDialogState(() {
                              errorText = "Utilice mínimo 8 caracteres";
                            });
                            return;
                          }

                          //Verificación de contraseña actual
                          setDialogState(() {
                            isVerifying = true;
                            errorText = null;
                          });

                          bool isCurrentCorrect = await _profileService
                              .validateCurrentPassword(
                                currentPassController.text,
                              );

                          if (!isCurrentCorrect) {
                            setDialogState(() {
                              isVerifying = false;
                              errorText = "La contraseña actual es incorrecta";
                            });
                            return;
                          }

                          //CAMBIO DE CONTRASEÑA
                          await _profileService.updateAuthPass(
                            passController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Contraseña actualizada exitosamente",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Intentar de nuevo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
