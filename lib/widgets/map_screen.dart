import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// If you want clickable attribution links:
// import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // You might want to customize or remove the AppBar depending on your app structure
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.teal, // Example customization
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(
              51.509865, -0.118092), // Example: London (adjust as needed)
          initialZoom: 14.0,
          interactionOptions: InteractionOptions(
              // Optional: enable rotation, pinch zoom, double tap zoom etc.
              // flags: InteractiveFlag.all,
              ),
        ),
        children: [
          // --- Tile Layer without POIs (Points of Interest) ---
          TileLayer(
            // CARTO Voyager No Labels - designed for minimal place markers
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'], // Standard CARTO subdomains
            // It's polite and often required to identify your app
            // IMPORTANT: Replace with your actual package name
            userAgentPackageName: 'com.yourcompany.yourappname',
            // tileProvider: CachedTileProvider(), // Optional: Enables caching tiles locally
          ),

          // --- Attribution Layer (Very Important!) ---
          // You MUST attribute the map data source (OSM) and the tile provider (CARTO)
          const RichAttributionWidget(
            popupInitialDisplayDuration: Duration(seconds: 5),
            animationConfig: ScaleRAWA(), // Optional nice animation
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                // Optional: Make OSM link clickable (requires url_launcher package)
                // onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
              TextSourceAttribution(
                'CARTO',
                // Optional: Make CARTO link clickable (requires url_launcher package)
                // onTap: () => launchUrl(Uri.parse('https://carto.com/attributions')),
              ),
            ],
          ),

          // You can add other layers here if needed, like MarkerLayer, PolygonLayer, etc.
          // Example (requires adding markers):
          // MarkerLayer(markers: [
          //   Marker(
          //     point: LatLng(51.509865, -0.118092),
          //     width: 80,
          //     height: 80,
          //     child: FlutterLogo(), // Replace with your marker widget
          //   ),
          // ]),
        ],
      ),
    );
  }
}
