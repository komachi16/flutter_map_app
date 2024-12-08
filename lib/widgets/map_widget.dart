import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../charger_spots_repository.dart';
import '../services/location_service.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  MapWidgetState createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
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

  void _moveCameraToCurrentLocation() {
    if (_currentLocation != null) {
      _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  Future<void> _loadChargerSpots() async {
    if (_currentLocation == null) {
      return;
    }

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

  Future<void> _refreshChargerSpots() async {
    // 現在地を再取得して近くのCharger Spotsを取得
    _currentLocation = await LocationService.getCurrentLocation();
    if (_currentLocation != null) {
      await _loadChargerSpots();
      _moveCameraToCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 16,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                  _moveCameraToCurrentLocation();
                },
                myLocationEnabled: true,
              ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: ElevatedButton(
            onPressed: _refreshChargerSpots,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.green,
              backgroundColor: const Color.fromARGB(255, 234, 248, 219),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('このエリアでスポットを検索'),
                Spacer(),
                Icon(Icons.search), // 虫眼鏡アイコン
              ],
            ),
          ),
        ),
      ],
    );
  }
}
