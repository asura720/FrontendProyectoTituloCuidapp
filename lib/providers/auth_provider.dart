import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _rememberKey = 'remember_me';

  bool _isLoggedIn = false;
  User? _currentUser;
  String? _error;
  bool _isLoading = false;

  bool _requiresVerification = false;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String get userName => _currentUser?.name ?? '';
  String get userEmail => _currentUser?.email ?? '';
  String? get error => _error;
  bool get isLoading => _isLoading;
  // True si el último login falló porque la cuenta no está verificada
  bool get requiresVerification => _requiresVerification;

  Future<bool> login(String email, String password,
      {bool rememberMe = true}) async {
    _isLoading = true;
    _error = null;
    _requiresVerification = false;
    notifyListeners();

    try {
      final data = await AuthService.login(email, password);
      await ApiService.saveToken(data['token']);

      // Guardar preferencia de "Recuérdame" para el auto-login al reabrir la app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberKey, rememberMe);

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
      // El backend marca con requiresVerification cuando falta verificar el correo
      _requiresVerification = e.response?.data is Map &&
          e.response?.data['requiresVerification'] == true;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica la cuenta con el código de 6 dígitos enviado por correo.
  Future<bool> verifyEmail(String email, String code) async {
    _error = null;
    try {
      await AuthService.verifyCode(email, code);
      _requiresVerification = false;
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Código incorrecto o vencido';
      notifyListeners();
      return false;
    }
  }

  /// Reenvía un nuevo código de verificación al correo.
  Future<bool> resendCode(String email) async {
    _error = null;
    try {
      await AuthService.resendCode(email);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'No se pudo reenviar el código';
      notifyListeners();
      return false;
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

  /// Pide enviar un código de seguridad al correo para una acción sensible.
  Future<bool> sendActionCode(String email, String action) async {
    _error = null;
    try {
      await AuthService.sendCode(email, action);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'No se pudo enviar el código';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(
      String email, String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.resetPassword(email, code, newPassword);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ??
          'No se pudo restablecer la contraseña';
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

  /// Intenta iniciar sesión automáticamente al abrir la app, si el usuario
  /// marcó "Recuérdame" y el token guardado sigue siendo válido.
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberKey) ?? false;
      final token = await ApiService.getToken();

      if (!remember || token == null) {
        // Si no hay que recordar, limpiamos el token para no entrar solo
        if (!remember) await ApiService.deleteToken();
        return;
      }

      // Validar el token cargando el perfil
      final data = await AuthService.getProfile();
      _currentUser = User.fromJson(data);
      _isLoggedIn = true;
      notifyListeners();

      // Re-registrar el token de push de este dispositivo
      PushService.registerTokenForUser(_currentUser!.id);
    } catch (_) {
      // Token inválido/expirado o sin conexión: quedarse en la pantalla de login
      _isLoggedIn = false;
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

  /// Activa la función de cuidador con el código enviado al correo.
  Future<bool> enableCaregiver(String code) async {
    _error = null;
    if (code.isEmpty) {
      _error = 'Ingresa el código enviado a tu correo';
      notifyListeners();
      return false;
    }
    try {
      await AuthService.enableCaregiver(code);
      await _loadProfile(); // recarga el perfil con caregiverEnabled=true
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'No se pudo activar la función';
      notifyListeners();
      return false;
    }
  }

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

  Future<bool> changePassword(String oldPassword, String code,
      String newPassword, String confirmPassword) async {
    _error = null;
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _error = 'Completa todos los campos';
      notifyListeners();
      return false;
    }
    if (code.isEmpty) {
      _error = 'Ingresa el código enviado a tu correo';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _error = 'Las contraseñas nuevas no coinciden';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 4) {
      _error = 'La nueva contraseña debe tener al menos 4 caracteres';
      notifyListeners();
      return false;
    }
    try {
      await AuthService.changePassword(oldPassword, code, newPassword);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'No se pudo cambiar la contraseña';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount(String password, String code) async {
    _error = null;
    if (password.isEmpty) {
      _error = 'Confirma tu contraseña';
      notifyListeners();
      return false;
    }
    if (code.isEmpty) {
      _error = 'Ingresa el código enviado a tu correo';
      notifyListeners();
      return false;
    }
    try {
      await AuthService.deleteAccount(password, code);
      // Cuenta eliminada: cerrar sesión y limpiar estado
      await logout();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'No se pudo eliminar la cuenta';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, false);
    _isLoggedIn = false;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
