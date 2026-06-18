import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un control médico (cita) del usuario.
class MedicalControl {
  final String doctorName;
  final String specialty;
  final DateTime date;
  final TimeOfDay time;

  MedicalControl({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'doctorName': doctorName,
        'specialty': specialty,
        'date': date.toIso8601String(),
        'hour': time.hour,
        'minute': time.minute,
      };

  factory MedicalControl.fromJson(Map<String, dynamic> json) => MedicalControl(
        doctorName: json['doctorName'] ?? '',
        specialty: json['specialty'] ?? '',
        date: DateTime.parse(json['date']),
        time: TimeOfDay(hour: json['hour'] ?? 0, minute: json['minute'] ?? 0),
      );
}

/// Maneja la lista de controles médicos y la persiste en el dispositivo
/// (shared_preferences), para que sobreviva cambios de pestaña y reinicios.
class ControlsProvider extends ChangeNotifier {
  static const _storageKey = 'medical_controls';

  final List<MedicalControl> _controls = [];
  bool _loaded = false;

  List<MedicalControl> get controls => List.unmodifiable(_controls);
  int get count => _controls.length;

  /// Próximo control (hoy o futuro), o null.
  MedicalControl? get proximo {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final futuros = _controls.where((c) {
      final d = DateTime(c.date.year, c.date.month, c.date.day);
      return !d.isBefore(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return futuros.isEmpty ? null : futuros.first;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _controls
          ..clear()
          ..addAll(list.map((e) => MedicalControl.fromJson(
              Map<String, dynamic>.from(e))));
      }
    } catch (_) {
      // Si los datos guardados están corruptos, empezamos vacío.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _storageKey, jsonEncode(_controls.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(MedicalControl control) async {
    _controls.add(control);
    notifyListeners();
    await _persist();
  }

  Future<void> update(int index, MedicalControl control) async {
    if (index < 0 || index >= _controls.length) return;
    _controls[index] = control;
    notifyListeners();
    await _persist();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _controls.length) return;
    _controls.removeAt(index);
    notifyListeners();
    await _persist();
  }
}
