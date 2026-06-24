import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/sos_service.dart';
import '../services/vinculacion_service.dart';

/// Botón de emergencia que solo ve el paciente bajo tutela (rol PACIENTE).
/// Al pulsarlo (con confirmación) envía una alerta push + vibración al cuidador.
class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  bool _sending = false;

  // Conteo de pulsaciones: 5 dentro de una ventana de tiempo -> llamar al cuidador
  int _pressCount = 0;
  DateTime? _firstPressAt;
  static const _ventana = Duration(seconds: 60);

  /// Lleva el conteo y, al llegar a 5 pulsaciones seguidas, llama al cuidador.
  Future<void> _registrarPulsacionYQuizasLlamar() async {
    final now = DateTime.now();
    if (_firstPressAt == null || now.difference(_firstPressAt!) > _ventana) {
      _firstPressAt = now;
      _pressCount = 0;
    }
    _pressCount++;
    if (_pressCount >= 5) {
      _pressCount = 0;
      _firstPressAt = null;
      await _llamarCuidador();
    }
  }

  /// Obtiene el teléfono del cuidador y abre el marcador para llamarlo.
  Future<void> _llamarCuidador() async {
    String? phone;
    try {
      final titular = await VinculacionService.getMiTitular();
      phone = (titular['phone'] ?? '').toString().trim();
    } catch (_) {
      phone = null;
    }
    if (!mounted) return;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuidador no tiene un teléfono registrado para llamar'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el marcador')),
      );
    }
  }

  Future<void> _onPressed() async {
    final patientName = context.read<AuthProvider>().userName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Enviar SOS'),
          ],
        ),
        content: const Text(
          '¿Enviar una alerta de emergencia a tu cuidador? '
          'Recibirá una notificación y vibración en su celular.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _sending = true);
    final result = await SosService.send(patientName);
    if (!mounted) return;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Tras 5 pulsaciones seguidas, además llama al cuidador.
    await _registrarPulsacionYQuizasLlamar();
  }

  @override
  Widget build(BuildContext context) {
    // Solo visible para pacientes bajo tutela
    final role = context.watch<AuthProvider>().currentUser?.role;
    if (role != 'PACIENTE') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _sending ? null : _onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_sending)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  else
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Text(
                    _sending ? 'Enviando alerta...' : 'BOTÓN DE EMERGENCIA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
