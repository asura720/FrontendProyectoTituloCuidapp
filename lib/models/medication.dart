import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final Color containerColor;
  final Color iconColor;
  bool isTaken;
  DateTime? takenDateTime;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.containerColor,
    required this.iconColor,
    this.isTaken = false,
    this.takenDateTime,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      try {
        return Color(int.parse(hex.replaceAll('#', ''), radix: 16));
      } catch (_) {
        return fallback;
      }
    }

    return Medication(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      times: json['times'] != null ? List<String>.from(json['times']) : [],
      containerColor: parseColor(json['containerColor'], const Color(0xFFE3F2FD)),
      iconColor: parseColor(json['iconColor'], const Color(0xFF1A56DB)),
      isTaken: json['isTaken'] ?? false,
      takenDateTime: json['takenDateTime'] != null
          ? DateTime.tryParse(json['takenDateTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'containerColor': containerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase(),
      'iconColor': iconColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase(),
      'isTaken': isTaken,
    };
  }
}