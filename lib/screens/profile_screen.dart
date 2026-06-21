import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/push_service.dart';
import '../widgets/app_header.dart';
import 'terms_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = PushService.notificationsEnabled;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('No user logged in')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFffffff),
          body: CustomScrollView(
            slivers: [
              sectionSliverAppBar('Perfil'),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de usuario
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A56DB), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _rolLabel(user.role),
                                          style: const TextStyle(fontSize: 11, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showEditProfileDialog(context, authProvider, user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.25),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Editar perfil',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información personal
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFececf0)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              'Teléfono',
                              user.phone.isNotEmpty ? user.phone : 'No ingresado',
                              Icons.phone,
                            ),
                            const Divider(height: 24),
                            _buildInfoItem(
                              'Fecha de nacimiento',
                              user.birthDate.isNotEmpty
                                  ? user.birthDate
                                  : 'No ingresada',
                              Icons.calendar_today,
                            ),
                            const Divider(height: 24),
                            _buildInfoItem(
                              'Tipo de sangre',
                              user.bloodType,
                              Icons.favorite,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Configuración
                      const Text(
                        'Configuración',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFececf0)),
                        ),
                        child: Column(
                          children: [
                            _buildConfigItem(
                              'Notificaciones',
                              'Recordatorios de medicamentos',
                              Icons.notifications_active,
                              _notificationsEnabled,
                              (value) async {
                                await PushService.setEnabled(value);
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(value
                                          ? 'Notificaciones activadas'
                                          : 'Notificaciones desactivadas'),
                                    ),
                                  );
                                }
                              },
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildConfigItemWithArrow(
                              'Términos y Condiciones',
                              'Política de privacidad y datos',
                              Icons.description_outlined,
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TermsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Función de cuidador
                      const Text(
                        'Función de cuidador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFececf0)),
                        ),
                        child: (user.caregiverEnabled || user.role == 'TITULAR')
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified_user,
                                        color: Colors.green[600], size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Función de cuidador activada',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF030213),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ya puedes gestionar a tus pacientes desde la pestaña Cuidador.',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildConfigItemWithArrow(
                                'Activar función de cuidador',
                                'Para cuidar a otra persona y gestionar sus medicamentos',
                                Icons.people_outline,
                                () => _showEnableCaregiverInfo(context, authProvider),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Gestión de cuenta
                      const Text(
                        'Gestión de cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFececf0)),
                        ),
                        child: Column(
                          children: [
                            _buildConfigItemWithArrow(
                              'Cambiar contraseña',
                              'Actualiza tu contraseña',
                              Icons.vpn_key,
                              () =>
                                  _showChangePasswordDialog(context, authProvider),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildConfigItemWithArrowDangerous(
                              'Eliminar cuenta',
                              'Acción permanente e irreversible',
                              Icons.delete_outline,
                              () =>
                                  _showDeleteAccountDialog(context, authProvider),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contacto de emergencia
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contacto de emergencia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFd4183d),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.emergencyContact.isNotEmpty
                                  ? user.emergencyContact
                                  : 'No ingresado',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFd4183d),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.emergencyPhone.isNotEmpty
                                  ? user.emergencyPhone
                                  : 'No ingresado',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFd4183d),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _showEditEmergencyContactDialog(
                                context,
                                authProvider,
                                user,
                              ),
                              child: const Text(
                                'Editar contacto',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFd4183d),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón cerrar sesión
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showLogoutDialog(context, authProvider),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFd4183d),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _rolLabel(String role) {
    switch (role) {
      case 'PACIENTE':
        return 'Paciente';
      case 'TITULAR':
        return 'Cuidador titular';
      default:
        return 'Usuario independiente';
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A56DB), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF717182),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF030213),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A56DB), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF030213),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF717182),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF1A56DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItemWithArrow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A56DB), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF030213),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF717182),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFececf0)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItemWithArrowDangerous(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFd4183d), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFd4183d),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFd4183d),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFd4183d)),
          ],
        ),
      ),
    );
  }

  // ============ DIÁLOGOS =============

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider, user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    DateTime? selectedDate;
    if (user.birthDate.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(user.birthDate);
      } catch (_) {}
    }

    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String? selectedBloodType = bloodTypes.contains(user.bloodType) ? user.bloodType : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime(1970),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFf3f3f5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF717182)),
                        const SizedBox(width: 10),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                              : 'Fecha de nacimiento',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDate != null ? const Color(0xFF030213) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedBloodType,
                  decoration: const InputDecoration(labelText: 'Tipo de sangre'),
                  items: bloodTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedBloodType = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final birthDateStr = selectedDate != null
                    ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                    : '';
                await authProvider.updateProfile(
                  name: nameController.text,
                  phone: phoneController.text,
                  birthDate: birthDateStr,
                  bloodType: selectedBloodType ?? '',
                  emergencyContact: user.emergencyContact,
                  emergencyPhone: user.emergencyPhone,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final oldPasswordController = TextEditingController();
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String errorMessage = '';
    bool sendingCode = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Color(0xFFd4183d)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                  ),
                ),
                const SizedBox(height: 12),
                // Enviar código de seguridad al correo
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: sendingCode
                        ? null
                        : () async {
                            setState(() => sendingCode = true);
                            final ok = await authProvider.sendActionCode(
                                authProvider.userEmail, 'cambiar tu contraseña');
                            if (!context.mounted) return;
                            setState(() => sendingCode = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Código enviado a ${authProvider.userEmail}'
                                    : (authProvider.error ??
                                        'No se pudo enviar el código')),
                              ),
                            );
                          },
                    icon: sendingCode
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Enviar código al correo'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código de verificación',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await authProvider.changePassword(
                  oldPasswordController.text,
                  codeController.text.trim(),
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
                if (success) {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contraseña actualizada correctamente'),
                      ),
                    );
                  }
                } else {
                  setState(() {
                    errorMessage = authProvider.error ??
                        'Error. Verifica los datos e intenta nuevamente.';
                  });
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmergencyContactDialog(
    BuildContext context,
    AuthProvider authProvider,
    user,
  ) {
    final contactController =
        TextEditingController(text: user.emergencyContact);
    final phoneController = TextEditingController(text: user.emergencyPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Contacto de Emergencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: 'Nombre del contacto',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await authProvider.updateProfile(
                name: user.name,
                phone: user.phone,
                birthDate: user.birthDate,
                bloodType: user.bloodType,
                emergencyContact: contactController.text,
                emergencyPhone: phoneController.text,
              );
              if (context.mounted) Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Contacto de emergencia actualizado'
                      : 'No se pudo actualizar el contacto'),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final passwordController = TextEditingController();
    final codeController = TextEditingController();
    String errorMessage = '';
    bool sendingCode = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Eliminar Cuenta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚠️ Esta acción es permanente e irreversible. '
                  'Se eliminarán todos tus datos. Confirma con tu contraseña '
                  'y el código que enviaremos a tu correo.',
                  style: TextStyle(color: Color(0xFFd4183d)),
                ),
                const SizedBox(height: 16),
                if (errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Color(0xFFd4183d)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirma tu contraseña',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: sendingCode
                        ? null
                        : () async {
                            setState(() => sendingCode = true);
                            final ok = await authProvider.sendActionCode(
                                authProvider.userEmail, 'eliminar tu cuenta');
                            if (!context.mounted) return;
                            setState(() => sendingCode = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Código enviado a ${authProvider.userEmail}'
                                    : (authProvider.error ??
                                        'No se pudo enviar el código')),
                              ),
                            );
                          },
                    icon: sendingCode
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Enviar código al correo'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Código de verificación',
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final success = await authProvider.deleteAccount(
                    passwordController.text, codeController.text.trim());
                if (success) {
                  // logout() ya limpió la sesión; la app vuelve a Login sola
                  if (context.mounted) Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada')),
                  );
                } else {
                  setState(() {
                    errorMessage = authProvider.error ?? 'Contraseña incorrecta';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd4183d),
              ),
              child: const Text('Eliminar Cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  // Paso 1: popup que explica para qué sirve la función de cuidador.
  void _showEnableCaregiverInfo(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.people_alt_outlined,
            color: Color(0xFF1A56DB), size: 40),
        title: const Text('Función de cuidador'),
        content: const Text(
          'Esta función te permite cuidar a otra persona (por ejemplo un adulto '
          'mayor o familiar): podrás crear su cuenta, gestionar sus medicamentos '
          'y horarios, y recibir sus alertas de emergencia (SOS) y avisos de '
          'medicamentos no tomados.\n\n'
          'Para activarla te enviaremos un código de verificación a tu correo.',
          textAlign: TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await authProvider.sendActionCode(
                  authProvider.userEmail, 'activar la función de cuidador');
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Código enviado a ${authProvider.userEmail}'
                      : (authProvider.error ?? 'No se pudo enviar el código')),
                ),
              );
              if (ok && context.mounted) {
                _showEnableCaregiverCode(context, authProvider);
              }
            },
            child: const Text('Enviar código',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Paso 2: ingresar el código para activar.
  void _showEnableCaregiverCode(BuildContext context, AuthProvider authProvider) {
    final codeController = TextEditingController();
    String errorMessage = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Activar función de cuidador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa el código que enviamos a ${authProvider.userEmail}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(errorMessage,
                      style: const TextStyle(color: Color(0xFFd4183d))),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB)),
              onPressed: () async {
                final ok =
                    await authProvider.enableCaregiver(codeController.text.trim());
                if (ok) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Función de cuidador activada!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } else {
                  setLocal(() => errorMessage =
                      authProvider.error ?? 'Código incorrecto o vencido');
                }
              },
              child: const Text('Activar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFd4183d)),
            ),
          ),
        ],
      ),
    );
  }
}
