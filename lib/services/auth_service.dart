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

  static Future<Map<String, dynamic>> verifyCode(
      String email, String code) async {
    final response = await ApiService.dio.post('/api/auth/verify', data: {
      'email': email,
      'code': code,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> resendCode(String email) async {
    final response = await ApiService.dio.post('/api/auth/resend-code', data: {
      'email': email,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Pide al backend enviar un código de seguridad al correo para una acción
  /// (recuperar/cambiar contraseña o eliminar cuenta).
  static Future<Map<String, dynamic>> sendCode(String email, String action) async {
    final response = await ApiService.dio.post('/api/auth/send-code', data: {
      'email': email,
      'action': action,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String code, String newPassword) async {
    final response = await ApiService.dio.post('/api/auth/reset-password', data: {
      'email': email,
      'code': code,
      'password': newPassword,
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

  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String code, String newPassword) async {
    final response = await ApiService.dio.put('/api/auth/change-password', data: {
      'oldPassword': oldPassword,
      'code': code,
      'newPassword': newPassword,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> enableCaregiver(String code) async {
    final response = await ApiService.dio.post('/api/auth/enable-caregiver', data: {
      'code': code,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> deleteAccount(
      String password, String code) async {
    final response = await ApiService.dio.delete('/api/auth/account', data: {
      'password': password,
      'code': code,
    });
    return Map<String, dynamic>.from(response.data);
  }
}
