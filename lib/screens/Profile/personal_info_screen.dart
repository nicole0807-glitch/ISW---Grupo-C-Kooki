import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../services/profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _profileService = ProfileService();
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
    final isAdmin = context.read<HomeController>().isAdmin;
    if (!isAdmin) return;

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

  //Widget principal
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<HomeController>().isAdmin;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 248, 246),
      appBar: AppBar(
        title: const Text("Información Personal"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        foregroundColor: Colors.black,
      ),

      //FutureBuilder para esperar a que los datos carguen
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {

          //Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //ERROR
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 10),
                  const Text("Error cargando los datos de usuario. Intente más tarde."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Volver al Perfil"),
                  )
                ],
              ),
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
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  _buildRoleSection(),
                ],
              ],
            ),
          );

        }
      )

    );
  }

  Widget _buildRoleSection() {
    final dropdownValue = _roles
            .where((r) => r['role_id'] == _selectedRoleId)
            .isNotEmpty
        ? _selectedRoleId
        : null;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Rol (Admin)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_rolesLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                value: dropdownValue,
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
                  backgroundColor: const Color.fromARGB(255, 19, 236, 91),
                  foregroundColor: Colors.black,
                ),
                child: _savingRole
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Guardar rol"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //WIDGETS Secundarios
  Widget _buildTopSection(String username, String? avatarURL) {
    return Card(
      elevation: 2,
      color: Colors.white,
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
                  ? NetworkImage(avatarURL) : null,
                  child: (avatarURL == null || avatarURL.isEmpty)
                  ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,

                ),
                //Botón de editar foto
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 19, 236, 91),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                  ),
                )
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 19, 236, 91),),
                        onPressed: () {
                          _showEditDialog(
                            title: "Editar Nombre",
                            currentValue: username,
                            onSave: (newValue) async {
                              await _profileService.updateUsername(newValue);
                              _refreshData();
                            }
                          );
                        },
                      )
                    ],
                  )
                ],
              )
            )
          ],
        ),
      )
    );
  }

  Widget _buildSensitiveSection(String email) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // Email

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Correo Electrónico"),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color.fromARGB(255, 19, 236, 91)),
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
              icon: const Icon(Icons.edit, color: Color.fromARGB(255, 19, 236, 91)),
              onPressed: () {
                _showPasswordDialog();
              },
            ),
          )
        ],
      )
    );
  }

  // DIALOG GENÉRICO
  Future <void> _showEditDialog({
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
          )
        ],
      )
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
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),

                ),
                //Botón para realizar cambios
                ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                  onPressed: isVerifying ? null : () async {

                    //Contraseña actual vacía
                    if (currentPassController.text.isEmpty) {
                      setDialogState(() => errorText = "Ingresa tu contraseña actual");
                    }

                    //La contraseña nueva y la confirmación no coinciden
                    if (passController.text != confirmController.text) {
                      setDialogState(() {
                        errorText = "La confirmación no coincide con la contraseña nueva. Intentelo de nuevo.";
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

                    bool isCurrentCorrect = await _profileService.validateCurrentPassword(currentPassController.text);

                    if (!isCurrentCorrect) {
                      setDialogState(() {
                        isVerifying = false;
                        errorText = "La contraseña actual es incorrecta";
                      });
                      return;
                    }

                    //CAMBIO DE CONTRASEÑA
                    await _profileService.updateAuthPass(passController.text);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Contraseña actualizada exitosamente"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                  },
                  child: isVerifying
                  ? const SizedBox(width: 20, height: 20, child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                  : const Text("Guardar"),
                ),
              ],
            );
          }
        );
      }
    );
  }

}
