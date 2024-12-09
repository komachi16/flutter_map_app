import 'package:flutter/material.dart';

import '../charger_spot.dart';

class ChargerSpotCard extends StatelessWidget {
  const ChargerSpotCard({super.key, required this.spot});
  final ChargerSpot spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spot.imageUrl != null)
              SizedBox(
                width: 365,
                height: 72,
                child: Image.network(
                  spot.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              spot.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.power, color: Colors.amber),
                const SizedBox(width: 8),
                Text('充電器数: ${spot.chargerDevices.length}台'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                    '充電出力: ${spot.chargerDevices.isNotEmpty ? '${spot.chargerDevices.map(
                          (device) => device.power,
                        ).join(', ')} kW' : '情報なし'}'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.watch_later, color: Colors.amber),
                const SizedBox(width: 8),
                Text('営業時間: ${_getServiceTimes(spot.serviceTimes)}'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.today, color: Colors.amber),
                const SizedBox(width: 8),
                Text('定休日: ${_getClosedDays(spot.serviceTimes)}'),
              ],
            ),
            TextButton(
              onPressed: () {
                // Google Maps アプリで経路を表示する処理
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}';
                // launch(url);
              },
              child: const Text('地図アプリで経路を見る'),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceTimes(List<ServiceTime> serviceTimes) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    // 今日の曜日に対応するサービス時間を取得
    for (final serviceTime in serviceTimes) {
      if (serviceTime.day == today) {
        return '${serviceTime.startTime} - ${serviceTime.endTime}';
      }
    }
    return '営業時間が見つかりません';
  }

  ServiceTimeDay? _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return ServiceTimeDay.monday;
      case 2:
        return ServiceTimeDay.tuesday;
      case 3:
        return ServiceTimeDay.wednesday;
      case 4:
        return ServiceTimeDay.thursday;
      case 5:
        return ServiceTimeDay.friday;
      case 6:
        return ServiceTimeDay.thursday;
      case 7:
        return ServiceTimeDay.sunday;
    }
    return null;
  }

  String _getClosedDays(List<ServiceTime> serviceTimes) {
    final closedDays = serviceTimes
        .where((time) => !time.businessDay)
        .map((time) => time.day.name)
        .toList();

    return closedDays.isNotEmpty ? closedDays.join(', ') : '-';
  }
}
