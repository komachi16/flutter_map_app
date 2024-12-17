import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../charger_spot.dart';
import '../utils/asset_images.dart';

class ChargerSpotCard extends StatelessWidget {
  const ChargerSpotCard({super.key, required this.spot});
  final ChargerSpot spot;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          const SizedBox(height: 8),
          _buildInfoColumn(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      width: 365,
      height: 72,
      child: spot.imageUrl != null
          ? _buildNetworkImage(spot.imageUrl!)
          : _buildDefaultImage(),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildDefaultImage() {
    return SvgPicture.asset(
      AssetImages.defaultImage,
    );
  }

  Widget _buildInfoColumn() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpotName(),
          const SizedBox(height: 8),
          _buildChargerCount(),
          const SizedBox(height: 12),
          _buildChargerPower(),
          const SizedBox(height: 12),
          _buildServiceTime(),
          const SizedBox(height: 12),
          _buildClosedDays(),
          const SizedBox(height: 12),
          _buildMapButton(),
        ],
      ),
    );
  }

  Widget _buildSpotName() {
    return Text(
      spot.name,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildChargerCount() {
    return _buildInfoRow(
      icon: Icons.power,
      title: '充電器数',
      text: '${spot.chargerDevices.length}台',
    );
  }

  Widget _buildChargerPower() {
    final powerInfo = spot.chargerDevices.isNotEmpty
        ? '${spot.chargerDevices.map((device) => device.power).join(', ')} kW'
        : '情報なし';
    return _buildInfoRow(
      icon: Icons.bolt,
      title: '充電出力',
      text: powerInfo,
    );
  }

  Widget _buildServiceTime() {
    return _buildServiceTimeRow(
      text: _getServiceTimes(spot.serviceTimes),
      isServiceTime: _getIsServiceTime(spot.serviceTimes),
    );
  }

  Widget _buildClosedDays() {
    return _buildInfoRow(
      icon: Icons.today,
      title: '定休日',
      text: _getClosedDays(spot.serviceTimes),
    );
  }

  Widget _buildMapButton() {
    return TextButton(
      onPressed: () {
        final url =
            'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}';
        // launch(url);
      },
      child: const Text('地図アプリで経路を見る'),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.amber),
        const SizedBox(width: 8),
        Text(title),
        const SizedBox(width: 16),
        Text(text),
      ],
    );
  }

  Widget _buildServiceTimeRow({
    required String text,
    required bool isServiceTime,
  }) {
    final title = isServiceTime ? '営業中' : '営業時間外';
    final titleColor = isServiceTime ? Colors.green : Colors.black38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.watch_later, color: Colors.amber),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
          ),
        ),
        const SizedBox(width: 16),
        Text(text),
      ],
    );
  }

  bool _getIsServiceTime(List<ServiceTime> serviceTimes) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    for (final serviceTime in serviceTimes) {
      if (serviceTime.day == today) {
        return serviceTime.businessDay;
      }
    }
    return false;
  }

  String _getServiceTimes(List<ServiceTime> serviceTimes) {
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
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
        return ServiceTimeDay.saturday;
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
