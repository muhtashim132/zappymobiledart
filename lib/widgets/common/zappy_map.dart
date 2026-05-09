import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';

class ZappyMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final bool interactive;

  const ZappyMap({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.markers = const [],
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.zappy.app',
        ),
        MarkerLayer(
          markers: [
            // Default center marker if no markers provided
            if (markers.isEmpty)
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
            ...markers,
          ],
        ),
      ],
    );
  }
}
