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
        _chargerSpots = response.spots;

        _markers.clear();
        for (final spot in response.spots) {
          _addMarker(
            spot.latitude,
            spot.longitude,
            spot.chargerDevices.length,
            spot,
          );
        }
      });
    }
  }

  void _addMarker(double lat, double lng, int chargerCount, ChargerSpot spot) {
    final marker = Marker(
      markerId: MarkerId('marker_$lat$lng'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () {
        setState(() {
          isMarkerSelected = true;
        });

        // スクロール位置を調整
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = _chargerSpots.indexOf(spot);
          final offset = index *
              (MediaQuery.of(context).size.width * 0.85 + 16); // カードの幅と余白を考慮
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      },
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
                padding: EdgeInsets.only(
                    bottom: isMarkerSelected
                        ? 360
                        : (_chargerSpots.isEmpty ? 0 : 140)),
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
                Icon(Icons.search),
              ],
            ),
          ),
        ),
        _chargerSpots.isNotEmpty
            ? Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Transform.translate(
                    offset: isMarkerSelected
                        ? Offset.zero
                        : Offset(0, cellMovementRange),
                    child: SingleChildScrollView(
                      controller: _scrollController, // ScrollControllerを指定
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._chargerSpots.map((spot) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.85,
                                child: ChargerSpotCard(spot: spot),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
