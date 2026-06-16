import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'user_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  User? _currentUser;
  String? _error;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String get userName => _currentUser?.name ?? '';
  String get userEmail => _currentUser?.email ?? '';
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.login(email, password);
      await ApiService.saveToken(data['token']);

      _currentUser = User(
        id: data['id'].toString(),
        name: data['name'] ?? '',
        email: data['email'] ?? '',
      );

      _isLoggedIn = true;
      notifyListeners();

      // Registrar el token de notificaciones push de este dispositivo (móvil)
      await PushService.registerTokenForUser(_currentUser!.id);

      // Cargar perfil completo en segundo plano
      _loadProfile();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Error de conexión';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmPassword, {
    String? birthDate,
  }) async {
    if (password != confirmPassword) {
      _error = 'Las contraseñas no coinciden';
      notifyListeners();
      return false;
    }
    if (password.length < 4) {
      _error = 'La contraseña debe tener al menos 4 caracteres';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        birthDate: birthDate,
      );
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Error al registrar';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.forgotPassword(email);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ??
          'No se pudo enviar el correo de recuperación';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pide al backend enviar el push de bienvenida tras el registro.
  /// Tolerante a fallos: nunca interrumpe el flujo si no hay token/push.
  Future<void> sendWelcomePush() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      await NotificationService.sendWelcome(user.id, user.name);
    } catch (_) {
      // El push es secundario; ignoramos errores.
    }
  }

  Future<void> _loadProfile() async {
    try {
      final data = await AuthService.getProfile();
      _currentUser = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshProfile() => _loadProfile();

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String birthDate,
    required String bloodType,
    required String emergencyContact,
    required String emergencyPhone,
  }) async {
    try {
      final data = await AuthService.updateProfile({
        'name': name,
        'phone': phone.isNotEmpty ? phone : null,
        'birthDate': birthDate.isNotEmpty ? birthDate : null,
        'bloodType': bloodType.isNotEmpty ? bloodType : null,
        'emergencyContact': emergencyContact.isNotEmpty ? emergencyContact : null,
        'emergencyPhone': emergencyPhone.isNotEmpty ? emergencyPhone : null,
      });
      _currentUser = User.fromJson(data);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool changePassword(String oldPassword, String newPassword, String confirmPassword) {
    // TODO: implementar endpoint en backend
    return false;
  }

  bool deleteAccount(String password) {
    // TODO: implementar endpoint en backend
    return false;
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    _isLoggedIn = false;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
