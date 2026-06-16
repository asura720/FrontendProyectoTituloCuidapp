import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? birthDate,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
    };
    final response = await ApiService.dio.post('/api/auth/register', data: body);
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiService.dio.post('/api/auth/forgot-password', data: {
      'email': email,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.dio.get('/api/auth/profile');
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.dio.put('/api/auth/profile', data: data);
    return Map<String, dynamic>.from(response.data);
  }
}
