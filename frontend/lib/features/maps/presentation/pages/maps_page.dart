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
    final destLat = coords[1];
    final destLng = coords[0];
    final name = Uri.encodeComponent(center['name'] as String? ?? 'Blood Center');

    Uri uri;
    if (_userLat != null && _userLng != null) {
      // Ouvre Google Maps avec l'itinéraire depuis la position de l'utilisateur
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$_userLat,$_userLng'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );
    } else {
      // Pas de position connue : ouvre juste la localisation du centre
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng($name)',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: centers.length,
      itemBuilder: (_, i) {
        final c = centers[i];
        final isSelected = selectedCenter?['_id'] == c['_id'];
        final address = c['address'] is String
            ? c['address'] as String
            : c['address'] is Map
                ? (c['address']['street'] ?? c['address']['city'] ?? '') as String
                : '';
        final coords = c['location']?['coordinates'];
        final hasCoords = coords != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              onCenterTap(c);
              onNavigate(c); // clic sur la carte = ouvrir Google Maps
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.local_hospital, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name'] as String? ?? 'Blood Center',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (c['phone'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                c['phone'] as String,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasCoords)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.directions, color: AppColors.primary, size: 22),
                          SizedBox(height: 2),
                          Text('Go',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
