# CuidApp — Frontend (App Móvil)

Aplicación móvil de **CuidApp**, una plataforma para el cuidado y acompañamiento
de personas (especialmente adultos mayores) en la gestión de su salud:
medicamentos, recordatorios, controles médicos y vínculo con un cuidador.

Este repositorio contiene la **app cliente** desarrollada en Flutter. El backend
(microservicios) vive en un repositorio aparte.

---

## 📋 Descripción del proyecto

CuidApp permite a un **paciente** gestionar sus medicamentos y controles, y a un
**cuidador (titular)** supervisar a las personas bajo su tutela. Funcionalidades
principales:

- **Autenticación**: registro, inicio de sesión y recuperación de contraseña (JWT).
- **Gestión de medicamentos**: alta, edición, horarios y seguimiento de adherencia.
- **Controles médicos** y panel de inicio con resumen del día.
- **Vinculación cuidador–paciente**: un titular crea/gestiona cuentas de pacientes
  y aprueba permisos.
- **Escáner**: lectura de cajas/recetas con OCR (reconocimiento de texto).
- **Mapa "Cerca"**: farmacias y centros médicos cercanos con Google Maps + Places.
- **Notificaciones push** (Firebase Cloud Messaging): bienvenida y recordatorios.
- **Botón SOS**: el paciente envía una alerta de emergencia con push y vibración
  al celular de su cuidador.

---

## 🛠️ Tecnologías utilizadas

| Categoría | Tecnología |
|-----------|------------|
| Framework | **Flutter** (Dart 3.11+) |
| Estado | **Provider** |
| HTTP / API | **Dio** |
| Almacenamiento seguro | **flutter_secure_storage** (token JWT) |
| Notificaciones push | **firebase_core**, **firebase_messaging**, **flutter_local_notifications** |
| Mapas y ubicación | **google_maps_flutter**, **geolocator**, Google Places API |
| Escáner / OCR | **mobile_scanner**, **google_mlkit_text_recognition** |
| UI / utilidades | **google_fonts**, **intl**, **flutter_localizations** |
| Plataformas | Android, iOS, Web |

---

## 📂 Estructura del proyecto

```
lib/
├── main.dart                 # Punto de entrada y configuración global
├── models/                   # Modelos (medication, location, ...)
├── providers/                # Estado con Provider (auth, medication, user)
├── screens/                  # Pantallas (login, home, mapa, scanner, perfil, ...)
├── services/                 # Acceso a la API y servicios (api, auth, push, places, sos, ...)
└── widgets/                  # Componentes reutilizables (sos_button, ...)
android/  ios/  web/          # Configuración por plataforma
```

---

## 🚀 Cómo ejecutar

```bash
flutter pub get

# Ejecutar en Chrome (desarrollo)
flutter run -d chrome

# Ejecutar / compilar apuntando al backend (IP del servidor)
flutter run --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:8083
flutter build apk --release --dart-define=API_BASE_URL=http://IP_DEL_SERVIDOR:8083
```

> Para activar el push se requiere `android/app/google-services.json` (Firebase).
> Ver `FIREBASE-SETUP.md`.

---

## 👥 Estructura del equipo

| Nombre | Rol | Responsabilidades |
|--------|-----|-------------------|
| **Matías Samaniego** | Líder de proyecto / Full-Stack | Coordinación, integración frontend–backend, notificaciones push |
| **Francisco Gómez** | Desarrollo Backend | Microservicios, API Gateway, base de datos y seguridad (JWT) |
| **Ricardo Díaz** | Desarrollo Frontend | App Flutter, pantallas, mapa y experiencia de usuario |
