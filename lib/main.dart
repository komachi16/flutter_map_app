import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'charger_spots_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Map App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final ChargerSpotsRepository _repository = ChargerSpotsRepository();
  LatLng? _currentLocation; // 現在地を保存する変数
  static const double _kmRange = 0.01; // 約1kmの変化量

  // static const CameraPosition _initialPosition = CameraPosition(
  //   target: LatLng(35.681236, 139.767125), // 初期位置（東京駅）
  //   zoom: 12,
  // );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 現在地を取得
  }

  Future<void> _getCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      await _loadChargerSpots(); // 現在地取得後に充電スポットを読み込む
    }
  }

  Future<void> _loadChargerSpots() async {
    if (_currentLocation == null) {
      return; // 現在地が取得できていない場合は終了
    }

    final response = await _repository.getChargerSpots(
      swLat: _currentLocation!.latitude - _kmRange, // 南西の緯度
      swLng: _currentLocation!.longitude - _kmRange, // 南西の経度
      neLat: _currentLocation!.latitude + _kmRange, // 北東の緯度
      neLng: _currentLocation!.longitude + _kmRange, // 北東の経度
    );

    if (response.status == GetChargerSpotsStatus.ok) {
      setState(() {
        _markers.clear();
        for (final spot in response.spots) {
          _markers.add(
            Marker(
              markerId: MarkerId(spot.uuid),
              position: LatLng(spot.latitude, spot.longitude),
              infoWindow: InfoWindow(
                title: spot.name,
                snippet: '充電器数: ${spot.chargerDevices.length}',
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentLocation!, zoom: 16),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
    );
  }
}
