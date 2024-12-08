import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../charger_spots_repository.dart';
import '../services/location_service.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final ChargerSpotsRepository _repository = ChargerSpotsRepository();
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    _currentLocation = await LocationService.getCurrentLocation();
    if (_currentLocation != null) {
      await _loadChargerSpots();
    }
  }

  Future<void> _loadChargerSpots() async {
    if (_currentLocation == null) return;

    final response = await _repository.getChargerSpots(
      swLat: _currentLocation!.latitude - 0.01,
      swLng: _currentLocation!.longitude - 0.01,
      neLat: _currentLocation!.latitude + 0.01,
      neLng: _currentLocation!.longitude + 0.01,
    );

    if (response.status == GetChargerSpotsStatus.ok) {
      setState(() {
        _markers.clear();
        for (final spot in response.spots) {
          _addMarker(spot.latitude, spot.longitude, spot.chargerDevices.length);
        }
      });
    }
  }

  void _addMarker(double lat, double lng, int chargerCount) {
    final marker = Marker(
      markerId: MarkerId('marker_$lat$lng'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
    );
  }
}
