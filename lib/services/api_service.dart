import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // URL del backend. Se puede sobrescribir al compilar sin tocar el código:
  //   flutter build apk --dart-define=API_BASE_URL=http://TU_IP:8083
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8083',
  );
  static const _storage = FlutterSecureStorage();
  static Dio? _dio;

  static Dio get dio {
    _dio ??=
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          )
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                final token = await getToken();
                if (token != null) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                handler.next(options);
              },
            ),
          );
    return _dio!;
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'jwt_token', value: token);
    } catch (_) {
      // Si el almacenamiento quedó en mal estado, lo limpiamos y reintentamos.
      await _safeDeleteAll();
      await _storage.write(key: 'jwt_token', value: token);
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (_) {
      await _safeDeleteAll();
    }
  }

  /// Lee el token de forma tolerante: si el valor guardado está corrupto
  /// (BadPaddingException tras reinstalar la app), lo limpia y devuelve null
  /// en vez de romper la petición.
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (_) {
      await _safeDeleteAll();
      return null;
    }
  }

  static Future<void> _safeDeleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
