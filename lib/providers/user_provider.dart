import 'package:flutter/material.dart';

class User {
  final String id;
  String name;
  String email;
  String password;
  String phone;
  String birthDate;
  String bloodType;
  String emergencyContact;
  String emergencyPhone;
  String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.password = '',
    this.phone = '',
    this.birthDate = '',
    this.bloodType = '',
    this.emergencyContact = '',
    this.emergencyPhone = '',
    this.role = 'INDEPENDIENTE',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone.isNotEmpty ? phone : null,
      'birthDate': birthDate.isNotEmpty ? birthDate : null,
      'bloodType': bloodType.isNotEmpty ? bloodType : null,
      'emergencyContact': emergencyContact.isNotEmpty ? emergencyContact : null,
      'emergencyPhone': emergencyPhone.isNotEmpty ? emergencyPhone : null,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      birthDate: json['birthDate'] ?? '',
      bloodType: json['bloodType'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      emergencyPhone: json['emergencyPhone'] ?? '',
      role: json['role'] ?? 'INDEPENDIENTE',
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? birthDate,
    String? bloodType,
    String? emergencyContact,
    String? emergencyPhone,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      role: role ?? this.role,
    );
  }
}

class UserProvider extends ChangeNotifier {
  final List<User> _users = [
    User(
      id: '1',
      name: 'María Rodríguez',
      email: 'maria@example.com',
      password: '1234',
      phone: '+56 9 8765 4321',
      birthDate: '15 de Marzo, 1985',
      bloodType: 'O+',
      emergencyContact: 'Ana Rodríguez (Hermana)',
      emergencyPhone: '+56 9 1234 5678',
    ),
    User(
      id: '2',
      name: 'Juan García López',
      email: 'juan@example.com',
      password: '1234',
      phone: '+56 9 8765 4322',
      birthDate: '20 de Junio, 1978',
      bloodType: 'A+',
      emergencyContact: 'Carlos García (Hijo)',
      emergencyPhone: '+56 9 1234 5679',
    ),
  ];

  // Obtener todos los usuarios
  List<User> get users => _users;

  // Buscar usuario por email
  User? getUserByEmail(String email) {
    try {
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  // Crear usuario
  bool createUser(User user) {
    if (getUserByEmail(user.email) != null) {
      return false; // Email ya existe
    }
    _users.add(user);
    notifyListeners();
    return true;
  }

  // Actualizar usuario
  bool updateUser(User updatedUser) {
    final index = _users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Eliminar usuario
  bool deleteUser(String userId) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users.removeAt(index);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Verificar credenciales
  User? validateCredentials(String email, String password) {
    final user = getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }
}
