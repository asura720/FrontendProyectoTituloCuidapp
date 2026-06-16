import 'api_service.dart';

class VinculacionService {
  static Future<Map<String, dynamic>> crearPaciente({
    required String name,
    required String email,
    required String password,
    String? birthDate,
    String? bloodType,
  }) async {
    final response = await ApiService.dio.post('/api/auth/vincular/crear-paciente', data: {
      'name': name,
      'email': email,
      'password': password,
      if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
      if (bloodType != null && bloodType.isNotEmpty) 'bloodType': bloodType,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<List<Map<String, dynamic>>> getMisPacientes() async {
    final response = await ApiService.dio.get('/api/auth/vincular/mis-pacientes');
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> getMiTitular() async {
    final response = await ApiService.dio.get('/api/auth/vincular/mi-titular');
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> desvincular(String pacienteId) async {
    await ApiService.dio.delete('/api/auth/vincular/desvincular/$pacienteId');
  }

  // El paciente solicita permiso para gestionar sus propios medicamentos
  static Future<void> solicitarPermiso() async {
    await ApiService.dio.post('/api/auth/vincular/solicitar-permiso');
  }

  // El titular autoriza o rechaza la solicitud de un paciente
  static Future<void> responderSolicitud(String pacienteId, bool aprobar) async {
    await ApiService.dio.post('/api/auth/vincular/responder-solicitud/$pacienteId',
        data: {'aprobar': aprobar});
  }

  // El paciente consulta su estado de permiso
  static Future<Map<String, dynamic>> getMiPermiso() async {
    final response = await ApiService.dio.get('/api/auth/vincular/mi-permiso');
    return Map<String, dynamic>.from(response.data);
  }
}
