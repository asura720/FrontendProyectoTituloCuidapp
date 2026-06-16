import 'notification_service.dart';
import 'vinculacion_service.dart';

/// Resultado del envío de un SOS.
class SosResult {
  final bool success;
  final int devicesNotified;
  final String message;

  SosResult({
    required this.success,
    required this.devicesNotified,
    required this.message,
  });
}

/// Lógica del botón de emergencia (SOS) que pulsa el paciente bajo tutela.
class SosService {
  /// Resuelve el cuidador (titular) del paciente y le envía la alerta SOS.
  static Future<SosResult> send(String patientName) async {
    try {
      final titular = await VinculacionService.getMiTitular();
      final caregiverId = titular['id']?.toString();
      final caregiverName = (titular['name'] ?? 'tu cuidador').toString();

      if (caregiverId == null) {
        return SosResult(
          success: false,
          devicesNotified: 0,
          message: 'No tienes un cuidador vinculado',
        );
      }

      final sent = await NotificationService.sendSos(caregiverId, patientName);

      if (sent == 0) {
        return SosResult(
          success: true,
          devicesNotified: 0,
          message:
              'Alerta registrada, pero $caregiverName no tiene la app abierta en su celular todavía.',
        );
      }
      return SosResult(
        success: true,
        devicesNotified: sent,
        message: 'Se avisó a $caregiverName. ¡Ayuda en camino!',
      );
    } catch (e) {
      return SosResult(
        success: false,
        devicesNotified: 0,
        message: 'No se pudo enviar el SOS. Revisa tu conexión.',
      );
    }
  }
}
