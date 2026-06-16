import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location.dart';
import '../services/places_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Ubicación por defecto si no se puede obtener el GPS (Santiago, Chile)
  static const LatLng _defaultCenter = LatLng(-33.4489, -70.6693);

  GoogleMapController? _controller;
  LatLng _center = _defaultCenter;
  List<Location> _places = [];
  bool _loading = true;
  String _filter = 'all'; // all | pharmacy | medical

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final pos = await _resolvePosition();
    final places = await PlacesService.nearby(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!mounted) return;
    setState(() {
      _center = pos;
      _places = places;
      _loading = false;
    });
  }

  /// Intenta obtener la ubicación actual; si falla o se deniega, usa la default.
  Future<LatLng> _resolvePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultCenter;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _defaultCenter;
      }

      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return _defaultCenter;
    }
  }

  List<Location> get _filteredPlaces {
    switch (_filter) {
      case 'pharmacy':
        return _places.where((p) => p.type == 'pharmacy').toList();
      case 'medical':
        return _places
            .where((p) => p.type == 'hospital' || p.type == 'clinic')
            .toList();
      default:
        return _places;
    }
  }

  Set<Marker> get _markers {
    return _filteredPlaces.map((p) {
      return Marker(
        markerId: MarkerId('${p.name}-${p.latitude}-${p.longitude}'),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(p.type)),
        infoWindow: InfoWindow(
          title: p.name,
          snippet: '${p.address} · ${p.distance.toStringAsFixed(1)} km',
        ),
      );
    }).toSet();
  }

  double _hueFor(String type) {
    switch (type) {
      case 'pharmacy':
        return BitmapDescriptor.hueGreen;
      case 'hospital':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<void> _focusOn(Location p) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca de ti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recargar',
            onPressed: _loading ? null : _init,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            flex: 3,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (c) => _controller = c,
                  ),
          ),
          Expanded(
            flex: 2,
            child: _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, String value, IconData icon) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          avatar: Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : const Color(0xFF1A56DB),
          ),
          selected: selected,
          selectedColor: const Color(0xFF1A56DB),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: const Color(0xFFF5F7FB),
          onSelected: (_) => setState(() => _filter = value),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Todos', 'all', Icons.place_outlined),
            chip('Farmacias', 'pharmacy', Icons.local_pharmacy_outlined),
            chip('Centros médicos', 'medical', Icons.local_hospital_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final places = _filteredPlaces;
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (places.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron lugares cercanos',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: places.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final p = places[index];
        final isPharmacy = p.type == 'pharmacy';
        final color = isPharmacy
            ? const Color(0xFF2E7D32)
            : (p.type == 'hospital'
                ? const Color(0xFFC62828)
                : const Color(0xFF1A56DB));
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              isPharmacy
                  ? Icons.local_pharmacy
                  : (p.type == 'hospital'
                      ? Icons.local_hospital
                      : Icons.medical_services),
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.address.isNotEmpty)
                Text(p.address, style: const TextStyle(fontSize: 12)),
              if (p.hours.isNotEmpty)
                Text(
                  p.hours,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.hours.toLowerCase().contains('cerrado')
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: Text(
            '${p.distance.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A56DB),
            ),
          ),
          onTap: () => _focusOn(p),
        );
      },
    );
  }
}
