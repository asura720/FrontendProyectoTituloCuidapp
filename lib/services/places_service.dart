import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location.dart';

/// Servicio que busca farmacias y centros médicos cercanos usando la
/// Google Places API (Nearby Search).
///
/// La misma API key de Google Maps que está en web/index.html y en el
/// AndroidManifest se usa aquí. Se puede sobrescribir al compilar:
///   flutter run --dart-define=GOOGLE_MAPS_API_KEY=TU_KEY
///
/// Nota sobre web: la llamada directa a Places desde el navegador suele ser
/// bloqueada por CORS, por lo que en Chrome se usan datos de demostración.
/// En Android la búsqueda real funciona sin problema.
class PlacesService {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAWgmIwopMDNgxSLszseXoiAr85yG7rt2U',
  );

  static final Dio _dio = Dio();

  /// Busca farmacias y centros médicos en un radio (metros) alrededor de la
  /// ubicación dada. Si la API falla (CORS en web, sin key, etc.) devuelve
  /// una lista de demostración para que la sección no quede vacía.
  static Future<List<Location>> nearby({
    required double latitude,
    required double longitude,
    int radius = 3000,
  }) async {
    try {
      final pharmacies = await _search(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: 'pharmacy',
        mappedType: 'pharmacy',
      );
      final hospitals = await _search(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: 'hospital',
        mappedType: 'hospital',
      );

      final all = [...pharmacies, ...hospitals];
      if (all.isEmpty) {
        return _demoData(latitude, longitude);
      }
      all.sort((a, b) => a.distance.compareTo(b.distance));
      return all;
    } catch (_) {
      return _demoData(latitude, longitude);
    }
  }

  static Future<List<Location>> _search({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
    required String mappedType,
  }) async {
    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      queryParameters: {
        'location': '$latitude,$longitude',
        'radius': radius,
        'type': type,
        'language': 'es',
        'key': apiKey,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? [];

    return results.map<Location>((r) {
      final geo = r['geometry']?['location'] ?? {};
      final lat = (geo['lat'] as num?)?.toDouble() ?? latitude;
      final lng = (geo['lng'] as num?)?.toDouble() ?? longitude;
      final openNow = r['opening_hours']?['open_now'];

      final distanceMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        lat,
        lng,
      );

      return Location(
        latitude: lat,
        longitude: lng,
        name: r['name'] ?? 'Sin nombre',
        type: mappedType,
        address: r['vicinity'] ?? '',
        phone: '',
        hours: openNow == null
            ? ''
            : (openNow == true ? 'Abierto ahora' : 'Cerrado ahora'),
        distance: distanceMeters / 1000.0,
      );
    }).toList();
  }

  /// Datos de ejemplo alrededor de la ubicación (para web/CORS o sin key).
  static List<Location> _demoData(double lat, double lng) {
    final demo = [
      _demo(lat, lng, 0.004, 0.003, 'Farmacia Cruz Verde', 'pharmacy',
          'Av. Principal 123', 'Abierto ahora'),
      _demo(lat, lng, -0.003, 0.005, 'Farmacia Ahumada', 'pharmacy',
          'Calle Comercio 456', 'Abierto ahora'),
      _demo(lat, lng, 0.006, -0.002, 'Farmacia Salcobrand', 'pharmacy',
          'Plaza Central 78', 'Cerrado ahora'),
      _demo(lat, lng, -0.005, -0.004, 'Hospital Regional', 'hospital',
          'Av. Salud 1000', 'Urgencias 24h'),
      _demo(lat, lng, 0.002, -0.006, 'Centro Médico San José', 'clinic',
          'Calle Bienestar 321', 'Abierto ahora'),
      _demo(lat, lng, -0.007, 0.002, 'CESFAM Los Andes', 'clinic',
          'Pasaje Norte 55', 'Abierto ahora'),
    ];
    demo.sort((a, b) => a.distance.compareTo(b.distance));
    return demo;
  }

  static Location _demo(double lat, double lng, double dLat, double dLng,
      String name, String type, String address, String hours) {
    final pLat = lat + dLat;
    final pLng = lng + dLng;
    final distanceMeters =
        Geolocator.distanceBetween(lat, lng, pLat, pLng);
    return Location(
      latitude: pLat,
      longitude: pLng,
      name: name,
      type: type,
      address: address,
      phone: '',
      hours: hours,
      distance: distanceMeters / 1000.0,
    );
  }
}
