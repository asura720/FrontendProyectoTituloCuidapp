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
      _medications.add(Medication.fromJson(data));
      notifyListeners();
    } catch (_) {}
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
