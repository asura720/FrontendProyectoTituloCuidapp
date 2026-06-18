import 'package:dio/dio.dart';
import 'api_service.dart';

/// Consulta el catálogo de medicamentos del backend (microservicio catálogo).
class CatalogService {
  /// Busca un medicamento por código de barras. Devuelve null si no existe (404).
  static Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    try {
      final response =
          await ApiService.dio.get('/api/catalog/barcode/$barcode');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Busca medicamentos por nombre (para el OCR). Devuelve lista (puede ser vacía).
  static Future<List<Map<String, dynamic>>> search(String query) async {
    final response = await ApiService.dio.get(
      '/api/catalog/search',
      queryParameters: {'q': query},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
