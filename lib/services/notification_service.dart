import 'api_service.dart';

/// Llamadas al microservicio de notificaciones (a través del API Gateway).
class NotificationService {
  /// Registra el token FCM del dispositivo para un usuario.
  static Future<void> registerToken(String userId, String token) async {
    await ApiService.dio.post('/api/notifications/token', data: {
      'userId': int.tryParse(userId),
      'token': token,
    });
  }

  /// Pide al backend que envíe el push de bienvenida al usuario recién registrado.
  static Future<void> sendWelcome(String userId, String name) async {
    await ApiService.dio.post('/api/notifications/welcome', data: {
      'userId': int.tryParse(userId),
      'name': name,
    });
  }

  /// Envía una alerta SOS al cuidador. Devuelve a cuántos dispositivos se envió.
  static Future<int> sendSos(String caregiverId, String patientName) async {
    final response = await ApiService.dio.post('/api/notifications/sos', data: {
      'caregiverId': int.tryParse(caregiverId),
      'patientName': patientName,
    });
    final data = Map<String, dynamic>.from(response.data);
    return (data['sent'] as num?)?.toInt() ?? 0;
  }
}
