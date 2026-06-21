import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'notification_service.dart';

/// Manejador de mensajes en segundo plano (debe ser una función top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Cuando la app está en segundo plano, Android muestra la notificación
  // automáticamente si el mensaje trae bloque "notification". No hace falta más.
  await Firebase.initializeApp();
}

/// Encapsula toda la lógica de notificaciones push (FCM) + notificaciones locales.
///
/// Es tolerante: en web (Chrome) o si Firebase no está configurado, no rompe la
/// app; simplemente no hace nada. El push real funciona en un Android con
/// google-services.json y permisos concedidos.
class PushService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cuidapp_default',
    'Notificaciones CuidApp',
    description: 'Avisos y recordatorios de CuidApp',
    importance: Importance.high,
  );

  // Patrón de vibración fuerte y repetido para emergencias (ms: espera, vibra, ...)
  static final Int64List _sosVibration =
      Int64List.fromList([0, 800, 400, 800, 400, 800, 400, 1000]);

  // Canal dedicado para alertas SOS: máxima prioridad y vibración intensa.
  static final AndroidNotificationChannel _sosChannel =
      AndroidNotificationChannel(
    'cuidapp_sos',
    'Emergencias SOS',
    description: 'Alertas de emergencia enviadas por un paciente',
    importance: Importance.max,
    enableVibration: true,
    vibrationPattern: _sosVibration,
  );

  static bool _initialized = false;

  static const _notifEnabledKey = 'notifications_enabled';
  static bool _notificationsEnabled = true;

  /// Si el usuario tiene las notificaciones activadas (preferencia local).
  static bool get notificationsEnabled => _notificationsEnabled;

  /// Carga la preferencia guardada de notificaciones.
  static Future<void> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notifEnabledKey) ?? true;
    } catch (_) {
      _notificationsEnabled = true;
    }
  }

  /// Activa/desactiva las notificaciones. Cuando está desactivado, no se
  /// muestran avisos locales en primer plano.
  static Future<void> setEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifEnabledKey, enabled);
    } catch (_) {}
  }

  /// Inicializa Firebase, permisos y el canal local. Llamar una vez al arrancar.
  /// No lanza excepciones: si algo falla (p. ej. web sin config), solo lo ignora.
  static Future<void> initialize() async {
    if (_initialized) return;

    // Cargar preferencia de notificaciones (funciona también en web)
    await loadPreference();

    // El push de FCM aquí está pensado para móvil. En web lo omitimos para no
    // requerir configuración adicional (VAPID) y no romper la ejecución en Chrome.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Zona horaria para programar recordatorios locales.
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Santiago'));
    } catch (e) {
      debugPrint('[PushService] timezone init: $e');
    }

    // Notificaciones locales (independiente de Firebase, para que los
    // recordatorios programados funcionen aunque el push no esté configurado).
    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_channel);
      await androidImpl?.createNotificationChannel(_sosChannel);
      await androidImpl?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[PushService] notificaciones locales: $e');
    }

    // Firebase Cloud Messaging (push remoto). Si no está configurado, se ignora.
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } catch (e) {
      debugPrint('[PushService] No se pudo inicializar el push: $e');
    }

    _initialized = true;
  }

  /// Programa una notificación local para una cita/control, 2 horas antes.
  /// Si faltan menos de 2 horas, no programa nada.
  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String body,
    required DateTime appointment,
  }) async {
    if (kIsWeb) return;
    final reminderTime = appointment.subtract(const Duration(hours: 2));
    // Reprogramar: cancelamos cualquier recordatorio previo con este id.
    await cancelReminder(id);
    if (reminderTime.isBefore(DateTime.now())) return;
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[PushService] No se pudo programar recordatorio: $e');
    }
  }

  /// Cancela un recordatorio local programado.
  static Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.cancel(id);
    } catch (_) {}
  }

  static void _showForegroundNotification(RemoteMessage message) {
    // Si el usuario desactivó las notificaciones, no mostramos nada en primer plano
    if (!_notificationsEnabled) return;

    final notification = message.notification;
    if (notification == null) return;

    final isSos = message.data['type'] == 'sos';

    final androidDetails = isSos
        ? AndroidNotificationDetails(
            _sosChannel.id,
            _sosChannel.name,
            channelDescription: _sosChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            color: const Color(0xFFD32F2F),
            colorized: true,
            enableVibration: true,
            vibrationPattern: _sosVibration,
            icon: '@mipmap/ic_launcher',
          )
        : AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Obtiene el token FCM de este dispositivo (null en web o si falla).
  static Future<String?> getToken() async {
    if (kIsWeb || !_initialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[PushService] No se pudo obtener el token: $e');
      return null;
    }
  }

  /// Registra el token de este dispositivo en el backend para el usuario dado.
  /// Tolerante a fallos: nunca lanza.
  static Future<void> registerTokenForUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;
      await NotificationService.registerToken(userId, token);

      // Si el token cambia más adelante, lo volvemos a registrar
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        NotificationService.registerToken(userId, newToken).catchError((_) {});
      });
    } catch (e) {
      debugPrint('[PushService] No se pudo registrar el token: $e');
    }
  }
}
