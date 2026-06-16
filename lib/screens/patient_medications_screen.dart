import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class PatientMedicationsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientMedicationsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientMedicationsScreen> createState() => _PatientMedicationsScreenState();
}

class _PatientMedicationsScreenState extends State<PatientMedicationsScreen> {
  List<Medication> _meds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await MedicationService.getMedications(widget.patientId);
      _meds = data.map((m) => Medication.fromJson(m)).toList();
    } catch (_) {
      _meds = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _eliminar(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Eliminar "$nombre"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFd4183d))),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await MedicationService.deleteMedication(id);
      _load();
    }
  }

  void _abrirForm([Medication? med]) {
    final nameCtrl = TextEditingController(text: med?.name ?? '');
    final dosageCtrl = TextEditingController(text: med?.dosage ?? '');
    final freqCtrl = TextEditingController(text: med?.frequency ?? '1 vez al día');
    final timesCtrl = TextEditingController(text: med?.times.join(', ') ?? '');
    String? error;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                  Text(med == null ? 'Nuevo medicamento' : 'Editar medicamento',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.medication_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosis (ej: 1 comprimido)',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: freqCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                      prefixIcon: Icon(Icons.repeat),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: timesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Horarios (separados por coma, ej: 08:00, 20:00)',
                      prefixIcon: Icon(Icons.schedule),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(color: Color(0xFFd4183d))),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                setModal(() => error = 'El nombre es obligatorio');
                                return;
                              }
                              setModal(() {
                                saving = true;
                                error = null;
                              });

                              final times = timesCtrl.text
                                  .split(',')
                                  .map((t) => t.trim())
                                  .where((t) => t.isNotEmpty)
                                  .toList();

                              final data = {
                                'name': nameCtrl.text.trim(),
                                'dosage': dosageCtrl.text.trim(),
                                'frequency': freqCtrl.text.trim(),
                                'times': times,
                                'isTaken': false,
                              };

                              try {
                                if (med == null) {
                                  await MedicationService.createMedication(
                                    data,
                                    forUserId: widget.patientId,
                                  );
                                } else {
                                  await MedicationService.updateMedication(med.id, data);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                _load();
                              } catch (_) {
                                setModal(() {
                                  saving = false;
                                  error = 'Error al guardar';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(med == null ? 'Agregar' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicamentos de ${widget.patientName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Sin medicamentos registrados',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meds.length,
                  itemBuilder: (_, i) {
                    final m = _meds[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(Icons.medication, color: Color(0xFF1A56DB)),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${m.dosage} · ${m.frequency}'
                          '${m.times.isNotEmpty ? '\n${m.times.join(', ')}' : ''}',
                        ),
                        isThreeLine: m.times.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1A56DB)),
                              onPressed: () => _abrirForm(m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFd4183d)),
                              onPressed: () => _eliminar(m.id, m.name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A56DB),
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
