import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  List<Medication> _medications = [];
  bool _isLoading = false;

  List<Medication> get medications => [..._medications];
  bool get isLoading => _isLoading;

  Future<void> loadMedications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await MedicationService.getMedications(userId);
      _medications = data.map((m) => Medication.fromJson(m)).toList();
    } catch (_) {
      _medications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(Medication med) async {
    try {
      final data = await MedicationService.createMedication(med.toJson());
      final created = Medication.fromJson(data);
      _medications.add(created);
      notifyListeners();
      // Si el medicamento corresponde hoy, marca como tomadas las dosis
      // cuyo horario ya pasó (así no alertan apenas se agrega).
      await _autoMarkPastDoses(created);
    } catch (_) {}
  }

  /// Marca como tomadas las dosis de hoy cuyo horario ya pasó.
  Future<void> _autoMarkPastDoses(Medication med) async {
    if (!med.isScheduledToday()) return;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (final t in med.times) {
      final parts = t.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      if (h * 60 + m <= nowMinutes && !med.isDoseTakenToday(t)) {
        await markDose(med.id, t);
      }
    }
  }

  Future<void> editMedication(String id, Medication newMed) async {
    try {
      final data = await MedicationService.updateMedication(id, newMed.toJson());
      final index = _medications.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _medications[index] = Medication.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteMedication(String id) async {
    try {
      await MedicationService.deleteMedication(id);
      _medications.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleMedicationTaken(String id) async {
    try {
      final data = await MedicationService.toggleMedication(id);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _medications[index] = Medication.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Marca/desmarca una dosis puntual de hoy por horario ("HH:mm").
  Future<void> markDose(String id, String time, {bool taken = true}) async {
    try {
      final data = await MedicationService.markDose(id, time, taken: taken);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index >= 0) {
        _medications[index] = Medication.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get weeklyAdherence {
    final today = DateTime.now();
    final days = <Map<String, dynamic>>[];
    int daysToMonday = today.weekday - 1;
    final monday = today.subtract(Duration(days: daysToMonday));
    final daysNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      days.add({
        'day': daysNames[i],
        'percentage': _calculateAdherenceForDay(dayDate),
        'date': dayDate,
      });
    }
    return days;
  }

  int _calculateAdherenceForDay(DateTime date) {
    if (_medications.isEmpty) return 0;
    final takenCount = _medications.where((med) {
      if (med.takenDateTime == null) return false;
      return med.takenDateTime!.year == date.year &&
          med.takenDateTime!.month == date.month &&
          med.takenDateTime!.day == date.day;
    }).length;
    return ((takenCount / _medications.length) * 100).toInt();
  }

  int getTakenTodayCount() {
    final today = DateTime.now();
    return _medications.where((med) {
      if (med.takenDateTime == null) return false;
      final t = med.takenDateTime!;
      return t.year == today.year && t.month == today.month && t.day == today.day;
    }).length;
  }

  int getTodayAdherence() {
    if (_medications.isEmpty) return 0;
    return ((getTakenTodayCount() / _medications.length) * 100).toInt();
  }

  bool isTakenToday(String medicationId) {
    final med = _medications.firstWhere(
      (m) => m.id == medicationId,
      orElse: () => Medication(
        id: '', name: '', dosage: '', frequency: '', times: [],
        containerColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1A56DB),
      ),
    );
    if (med.takenDateTime == null) return false;
    final today = DateTime.now();
    return med.takenDateTime!.year == today.year &&
        med.takenDateTime!.month == today.month &&
        med.takenDateTime!.day == today.day;
  }
}
