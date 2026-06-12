import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  double? _userLat;
  double? _userLng;
  List<dynamic> _centers = [];
  dynamic _selectedCenter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      await _loadNearestCenters(position.longitude, position.latitude);
    } catch (_) {
      setState(() {
        _userLat = 18.0735;
        _userLng = -15.9582;
      });
      await _loadNearestCenters(-15.9582, 18.0735);
    }
  }

  Future<void> _loadNearestCenters(double lng, double lat) async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.nearestCenters,
        queryParameters: {'lng': lng, 'lat': lat, 'radius': 100},
      );
      final centers = response.data['data'] as List;
      setState(() {
        _centers = centers;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _navigateTo(dynamic center) async {
    final coords = center['location']?['coordinates'];
    if (coords == null) return;
    final lat = coords[1];
    final lng = coords[0];
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${center['name']})');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Blood Centers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _MapPlaceholder(
                  userLat: _userLat,
                  userLng: _userLng,
                  centersCount: _centers.length,
                ),
                Expanded(
                  child: _centers.isEmpty
                      ? _EmptyState()
                      : _CentersList(
                          centers: _centers,
                          selectedCenter: _selectedCenter,
                          onCenterTap: (c) =>
                              setState(() => _selectedCenter = c),
                          onNavigate: _navigateTo,
                        ),
                ),
              ],
            ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final double? userLat;
  final double? userLng;
  final int centersCount;

  const _MapPlaceholder({
    required this.userLat,
    required this.userLng,
    required this.centersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 56, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text(
            'Map view requires a Google Maps API key',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (userLat != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your location: ${userLat!.toStringAsFixed(4)}, ${userLng!.toStringAsFixed(4)}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$centersCount center(s) found within 100 km',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital_outlined, size: 64, color: AppColors.divider),
          SizedBox(height: 12),
          Text('No blood centers found nearby',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CentersList extends StatelessWidget {
  final List<dynamic> centers;
  final dynamic selectedCenter;
  final ValueChanged<dynamic> onCenterTap;
  final Future<void> Function(dynamic) onNavigate;

  const _CentersList({
    required this.centers,
    required this.selectedCenter,
    required this.onCenterTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: centers.length,
      itemBuilder: (_, i) {
        final c = centers[i];
        final isSelected = selectedCenter?['_id'] == c['_id'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.local_hospital, color: AppColors.primary),
            ),
            title: Text(c['name'] ?? 'Blood Center',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: c['address'] != null
                ? Text(c['address'],
                    maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.navigation, color: AppColors.primary),
              onPressed: () => onNavigate(c),
            ),
            onTap: () => onCenterTap(c),
          ),
        );
      },
    );
  }
}
