import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/calendar_service.dart';
import '../services/push_service.dart';

/// Un control médico (cita) del usuario.
class MedicalControl {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final TimeOfDay time;
  // ID del evento creado en el calendario del teléfono (para editar/borrar).
  String? calendarEventId;

  MedicalControl({
    String? id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    this.calendarEventId,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Fecha y hora completas de la cita.
  DateTime get dateTime =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  /// ID estable para la notificación local (derivado del id).
  int get notificationId => id.hashCode & 0x7fffffff;

  MedicalControl copyWith({
    String? id,
    String? doctorName,
    String? specialty,
    DateTime? date,
    TimeOfDay? time,
    String? calendarEventId,
  }) =>
      MedicalControl(
        id: id ?? this.id,
        doctorName: doctorName ?? this.doctorName,
        specialty: specialty ?? this.specialty,
        date: date ?? this.date,
        time: time ?? this.time,
        calendarEventId: calendarEventId ?? this.calendarEventId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'specialty': specialty,
        'date': date.toIso8601String(),
        'hour': time.hour,
        'minute': time.minute,
        'calendarEventId': calendarEventId,
      };

  factory MedicalControl.fromJson(Map<String, dynamic> json) => MedicalControl(
        id: json['id'],
        doctorName: json['doctorName'] ?? '',
        specialty: json['specialty'] ?? '',
        date: DateTime.parse(json['date']),
        time: TimeOfDay(hour: json['hour'] ?? 0, minute: json['minute'] ?? 0),
        calendarEventId: json['calendarEventId'],
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

  /// Texto del evento/recordatorio.
  String _eventTitle(MedicalControl c) => 'Control médico: ${c.specialty}';
  String _eventDesc(MedicalControl c) => c.doctorName.isNotEmpty
      ? 'Con ${c.doctorName} (CuidApp)'
      : 'Agendado desde CuidApp';

  Future<void> add(MedicalControl control) async {
    _controls.add(control);
    notifyListeners();
    await _persist();
    await _sync(control); // calendario + recordatorio 2h antes
    await _persist();
  }

  Future<void> update(int index, MedicalControl control) async {
    if (index < 0 || index >= _controls.length) return;
    // Conservar id y el evento de calendario existente
    final old = _controls[index];
    final merged = control.copyWith(
      id: old.id,
      calendarEventId: old.calendarEventId,
    );
    _controls[index] = merged;
    notifyListeners();
    await _persist();
    await _sync(merged); // actualiza el mismo evento y reprograma el recordatorio
    await _persist();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _controls.length) return;
    final c = _controls[index];
    _controls.removeAt(index);
    notifyListeners();
    await _persist();
    // Borrar del calendario y cancelar el recordatorio
    if (c.calendarEventId != null) {
      await CalendarService.deleteEvent(c.calendarEventId!);
    }
    await PushService.cancelReminder(c.notificationId);
  }

  /// Crea/actualiza el evento en el calendario y programa la notificación 2h antes.
  Future<void> _sync(MedicalControl control) async {
    final eventId = await CalendarService.upsertEvent(
      eventId: control.calendarEventId,
      title: _eventTitle(control),
      description: _eventDesc(control),
      start: control.dateTime,
    );
    if (eventId != null) control.calendarEventId = eventId;

    await PushService.scheduleAppointmentReminder(
      id: control.notificationId,
      title: 'Control médico próximo',
      body: '${control.specialty}'
          '${control.doctorName.isNotEmpty ? " con ${control.doctorName}" : ""}'
          ' en 2 horas',
      appointment: control.dateTime,
    );
  }
}
