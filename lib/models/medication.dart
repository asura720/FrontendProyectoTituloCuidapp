import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  // Días de la semana en que se toma (1=Lun ... 7=Dom). Vacío = todos los días.
  final List<String> days;
  // Dosis tomadas: cada entrada "YYYY-MM-DD|HH:mm".
  final List<String> takenDoses;
  final Color containerColor;
  final Color iconColor;
  bool isTaken;
  DateTime? takenDateTime;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.days = const [],
    this.takenDoses = const [],
    required this.containerColor,
    required this.iconColor,
    this.isTaken = false,
    this.takenDateTime,
  });

  /// Horarios pendientes de hoy (no marcados todavía), ordenados.
  List<String> pendingTimesToday() {
    final today = _todayStr();
    final sorted = [...times]..sort();
    return sorted
        .where((t) => !takenDoses.contains('$today|$t'))
        .toList();
  }

  /// Cuántas dosis de hoy ya se tomaron.
  int takenCountToday() {
    final today = _todayStr();
    return times.where((t) => takenDoses.contains('$today|$t')).length;
  }

  bool isDoseTakenToday(String time) =>
      takenDoses.contains('${_todayStr()}|$time');

  /// ¿Corresponde tomar este medicamento hoy? (sin días = todos los días)
  bool isScheduledToday() {
    if (days.isEmpty) return true;
    final wd = DateTime.now().weekday; // 1=Lun ... 7=Dom
    return days.contains(wd.toString());
  }

  /// Marca "sin horario" para hoy (medicamento sin horas definidas).
  bool isMarkedTodayNoTime() =>
      takenDoses.contains('${_todayStr()}|--:--');

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      try {
        return Color(int.parse(hex.replaceAll('#', ''), radix: 16));
      } catch (_) {
        return fallback;
      }
    }

    return Medication(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      times: json['times'] != null ? List<String>.from(json['times']) : [],
      days: json['days'] != null
          ? List<String>.from(json['days'].map((d) => d.toString()))
          : [],
      takenDoses: json['takenDoses'] != null
          ? List<String>.from(json['takenDoses'].map((d) => d.toString()))
          : [],
      containerColor: parseColor(json['containerColor'], const Color(0xFFE3F2FD)),
      iconColor: parseColor(json['iconColor'], const Color(0xFF1A56DB)),
      isTaken: json['isTaken'] ?? false,
      takenDateTime: json['takenDateTime'] != null
          ? DateTime.tryParse(json['takenDateTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'days': days,
      'containerColor': containerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase(),
      'iconColor': iconColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase(),
      'isTaken': isTaken,
    };
  }
}