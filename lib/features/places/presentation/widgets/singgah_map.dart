import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/domain/entities/geo_point.dart';

/// Shared OpenStreetMap canvas. Tiles are public OSM tiles; search and reverse
/// geocoding still go through the Singgah Edge Function, never Nominatim
/// directly from the client.
class SinggahMap extends StatefulWidget {
  const SinggahMap({
    super.key,
    required this.center,
    this.marker,
    this.onTap,
    this.height = 300,
    this.interactive = true,
    this.zoom = 15,
  });

  final GeoPoint center;
  final GeoPoint? marker;
  final ValueChanged<GeoPoint>? onTap;
  final double height;
  final bool interactive;
  final double zoom;

  @override
  State<SinggahMap> createState() => _SinggahMapState();
}

class _SinggahMapState extends State<SinggahMap> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant SinggahMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center &&
        widget.center.latitude.isFinite &&
        widget.center.longitude.isFinite) {
      _controller.move(
        LatLng(widget.center.latitude, widget.center.longitude),
        _controller.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.singgah;
    final marker = widget.marker ?? widget.center;
    return ClipRRect(
      borderRadius: AppRadius.allLg,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: LatLng(
                  widget.center.latitude,
                  widget.center.longitude,
                ),
                initialZoom: widget.zoom,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.all & ~InteractiveFlag.rotate
                      : InteractiveFlag.none,
                ),
                backgroundColor: colors.mapTint,
                onTap: widget.onTap == null
                    ? null
                    : (tapPosition, point) => widget.onTap!(
                        GeoPoint(point.latitude, point.longitude),
                      ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.singgah.singgah',
                  retinaMode: MediaQuery.devicePixelRatioOf(context) > 1.4,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(marker.latitude, marker.longitude),
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 42,
                        color: colors.accent,
                        shadows: [
                          Shadow(
                            color: colors.shadow.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.88),
                  borderRadius: AppRadius.allSm,
                ),
                child: Text(
                  context.l10n.mapAttribution,
                  style: context.texts.bodySmall?.copyWith(fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
