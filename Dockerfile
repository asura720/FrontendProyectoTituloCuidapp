# ---- Etapa de build: compila el APK ----
# Imagen oficial mantenida con Flutter (stable) + SDK de Android y licencias aceptadas.
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Evita el error "dubious ownership" de git dentro del contenedor
RUN git config --global --add safe.directory '*'

WORKDIR /app

# 1. Cachear dependencias (solo se reinstalan si cambia pubspec)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 2. Copiar el resto del proyecto
COPY . .

# 3. URL del backend embebida en el APK. Cambiala al compilar con:
#      docker build --build-arg API_BASE_URL=http://TU_IP:8083 ...
ARG API_BASE_URL=http://192.168.1.8:8083

# 4. Compilar el APK de release
RUN flutter build apk --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---- Etapa de exportación: deja SOLO el APK ----
FROM scratch AS export
COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk /app-release.apk
