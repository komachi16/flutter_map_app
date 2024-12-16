import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../charger_spot.dart';
import '../charger_spots_repository.dart';
import '../services/location_service.dart';
import 'charger_spot_card.dart';

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
  List<ChargerSpot> _chargerSpots = [];
  bool isMarkerSelected = false;
  final ScrollController _scrollController = ScrollController();
  final double cellMovementRange = 180;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    _currentLocation = await LocationService.getCurrentLocation();
    setState(() {});
  }

  Future<void> _loadChargerSpotsInVisibleRegion() async {
    if (_currentLocation == null || !mounted) {
      return;
    }

    // 現在表示されている地図の範囲を取得
    final bounds = await _controller.getVisibleRegion();

    final response = await _repository.getChargerSpots(
      swLat: bounds.southwest.latitude,
      swLng: bounds.southwest.longitude,
      neLat: bounds.northeast.latitude,
      neLng: bounds.northeast.longitude,
    );

    if (response.status == GetChargerSpotsStatus.ok) {
      setState(() {
        _chargerSpots = response.spots;
        _updateMarkers();
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    for (final spot in _chargerSpots) {
      _markers.add(_createMarker(spot));
    }
  }

  Marker _createMarker(ChargerSpot spot) {
    return Marker(
      markerId: MarkerId('marker_${spot.latitude}_${spot.longitude}'),
      position: LatLng(spot.latitude, spot.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () => _onMarkerTapped(spot),
    );
  }

  void _onMarkerTapped(ChargerSpot spot) {
    setState(() {
      isMarkerSelected = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _chargerSpots.indexOf(spot);
      final offset = index * (MediaQuery.of(context).size.width * 0.85 + 16);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(),
        _buildSearchButton(),
        _buildChargerSpotCards(),
      ],
    );
  }

  Widget _buildMap() {
    return _currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            padding: EdgeInsets.only(
              bottom:
                  isMarkerSelected ? 360 : (_chargerSpots.isEmpty ? 0 : 140),
            ),
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 16,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _moveCameraToCurrentLocation();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadChargerSpotsInVisibleRegion();
              });
            },
            myLocationEnabled: true,
            // Androidにのみ表示される標準UIを非表示
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          );
  }

  Widget _buildSearchButton() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _loadChargerSpotsInVisibleRegion,
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
            Icon(Icons.search),
          ],
        ),
      ),
    );
  }

  Widget _buildChargerSpotCards() {
    if (_chargerSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Transform.translate(
          offset: isMarkerSelected ? Offset.zero : Offset(0, cellMovementRange),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _chargerSpots.map((spot) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: ChargerSpotCard(spot: spot),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
