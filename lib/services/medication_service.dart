import 'api_service.dart';

class MedicationService {
  static Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    final response = await ApiService.dio.get('/api/medications/user/$userId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> createMedication(
    Map<String, dynamic> data, {
    String? forUserId,
  }) async {
    final body = forUserId != null ? {...data, 'userId': int.tryParse(forUserId)} : data;
    final response = await ApiService.dio.post('/api/medications', data: body);
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateMedication(String id, Map<String, dynamic> data) async {
    final response = await ApiService.dio.put('/api/medications/$id', data: data);
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> deleteMedication(String id) async {
    await ApiService.dio.delete('/api/medications/$id');
  }

  static Future<Map<String, dynamic>> toggleMedication(String id) async {
    final response = await ApiService.dio.patch('/api/medications/$id/toggle');
    return Map<String, dynamic>.from(response.data);
  }
}
