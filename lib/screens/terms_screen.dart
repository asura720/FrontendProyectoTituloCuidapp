import 'package:flutter/material.dart';

/// Términos y Condiciones + Política de Privacidad de CuidApp.
/// Se muestra en el registro (debe aceptarse) y desde el Perfil.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        title: const Text('Términos y Condiciones'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _termsText,
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1A1A1A)),
        ),
      ),
    );
  }
}

const String _termsText = '''
TÉRMINOS Y CONDICIONES DE USO Y POLÍTICA DE PRIVACIDAD — CuidApp

Última actualización: 2026

1. OBJETO
CuidApp es una aplicación de apoyo al cuidado de la salud que permite gestionar medicamentos, recordatorios, controles médicos, alertas de emergencia (SOS) y la vinculación entre pacientes y cuidadores. Al registrarte y usar la aplicación, aceptas estos Términos y Condiciones y la presente Política de Privacidad.

2. MARCO LEGAL
El tratamiento de tus datos personales se rige por la legislación chilena vigente sobre protección de datos personales, en particular la Ley N° 19.628 sobre Protección de la Vida Privada y la Ley N° 21.719, que regula la protección y el tratamiento de los datos personales y crea la Agencia de Protección de Datos Personales. CuidApp adhiere a los principios de licitud, finalidad, proporcionalidad, calidad, transparencia, seguridad y responsabilidad proactiva.

3. DATOS QUE RECOPILAMOS
Para funcionar, CuidApp trata los siguientes datos:
- Datos de identificación y contacto: nombre, correo electrónico, teléfono, fecha de nacimiento.
- Contacto de emergencia: nombre y teléfono que tú indiques.
- Datos relativos a la salud (datos sensibles): medicamentos, dosis, horarios, tipo de sangre y controles médicos que registres.
- Datos técnicos: token del dispositivo para notificaciones y, si lo autorizas, tu ubicación aproximada para mostrar farmacias y centros médicos cercanos.

4. DATOS SENSIBLES DE SALUD
Los datos relativos a tu salud son datos sensibles y reciben protección reforzada. Al aceptar estos términos, otorgas tu consentimiento expreso e informado para que CuidApp los trate con la única finalidad de prestarte el servicio (recordatorios, alertas y gestión de tu tratamiento). No se usan con fines publicitarios ni se venden a terceros.

5. FINALIDAD DEL TRATAMIENTO
Tus datos se utilizan exclusivamente para: crear y administrar tu cuenta; enviarte recordatorios y alertas de medicamentos; gestionar la vinculación con tu cuidador o paciente; enviar alertas de emergencia (SOS); y mostrarte servicios de salud cercanos cuando lo solicites.

6. VINCULACIÓN PACIENTE–CUIDADOR
Si eres paciente vinculado a un cuidador, este podrá ver y gestionar tu información de medicamentos y recibir tus alertas, con la finalidad de cuidar tu salud. Las notificaciones de medicamentos y emergencias se envían únicamente a las personas del vínculo (paciente y/o cuidador), nunca a terceros.

7. SEGURIDAD
Aplicamos medidas técnicas para proteger tu información: las contraseñas se almacenan cifradas (no en texto plano), el acceso a la información se controla mediante autenticación, y las acciones sensibles (recuperar o cambiar contraseña y eliminar cuenta) requieren verificación por código enviado a tu correo.

8. TUS DERECHOS (ARCOP)
Puedes ejercer en cualquier momento tus derechos de Acceso, Rectificación, Cancelación (supresión), Oposición y Portabilidad sobre tus datos:
- Acceso y rectificación: desde "Editar perfil".
- Supresión: desde "Eliminar cuenta", que borra tu cuenta y tus vínculos de forma permanente.
Para otras solicitudes puedes escribirnos al correo de contacto.

9. CONSERVACIÓN Y ELIMINACIÓN
Conservamos tus datos mientras tu cuenta esté activa. Si eliminas tu cuenta, se borran tus datos personales y tus vínculos. Algunos registros podrían conservarse el tiempo mínimo que exija la ley.

10. CONTACTO
Para consultas sobre privacidad o el ejercicio de tus derechos, escribe a: cuidappnoreply@gmail.com

11. ACEPTACIÓN
Al marcar la casilla de aceptación durante el registro, declaras haber leído y comprendido estos Términos y Condiciones y esta Política de Privacidad, y otorgas tu consentimiento informado para el tratamiento de tus datos, incluidos los datos sensibles de salud, conforme a lo aquí descrito.
''';
