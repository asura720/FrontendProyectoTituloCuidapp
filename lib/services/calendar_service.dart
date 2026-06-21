import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// Integra los controles médicos con el calendario del teléfono
/// (incluye Google Calendar si la cuenta está sincronizada).
class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// Pide permiso de calendario si hace falta. Devuelve true si está concedido.
  static Future<bool> _ensurePermission() async {
    try {
      var res = await _plugin.hasPermissions();
      if (res.isSuccess && res.data == true) return true;
      res = await _plugin.requestPermissions();
      return res.isSuccess && res.data == true;
    } catch (_) {
      return false;
    }
  }

  /// Devuelve el id de un calendario donde se pueda escribir (prefiere el
  /// predeterminado / cuenta de Google), o null.
  static Future<String?> _writableCalendarId() async {
    final result = await _plugin.retrieveCalendars();
    final cals = result.data;
    if (cals == null || cals.isEmpty) return null;
    final writables = cals.where((c) => c.isReadOnly != true).toList();
    if (writables.isEmpty) return null;
    final def = writables.where((c) => c.isDefault == true).toList();
    return (def.isNotEmpty ? def.first : writables.first).id;
  }

  /// Crea o actualiza el evento de un control. Devuelve el id del evento
  /// (el mismo si se actualizó), o null si no se pudo.
  static Future<String?> upsertEvent({
    String? eventId,
    required String title,
    required String description,
    required DateTime start,
  }) async {
    if (kIsWeb) return null;
    try {
      if (!await _ensurePermission()) return null;
      final calendarId = await _writableCalendarId();
      if (calendarId == null) return null;

      final startTz = tz.TZDateTime.from(start, tz.local);
      final endTz = startTz.add(const Duration(hours: 1));

      final event = Event(
        calendarId,
        eventId: eventId, // si viene, se ACTUALIZA ese evento
        title: title,
        description: description,
        start: startTz,
        end: endTz,
      );

      final res = await _plugin.createOrUpdateEvent(event);
      if (res != null && res.isSuccess) return res.data;
      return eventId;
    } catch (_) {
      return eventId;
    }
  }

  /// Borra el evento del calendario.
  static Future<void> deleteEvent(String eventId) async {
    if (kIsWeb) return;
    try {
      if (!await _ensurePermission()) return;
      final calendarId = await _writableCalendarId();
      if (calendarId == null) return;
      await _plugin.deleteEvent(calendarId, eventId);
    } catch (_) {}
  }
}
