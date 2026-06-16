import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  /// Inicializa Firebase, permisos y el canal local. Llamar una vez al arrancar.
  /// No lanza excepciones: si algo falla (p. ej. web sin config), solo lo ignora.
  static Future<void> initialize() async {
    if (_initialized) return;

    // El push de FCM aquí está pensado para móvil. En web lo omitimos para no
    // requerir configuración adicional (VAPID) y no romper la ejecución en Chrome.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp();

      // Notificaciones locales (para mostrar el push cuando la app está abierta)
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);
      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_channel);
      await androidImpl?.createNotificationChannel(_sosChannel);

      // Permiso (Android 13+ / iOS)
      await FirebaseMessaging.instance.requestPermission();

      // Handler de segundo plano
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Mensajes en primer plano: los mostramos con la notificación local
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      _initialized = true;
    } catch (e) {
      debugPrint('[PushService] No se pudo inicializar el push: $e');
    }
  }

  static void _showForegroundNotification(RemoteMessage message) {
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
