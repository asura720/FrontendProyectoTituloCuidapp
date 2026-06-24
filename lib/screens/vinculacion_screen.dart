import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/vinculacion_service.dart';
import '../widgets/app_header.dart';
import 'patient_medications_screen.dart';

class VinculacionScreen extends StatefulWidget {
  const VinculacionScreen({super.key});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen> {
  List<Map<String, dynamic>> _pacientes = [];
  Map<String, dynamic>? _titular;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final role = auth.currentUser?.role ?? 'INDEPENDIENTE';

    try {
      if (role == 'TITULAR' || role == 'INDEPENDIENTE') {
        final pacientes = await VinculacionService.getMisPacientes();
        setState(() => _pacientes = pacientes);
      }
      if (role == 'PACIENTE') {
        final titular = await VinculacionService.getMiTitular();
        setState(() => _titular = titular);
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _abrirCrearPaciente() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CrearPacienteModal(),
    );
    if (creado == true) {
      await _cargarDatos();
      // El rol del titular pudo cambiar de INDEPENDIENTE a TITULAR
      if (mounted) await context.read<AuthProvider>().refreshProfile();
    }
  }

  Future<void> _desvincular(String pacienteId, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desvincular paciente'),
        content: Text('¿Desvincular a $nombre? Volverá a ser un usuario independiente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desvincular', style: TextStyle(color: Color(0xFFd4183d))),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await VinculacionService.desvincular(pacienteId);
      _cargarDatos();
    }
  }

  Future<void> _responderSolicitud(String pacienteId, bool aprobar) async {
    await VinculacionService.responderSolicitud(pacienteId, aprobar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aprobar ? 'Permiso autorizado' : 'Solicitud rechazada'),
          backgroundColor: aprobar ? const Color(0xFF10B981) : const Color(0xFFd4183d),
        ),
      );
    }
    _cargarDatos();
  }

  Future<void> _cambiarPermiso(String pacienteId, bool habilitar) async {
    await VinculacionService.responderSolicitud(pacienteId, habilitar);
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role ?? 'INDEPENDIENTE';

    return Scaffold(
      appBar: gradientAppBar('Cuidador', actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoleChip(role: role),
                  const SizedBox(height: 24),
                  if (role == 'PACIENTE') _buildVistaPaciente(),
                  if (role != 'PACIENTE') _buildVistaTitular(),
                ],
              ),
            ),
    );
  }

  Widget _buildVistaPaciente() {
    if (_titular == null) {
      return const Center(
        child: Text('No tienes un cuidador vinculado aún.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1A56DB),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(_titular!['name'] ?? ''),
        subtitle: Text(_titular!['email'] ?? ''),
        trailing: const Icon(Icons.favorite, color: Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildVistaTitular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _abrirCrearPaciente,
            icon: const Icon(Icons.person_add),
            label: const Text('Crear cuenta de paciente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Mis pacientes (${_pacientes.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_pacientes.isEmpty)
          const Text('Aún no tienes pacientes vinculados.',
              style: TextStyle(color: Colors.grey))
        else
          ..._pacientes.map(_buildPacienteCard),
      ],
    );
  }

  Widget _buildPacienteCard(Map<String, dynamic> p) {
    final id = p['id'].toString();
    final nombre = p['name'] ?? '';
    final puedeGestionar = p['puedeGestionar'] == true;
    final solicitudPendiente = p['solicitudPendiente'] == true;
    final confirmado = p['confirmado'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.elderly, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(p['email'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off, color: Color(0xFFd4183d)),
                  onPressed: () => _desvincular(id, nombre),
                ),
              ],
            ),
            if (!confirmado) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mark_email_unread_outlined,
                        color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pendiente: el paciente debe confirmar el vínculo desde el correo que le enviamos.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (solicitudPendiente) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.notifications_active, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Solicita permiso para gestionar sus medicamentos',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _responderSolicitud(id, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Autorizar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _responderSolicitud(id, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFd4183d),
                              ),
                              child: const Text('Rechazar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      puedeGestionar ? Icons.lock_open : Icons.lock_outline,
                      size: 16,
                      color: puedeGestionar ? const Color(0xFF10B981) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        puedeGestionar
                            ? 'Puede gestionar sus propios medicamentos'
                            : 'Solo tú gestionas sus medicamentos',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    Switch(
                      value: puedeGestionar,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (v) => _cambiarPermiso(id, v),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientMedicationsScreen(
                        patientId: id,
                        patientName: nombre,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Gestionar medicamentos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CrearPacienteModal extends StatefulWidget {
  const _CrearPacienteModal();

  @override
  State<_CrearPacienteModal> createState() => _CrearPacienteModalState();
}

class _CrearPacienteModalState extends State<_CrearPacienteModal> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _birthDate;
  String? _bloodType;
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 70),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _guardar() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Nombre, correo y contraseña son obligatorios');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'La contraseña debe tener al menos 4 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await VinculacionService.crearPaciente(
        name: name,
        email: email,
        password: password,
        birthDate: _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        bloodType: _bloodType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Paciente creado. Le enviamos un correo para que confirme el vínculo.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['message'] ?? 'Error al crear el paciente';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Crear cuenta de paciente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                  'Le enviaremos un correo para que confirme el vínculo. Entrará con el correo y contraseña que definas.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento (opcional)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthDate != null
                        ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _birthDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _bloodType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre (opcional)',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _bloodTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFd4183d), fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Crear paciente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final config = switch (role) {
      'TITULAR' => ('Titular / Cuidador', const Color(0xFF1A56DB), Icons.manage_accounts),
      'PACIENTE' => ('Paciente', const Color(0xFF10B981), Icons.elderly),
      _ => ('Independiente', Colors.grey, Icons.person_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: config.$2.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.$2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.$3, color: config.$2, size: 20),
          const SizedBox(width: 8),
          Text('Rol: ${config.$1}',
              style: TextStyle(color: config.$2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
