import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/controls_provider.dart';
import '../utils/health_tips.dart';
import '../widgets/app_header.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  // Consejo elegido al entrar a la pestaña (cambia cada vez que se abre)
  late String _consejo;

  @override
  void initState() {
    super.initState();
    _consejo = randomHealthTip();
  }

  void _openModal({MedicalControl? existing, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: _ControlModal(
            initialControl: existing == null
                ? null
                : {
                    'doctorName': existing.doctorName,
                    'specialty': existing.specialty,
                    'date': existing.date,
                    'time': existing.time,
                  },
            onSaved: (data) {
              final control = MedicalControl(
                doctorName: data['doctorName'],
                specialty: data['specialty'],
                date: data['date'],
                time: data['time'],
              );
              final provider = context.read<ControlsProvider>();
              if (index != null) {
                provider.update(index, control);
              } else {
                provider.add(control);
              }
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int index, String doctorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar control'),
        content: Text('¿Eliminar el control con $doctorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFd4183d)),
            onPressed: () {
              context.read<ControlsProvider>().removeAt(index);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controlsProvider = context.watch<ControlsProvider>();
    final controls = controlsProvider.controls;
    final proximo = controlsProvider.proximo;

    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      body: CustomScrollView(
        slivers: [
          sectionSliverAppBar('Controles Médicos'),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de próximo control
                  _buildProximoControl(proximo),
                  const SizedBox(height: 24),

                  // Consejo de Salud
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consejo de Salud',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _consejo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título lista
                  const Text(
                    'Todos los Controles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF030213),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (controls.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes controles registrados\nAgrega uno con el botón +',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final control = controls[index];
                  return _ControlCard(
                    doctorName: control.doctorName,
                    specialty: control.specialty,
                    date: control.date,
                    time: control.time,
                    onEdit: () => _openModal(existing: control, index: index),
                    onDelete: () => _confirmDelete(index, control.doctorName),
                  );
                },
                childCount: controls.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A56DB),
        elevation: 4,
        onPressed: () => _openModal(),
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: const Text(
          'Agregar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProximoControl(MedicalControl? control) {
    if (control == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.grey[400], size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin próximos controles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF717182),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agrega un control médico con el botón +',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final date = control.date;
    final time = control.time;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final controlDay = DateTime(date.year, date.month, date.day);
    final daysLeft = controlDay.difference(today).inDays;

    final daysLabel = daysLeft == 0
        ? 'Hoy'
        : daysLeft == 1
            ? 'Mañana'
            : 'En $daysLeft días';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.medical_services, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Próximo Control',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            control.doctorName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            control.specialty,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(date),
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ControlCard({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.medical_services, color: Color(0xFF1A56DB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF030213),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF717182)),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A56DB)),
                          SizedBox(width: 10),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFd4183d)),
                          SizedBox(width: 10),
                          Text('Eliminar', style: TextStyle(color: Color(0xFFd4183d))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF717182)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('d \'de\' MMM, yyyy', 'es_ES').format(date),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF717182)),
                    const SizedBox(width: 8),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF717182)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlModal extends StatefulWidget {
  final Map<String, dynamic>? initialControl;
  final Function(Map<String, dynamic>) onSaved;

  const _ControlModal({this.initialControl, required this.onSaved});

  @override
  State<_ControlModal> createState() => _ControlModalState();
}

class _ControlModalState extends State<_ControlModal> {
  late final TextEditingController _doctorController;
  String? _selectedSpecialty;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final SpeechToText _speech = SpeechToText();
  bool _listening = false;

  // Categorías de especialidad médica
  final List<String> _specialties = [
    'Medicina General',
    'Cardiología',
    'Dermatología',
    'Endocrinología',
    'Gastroenterología',
    'Ginecología',
    'Kinesiología',
    'Nefrología',
    'Neurología',
    'Nutrición',
    'Odontología',
    'Oftalmología',
    'Oncología',
    'Otorrinolaringología',
    'Pediatría',
    'Psicología',
    'Psiquiatría',
    'Reumatología',
    'Traumatología',
    'Urología',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.initialControl;
    _doctorController = TextEditingController(text: existing?['doctorName'] ?? '');
    final esp = existing?['specialty'] as String?;
    if (esp != null && esp.isNotEmpty) {
      // Si la especialidad guardada no está en la lista, la agregamos para no perderla
      if (!_specialties.contains(esp)) _specialties.insert(_specialties.length - 1, esp);
      _selectedSpecialty = esp;
    }
    _selectedDate = existing?['date'] ?? DateTime.now();
    _selectedTime = existing?['time'] ?? TimeOfDay.now();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _save() {
    if (_doctorController.text.isEmpty ||
        _selectedSpecialty == null ||
        _selectedSpecialty!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }
    // El calendario y el recordatorio 2h antes los maneja el ControlsProvider.
    widget.onSaved({
      'doctorName': _doctorController.text.trim(),
      'specialty': _selectedSpecialty!,
      'date': _selectedDate,
      'time': _selectedTime,
    });
  }

  Future<void> _listen() async {
    if (_listening) return;
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Micrófono no disponible o permiso denegado')),
      );
      return;
    }
    setState(() => _listening = true);
    _speech.listen(
      localeId: 'es_CL',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 4),
      onResult: (res) {
        if (!res.finalResult) return;
        final p = _parseVoiceControl(res.recognizedWords, _specialties);
        setState(() {
          if (p.doctor != null && p.doctor!.isNotEmpty) {
            _doctorController.text = p.doctor!;
          }
          if (p.specialty != null) _selectedSpecialty = p.specialty;
          if (p.date != null) _selectedDate = p.date!;
          if (p.time != null) _selectedTime = p.time!;
          _listening = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialControl != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Text(
              isEditing ? 'Editar Control Médico' : 'Nuevo Control Médico',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            // Dictado por voz: llena doctor, especialidad, fecha y hora
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _listening
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF1A56DB),
                  side: BorderSide(
                    color: _listening
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF1A56DB),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                label: Text(
                  _listening ? 'Escuchando... habla ahora' : 'Dictar por voz',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _listening ? null : _listen,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ej: "Doctor Pérez cardiología el 15 de julio a las 10 de la mañana"',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doctorController,
              decoration: InputDecoration(
                labelText: 'Nombre del Doctor',
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1A56DB)),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecialty,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Especialidad',
                prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF1A56DB)),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              hint: const Text('Selecciona una categoría'),
              items: _specialties
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSpecialty = value),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF1A56DB), size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fecha del Control', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(_selectedDate),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_outlined, color: Color(0xFF1A56DB), size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hora del Control', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: _save,
                    child: Text(
                      isEditing ? 'Guardar cambios' : 'Agregar Control',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Resultado del parseo de voz para un control médico.
class _VoiceControl {
  final String? doctor;
  final String? specialty;
  final DateTime? date;
  final TimeOfDay? time;
  _VoiceControl({this.doctor, this.specialty, this.date, this.time});
}

/// Quita tildes y pasa a minúsculas para comparar.
String _norm(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ñ', 'n');

/// Interpreta una frase dictada para un control médico.
/// Ej: "Doctor Pérez cardiología el 15 de julio a las 10 de la mañana".
_VoiceControl _parseVoiceControl(String raw, List<String> specialties) {
  final low = raw.trim().toLowerCase();
  final norm = _norm(low);

  String? specialty;
  for (final esp in specialties) {
    if (esp == 'Otro') continue;
    final key = _norm(esp);
    final stem = key.length > 5 ? key.substring(0, 5) : key;
    if (norm.contains(key) || norm.contains(stem)) {
      specialty = esp;
      break;
    }
  }

  return _VoiceControl(
    doctor: _parseDoctor(low, specialties),
    specialty: specialty,
    date: _parseDateEs(norm),
    time: _parseTimeOfDayEs(low),
  );
}

DateTime? _parseDateEs(String norm) {
  final now = DateTime.now();
  if (norm.contains('pasado manana')) {
    return DateTime(now.year, now.month, now.day + 2);
  }
  const months = {
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
    'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
    'noviembre': 11, 'diciembre': 12,
  };
  final m =
      RegExp(r'(\d{1,2})\s+de\s+([a-z]+)(?:\s+de\s+(\d{4}))?').firstMatch(norm);
  if (m != null) {
    final day = int.tryParse(m.group(1)!);
    final mon = months[m.group(2)];
    final year = m.group(3) != null ? int.tryParse(m.group(3)!) : null;
    if (day != null && mon != null) {
      final y = year ?? now.year;
      var d = DateTime(y, mon, day);
      if (year == null && d.isBefore(DateTime(now.year, now.month, now.day))) {
        d = DateTime(y + 1, mon, day);
      }
      return d;
    }
  }
  if (norm.contains('hoy')) return DateTime(now.year, now.month, now.day);
  return null;
}

TimeOfDay? _parseTimeOfDayEs(String text) {
  final re = RegExp(
    r'(a\s+la[s]?\s+)?(\d{1,2})(?::(\d{2}))?(\s+y\s+(?:media|cuarto))?\s*'
    r'(a\.?\s?m\.?|p\.?\s?m\.?|de\s+la\s+mañana|de\s+la\s+manana|de\s+la\s+tarde|de\s+la\s+noche|de\s+la\s+madrugada|mañana|manana|tarde|noche|madrugada)?',
    caseSensitive: false,
  );
  for (final mt in re.allMatches(text)) {
    final prefix = mt.group(1);
    final hh = int.tryParse(mt.group(2) ?? '');
    if (hh == null) continue;
    final mmStr = mt.group(3);
    final yQual = mt.group(4);
    final mer = (mt.group(5) ?? '').toLowerCase();
    final hasContext =
        prefix != null || mmStr != null || yQual != null || mer.isNotEmpty;
    if (!hasContext) continue;

    int h = hh;
    int min = mmStr != null ? (int.tryParse(mmStr) ?? 0) : 0;
    if (yQual != null) min = yQual.contains('media') ? 30 : 15;

    final pm = RegExp(r'p\.?\s?m\.?').hasMatch(mer) ||
        mer.contains('tarde') ||
        mer.contains('noche');
    final am = !pm &&
        (RegExp(r'a\.?\s?m\.?').hasMatch(mer) ||
            mer.contains('mañana') ||
            mer.contains('manana') ||
            mer.contains('madrugada'));
    if (pm && h < 12) h += 12;
    if (am && h == 12) h = 0;
    if (h > 23 || min > 59) continue;
    return TimeOfDay(hour: h, minute: min);
  }
  return null;
}

String? _parseDoctor(String low, List<String> specialties) {
  final m = RegExp(
          r'\b(?:doctora|doctor|dra\.?|dr\.?)\s+([a-záéíóúñ]+(?:\s+[a-záéíóúñ]+)?)')
      .firstMatch(low);
  if (m == null) return null;
  final stops = {'el', 'la', 'de', 'del', 'a', 'las', 'con', 'para'};
  final specStems = specialties.where((e) => e != 'Otro').map((e) {
    final k = _norm(e);
    return k.length > 5 ? k.substring(0, 5) : k;
  }).toList();
  final words = m.group(1)!.split(RegExp(r'\s+')).where((w) {
    final nw = _norm(w);
    if (stops.contains(nw)) return false;
    for (final st in specStems) {
      if (nw.startsWith(st)) return false;
    }
    return true;
  }).toList();
  if (words.isEmpty) return null;
  final name = words
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
  return 'Dr. $name';
}
