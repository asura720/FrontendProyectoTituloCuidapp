# Activar notificaciones push (Firebase Cloud Messaging)

Sigue estos pasos UNA vez. Al terminar, el botón SOS, el push de bienvenida y
los recordatorios llegarán de verdad al celular.

El push necesita configurarse en **dos lados**: la app (Android) y el backend.

---

## Parte A — Crear el proyecto Firebase

1. Entra a https://console.firebase.google.com → **Agregar proyecto**.
   - Nombre: `cuidapp` (o el que quieras). Puedes desactivar Google Analytics.

---

## Parte B — App Android (para que el celular RECIBA el push)

2. En el proyecto Firebase: ícono Android (**"Agregar app" → Android**).
3. **Nombre del paquete de Android:** escribe exactamente:
   ```
   com.example.frontend_proyecto_titulo
   ```
4. Registra la app y **descarga `google-services.json`**.
5. Copia ese archivo a esta ruta del proyecto Flutter:
   ```
   Frontend-Proyecto-Titulo-main/android/app/google-services.json
   ```
6. Recompila el APK e instálalo en el celular del cuidador:
   ```
   flutter build apk --release --dart-define=API_BASE_URL=http://TU_IP:8083
   ```
   > Al existir `google-services.json`, el plugin de Firebase se activa solo.
   > El cuidador debe **iniciar sesión** en este APK (ahí se registra su token).

---

## Parte C — Backend (para que el servidor ENVÍE el push)

7. En Firebase: ⚙️ **Configuración del proyecto → Cuentas de servicio →
   Generar nueva clave privada** → descarga el JSON.
8. Renómbralo a `firebase-service-account.json` y déjalo en la raíz del backend
   (junto al `docker-compose.yml`).
9. Edita el `docker-compose.yml` (o `docker-compose.aws.yml`), en el servicio
   **notificaciones**:
   - Cambia `FCM_ENABLED: "false"` por `FCM_ENABLED: "true"`
   - **Descomenta** el bloque `volumes:` que monta el `firebase-service-account.json`
10. Reinicia el servicio:
    ```
    docker compose up -d notificaciones
    ```
    En los logs debe aparecer: `[Firebase] Inicializado correctamente`.

---

## Probar

1. En un **celular Android** (no Chrome) inicia sesión con la cuenta del **cuidador**
   usando el APK recompilado → acepta el permiso de notificaciones.
2. Desde otra sesión (el paciente vinculado) pulsa el **botón SOS**.
3. Al cuidador le llega la notificación con **vibración fuerte**. 🆘

> Importante: el push **no se ve en Chrome** (está desactivado en web a propósito).
> Siempre pruébalo en un celular Android real.
