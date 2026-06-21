import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Pantalla para verificar la cuenta con el código de 6 dígitos enviado al correo.
/// Si se entrega [password], al verificar inicia sesión automáticamente.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? password;

  const VerifyEmailScreen({super.key, required this.email, this.password});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(widget.email, code);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _loading = false;
        _error = auth.error ?? 'Código incorrecto o vencido';
      });
      return;
    }

    // Cuenta verificada. Si tenemos la contraseña, iniciamos sesión directo.
    if (widget.password != null && widget.password!.isNotEmpty) {
      final logged = await auth.login(widget.email, widget.password!);
      if (!mounted) return;
      if (logged) {
        await auth.sendWelcomePush();
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
        return;
      }
    }

    // Sin auto-login: volvemos al login con aviso de éxito.
    setState(() => _loading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta verificada. Ya puedes iniciar sesión.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendCode(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Te enviamos un nuevo código a ${widget.email}'
            : (auth.error ?? 'No se pudo reenviar el código')),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFd4183d),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A56DB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 46, color: Color(0xFF1A56DB)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verifica tu cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviamos un código de 6 dígitos a\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: const TextStyle(letterSpacing: 12),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFd4183d), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFFd4183d), fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56DB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verificar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(
                        _resending ? 'Reenviando...' : '¿No te llegó? Reenviar código',
                        style: const TextStyle(
                          color: Color(0xFF1A56DB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
