import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/medication_provider.dart';
import '../providers/auth_provider.dart';
import '../services/vinculacion_service.dart';
import '../models/medication.dart';
import '../widgets/app_header.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  // El paciente sin permiso no puede agregar; se le ofrece solicitarlo al cuidador
  Future<void> _handleAdd(BuildContext context) async {
    final role = context.read<AuthProvider>().currentUser?.role ?? 'INDEPENDIENTE';

    if (role != 'PACIENTE') {
      _showForm(context);
      return;
    }

    try {
      final permiso = await VinculacionService.getMiPermiso();
      if (!context.mounted) return;
      if (permiso['puedeGestionar'] == true) {
        _showForm(context);
      } else {
        _showSolicitarPermiso(context, permiso['solicitudPendiente'] == true);
      }
    } catch (_) {
      // Paciente sin cuidador vinculado: gestiona normalmente
      if (context.mounted) _showForm(context);
    }
  }

  void _showSolicitarPermiso(BuildContext context, bool yaPendiente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: Text(yaPendiente
            ? 'Ya enviaste una solicitud. Espera a que tu cuidador la autorice.'
            : 'Para agregar tus propios medicamentos necesitas que tu cuidador te autorice. ¿Enviar solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          if (!yaPendiente)
            ElevatedButton(
              onPressed: () async {
                try {
                  await VinculacionService.solicitarPermiso();
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud enviada a tu cuidador'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Solicitar permiso'),
            ),
        ],
      ),
    );
  }

  // Confirmación antes de eliminar un medicamento.
  void _confirmDelete(
      BuildContext context, MedicationProvider provider, Medication med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 40),
        title: const Text('Eliminar medicamento'),
        content: Text(
          '¿Seguro que quieres eliminar "${med.name}"? '
          'Se borrarán también sus recordatorios.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () {
              provider.deleteMedication(med.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${med.name}" eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, [Medication? medication]) {
    final nameController = TextEditingController(text: medication?.name ?? '');
    final dosageController = TextEditingController(
      text: medication?.dosage ?? '',
    );
    // La frecuencia ("N veces al día") se deriva del número de horarios.
    final List<String> selectedTimes =
        List<String>.from(medication?.times ?? const []);
    // Días seleccionados (1=Lun ... 7=Dom). Vacío = todos los días.
    final List<String> selectedDays =
        List<String>.from(medication?.days ?? const []);
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final SpeechToText speech = SpeechToText();
    bool listening = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
        top: false,
        child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                medication == null
                    ? 'Añadir Medicamento'
                    : 'Editar Medicamento',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              // Dictado por voz: llena nombre, dosis y hora
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        listening ? const Color(0xFFD32F2F) : const Color(0xFF1A56DB),
                    side: BorderSide(
                      color: listening
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF1A56DB),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(listening ? Icons.mic : Icons.mic_none),
                  label: Text(
                    listening
                        ? 'Escuchando... habla ahora'
                        : 'Dictar por voz',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: listening
                      ? null
                      : () async {
                          final available = await speech.initialize(
                            onStatus: (s) {
                              if (s == 'done' || s == 'notListening') {
                                setModalState(() => listening = false);
                              }
                            },
                            onError: (_) =>
                                setModalState(() => listening = false),
                          );
                          if (!available) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Micrófono no disponible o permiso denegado'),
                              ),
                            );
                            return;
                          }
                          setModalState(() => listening = true);
                          speech.listen(
                            localeId: 'es_CL',
                            listenFor: const Duration(seconds: 12),
                            pauseFor: const Duration(seconds: 4),
                            onResult: (res) {
                              if (res.finalResult) {
                                final p = _parseVoiceMedication(
                                    res.recognizedWords);
                                setModalState(() {
                                  if (p.name != null && p.name!.isNotEmpty) {
                                    nameController.text = p.name!;
                                  }
                                  if (p.dosage != null) {
                                    dosageController.text = p.dosage!;
                                  }
                                  for (final t in p.times) {
                                    if (!selectedTimes.contains(t)) {
                                      selectedTimes.add(t);
                                    }
                                  }
                                  selectedTimes.sort();
                                  listening = false;
                                });
                              }
                            },
                          );
                        },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ej: "Paracetamol 500 mg a las 8 de la mañana"',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del medicamento',
                  prefixIcon: const Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF1A56DB),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosis (ej: 50mg)',
                  prefixIcon: const Icon(
                    Icons.scale_outlined,
                    color: Color(0xFF1A56DB),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Frecuencia: se calcula sola según la cantidad de horarios
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined, color: Color(0xFF1A56DB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _frequencyLabel(selectedTimes.length),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Selector de horarios
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Horarios',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...selectedTimes.map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: const Color(0xFFE8EEFB),
                      labelStyle: const TextStyle(
                        color: Color(0xFF1A56DB),
                        fontWeight: FontWeight.w600,
                      ),
                      deleteIconColor: const Color(0xFF1A56DB),
                      onDeleted: () =>
                          setModalState(() => selectedTimes.remove(t)),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: Color(0xFF1A56DB)),
                    label: const Text('Agregar hora'),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        final f =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        if (!selectedTimes.contains(f)) {
                          setModalState(() {
                            selectedTimes.add(f);
                            selectedTimes.sort();
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Selector de días de la semana
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Días de la semana',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayNum = (i + 1).toString(); // 1=Lun ... 7=Dom
                  final selected = selectedDays.contains(dayNum);
                  return GestureDetector(
                    onTap: () => setModalState(() {
                      if (selected) {
                        selectedDays.remove(dayNum);
                      } else {
                        selectedDays.add(dayNum);
                      }
                    }),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFFF5F7FB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1A56DB)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedDays.isEmpty
                      ? 'Sin selección = todos los días'
                      : 'Solo los días marcados',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    final medProvider = Provider.of<MedicationProvider>(
                      context,
                      listen: false,
                    );
                    final newMed = Medication(
                      id: medication?.id ?? DateTime.now().toString(),
                      name: nameController.text,
                      dosage: dosageController.text,
                      frequency: _frequencyLabel(selectedTimes.length),
                      times: selectedTimes,
                      days: selectedDays,
                      containerColor:
                          medication?.containerColor ?? const Color(0xFFf3f3f5),
                      iconColor:
                          medication?.iconColor ?? const Color(0xFF1A56DB),
                      isTaken: medication?.isTaken ?? false,
                      takenDateTime: medication?.takenDateTime,
                    );

                    if (medication == null) {
                      medProvider.addMedication(newMed);
                    } else {
                      medProvider.editMedication(medication.id, newMed);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  /// Marca una dosis. Si se pulsa antes de la hora programada, pide confirmación.
  Future<void> _confirmAndMarkDose(
    BuildContext context,
    MedicationProvider provider,
    Medication med,
    String time,
  ) async {
    final parts = time.split(':');
    final now = DateTime.now();
    DateTime? doseTime;
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        doseTime = DateTime(now.year, now.month, now.day, h, m);
      }
    }

    // Si todavía no es la hora de la dosis, confirmar antes de marcar
    if (doseTime != null && now.isBefore(doseTime)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 40),
          title: const Text('¿Estás seguro?'),
          content: Text(
            'Todavía no es la hora de esta dosis (programada a las $time). '
            '¿Confirmas que ya tomaste ${med.name}?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, ya la tomé',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await provider.markDose(med.id, time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      body: Consumer<MedicationProvider>(
        builder: (context, medProvider, _) {
          final medications = medProvider.medications;

          return CustomScrollView(
            slivers: [
              sectionSliverAppBar('Medicinas'),
              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y contador
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mis Medicamentos',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                '${medications.length} medicamentos activos',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Resumen semanal
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen semanal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Gráfica de barras de la semana
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                medProvider.weeklyAdherence.length,
                                (index) {
                                  final data =
                                      medProvider.weeklyAdherence[index];
                                  final percentage =
                                      (data['percentage'] as int) / 100;

                                  return Column(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 80 * percentage,
                                              decoration: BoxDecoration(
                                                color: percentage == 1.0
                                                    ? const Color(0xFF10B981)
                                                    : percentage >= 0.5
                                                    ? const Color(0xFFFCD34D)
                                                    : const Color(0xFFEF4444),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        data['day'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${data['percentage']}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Título de medicamentos
                      const Text(
                        'Medicamentos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Lista de medicamentos
                      ...medications.asMap().entries.map((entry) {
                        Medication med = entry.value;
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: med.containerColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.medication_outlined,
                                              color: med.iconColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                med.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                              Text(
                                                med.dosage,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFF030213),
                                            ),
                                            onPressed: () =>
                                                _showForm(context, med),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _confirmDelete(context,
                                                    medProvider, med),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    med.frequency,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDays(med.days),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Chips de horarios: verde = dosis tomada hoy
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: med.times.map((time) {
                                      final taken =
                                          med.isDoseTakenToday(time);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: taken
                                              ? const Color(0xFFECFDF5)
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              taken
                                                  ? Icons.check_circle
                                                  : Icons.access_time,
                                              size: 12,
                                              color: taken
                                                  ? Colors.green[700]
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              time,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: taken
                                                    ? Colors.green[700]
                                                    : Colors.grey[600],
                                                fontWeight: taken
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  // Próxima dosis + botón "Tomar ahora"
                                  Builder(builder: (_) {
                                    // No corresponde hoy: no se puede marcar
                                    if (!med.isScheduledToday()) {
                                      return Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.event_busy,
                                                color: Colors.grey[500],
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'No corresponde hoy (${_formatDays(med.days)})',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final total = med.times.length;
                                    // Sin horario definido: marcar como tomado hoy
                                    if (total == 0) {
                                      final marcado =
                                          med.isMarkedTodayNoTime();
                                      if (marcado) {
                                        return Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green[700],
                                                  size: 18),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tomado hoy',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            padding: const EdgeInsets
                                                .symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(Icons.check,
                                              color: Colors.white, size: 20),
                                          label: const Text(
                                            'Marcar como tomado',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onPressed: () => medProvider
                                              .markDose(med.id, '--:--'),
                                        ),
                                      );
                                    }
                                    final pending =
                                        med.pendingTimesToday();
                                    final takenCount =
                                        med.takenCountToday();
                                    if (pending.isEmpty) {
                                      return Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.green[700],
                                                size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Completado hoy ($takenCount/$total)',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final next = pending.first;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Próxima dosis: $next  •  $takenCount/$total tomadas hoy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: const Icon(Icons.check,
                                                color: Colors.white,
                                                size: 20),
                                            label: Text(
                                              'Tomar ahora ($next)',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _confirmAndMarkDose(
                                                    context,
                                                    medProvider,
                                                    med,
                                                    next),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                      const SizedBox(
                        height: 40,
                      ), // Espacio para el botón flotante
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A56DB),
        elevation: 4,
        onPressed: () => _handleAdd(context),
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: const Text(
          'Agregar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Resultado del parseo de voz para un medicamento.
class _VoiceMed {
  final String? name;
  final String? dosage;
  final List<String> times;
  _VoiceMed({this.name, this.dosage, this.times = const []});
}

/// Interpreta una frase dictada y extrae nombre, dosis y uno o varios horarios.
/// Ej: "Paracetamol 500 mg a las 8 de la mañana y a las 8 de la noche"
///     -> name, "500 mg", ["08:00", "20:00"]
_VoiceMed _parseVoiceMedication(String raw) {
  final text = raw.toLowerCase().trim();
  if (text.isEmpty) return _VoiceMed();

  // Dosis: número + unidad
  String? dosage;
  final dose = RegExp(
          r'(\d+(?:[.,]\d+)?)\s*(miligramos|mg|mililitros|ml|microgramos|mcg|gramos|gr|gotas|unidades|ui|g)\b')
      .firstMatch(text);
  if (dose != null) {
    final value = dose.group(1)!.replaceAll(',', '.');
    dosage = '$value ${_normalizeUnit(dose.group(2)!)}';
  }

  // Horarios (puede haber varios)
  final times = _parseAllTimesEs(text);

  // Nombre: lo que va antes del primer número
  String? name;
  final firstDigit = RegExp(r'\d').firstMatch(text);
  name = (firstDigit != null && firstDigit.start > 0)
      ? text.substring(0, firstDigit.start)
      : text;
  name = name.replaceAll(RegExp(r'\b(a la[s]?|tomar|el|la|de)\b\s*$'), '').trim();
  name = name.isEmpty ? null : _capitalize(name);

  return _VoiceMed(name: name, dosage: dosage, times: times);
}

String _normalizeUnit(String u) {
  switch (u) {
    case 'miligramos':
      return 'mg';
    case 'mililitros':
      return 'ml';
    case 'gramos':
    case 'gr':
      return 'g';
    case 'microgramos':
      return 'mcg';
    case 'unidades':
      return 'ui';
    default:
      return u;
  }
}

/// Extrae TODOS los horarios mencionados en la frase, cada uno con su AM/PM.
/// Ej: "a las 8 de la mañana y a las 8 de la noche" -> ["08:00", "20:00"]
List<String> _parseAllTimesEs(String text) {
  final result = <String>{};
  // Cada coincidencia: hora (con o sin :mm), opcional "y media/cuarto", y un
  // indicador AM/PM. Solo se acepta si hay contexto de hora (para no tomar la dosis).
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
    final yQual = mt.group(4); // " y media" / " y cuarto"
    final mer = (mt.group(5) ?? '').toLowerCase();

    // Requiere contexto para no confundir con la dosis (ej. "500 mg")
    final hasContext =
        prefix != null || mmStr != null || yQual != null || mer.isNotEmpty;
    if (!hasContext) continue;

    int h = hh;
    int min = mmStr != null ? (int.tryParse(mmStr) ?? 0) : 0;
    if (yQual != null) {
      min = yQual.contains('media') ? 30 : 15;
    }

    bool pm = false, am = false;
    if (RegExp(r'p\.?\s?m\.?').hasMatch(mer) ||
        mer.contains('tarde') ||
        mer.contains('noche')) {
      pm = true;
    } else if (RegExp(r'a\.?\s?m\.?').hasMatch(mer) ||
        mer.contains('mañana') ||
        mer.contains('manana') ||
        mer.contains('madrugada')) {
      am = true;
    }
    if (pm && h < 12) h += 12;
    if (am && h == 12) h = 0;

    if (h > 23 || min > 59) continue;
    result.add(_fmtTime(h, min));
  }

  final list = result.toList()..sort();
  return list;
}

String _fmtTime(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Texto de frecuencia derivado del número de horarios.
/// 0 -> "Sin horarios"; 1 -> "1 vez al día"; N -> "N veces al día".
String _frequencyLabel(int timesCount) {
  if (timesCount <= 0) return 'Sin horarios';
  if (timesCount == 1) return '1 vez al día';
  return '$timesCount veces al día';
}

/// Formatea la lista de días (1=Lun ... 7=Dom) a texto legible.
/// Vacío = "Todos los días"; lunes a viernes = "Lun a Vie".
String _formatDays(List<String> days) {
  if (days.isEmpty) return 'Todos los días';
  const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final nums = days
      .map((d) => int.tryParse(d) ?? 0)
      .where((n) => n >= 1 && n <= 7)
      .toSet()
      .toList()
    ..sort();
  if (nums.isEmpty) return 'Todos los días';
  if (nums.length == 7) return 'Todos los días';
  if (nums.length == 5 && nums.every((n) => n <= 5)) return 'Lun a Vie';
  if (nums.length == 2 && nums.contains(6) && nums.contains(7)) {
    return 'Fines de semana';
  }
  return nums.map((n) => names[n - 1]).join(', ');
}
