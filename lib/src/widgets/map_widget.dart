// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple;
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart' as latlong;

// class MapWidget extends StatefulWidget {
//   final bool isIOS;
//   final Function(String) onMarkerTapped;

//   const MapWidget(
//       {super.key, required this.isIOS, required this.onMarkerTapped});

//   @override
//   // ignore: library_private_types_in_public_api
//   _MapWidgetState createState() => _MapWidgetState();
// }

// class _MapWidgetState extends State<MapWidget> {
//   final Set<apple.Marker> _appleMarkers = {};
//   final List<Marker> _flutterMapMarkers = [];

//   @override
//   void initState() {
//     super.initState();
//     _addMarkers();
//   }

//   void _addMarkers() {
//     // Example restaurant locations
//     final List<Map<String, dynamic>> restaurants = [
//       {'name': 'Restaurant 1', 'lat': 46.8182, 'lng': 8.2275},
//       {'name': 'Restaurant 2', 'lat': 46.8282, 'lng': 8.2375},
//       {'name': 'Restaurant 3', 'lat': 46.8382, 'lng': 8.2475},
//     ];

//     setState(() {
//       // Add markers for Apple Maps
//       for (final restaurant in restaurants) {
//         _appleMarkers.add(
//           apple.Marker(
//             markerId: apple.MarkerId(restaurant['name']),
//             position: apple.LatLng(restaurant['lat'], restaurant['lng']),
//             infoWindow: apple.InfoWindow(
//               title: restaurant['name'],
//             ),
//             onTap: () {
//               widget.onMarkerTapped(restaurant['name']);
//             },
//           ),
//         );
//       }
      
//       // Add markers for Flutter Map
//       for (final restaurant in restaurants) {
//         _flutterMapMarkers.add(
//           Marker(
//             width: 80.0,
//             height: 80.0,
//             point: latlong.LatLng(restaurant['lat'], restaurant['lng']),
//             child: GestureDetector(
//               onTap: () => widget.onMarkerTapped(restaurant['name']),
//               child: Column(
//                 children: [
//                   const Icon(Icons.location_on, color: Colors.red, size: 30),
//                   Text(restaurant['name'], style: const TextStyle(fontSize: 12)),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.isIOS) {
//       // Use Apple Map for iOS
//       return apple.AppleMap(
//         initialCameraPosition: const apple.CameraPosition(
//           target: apple.LatLng(46.8182, 8.2275), // Center of Switzerland
//           zoom: 8,
//         ),
//         mapType: apple.MapType.standard,
//         myLocationEnabled: true,
//         myLocationButtonEnabled: true,
//         markers: _appleMarkers,
//       );
//     } else {
//       // Use Flutter Map for Android
//       return FlutterMap(
//         options: MapOptions(
//           center: latlong.LatLng(46.8182, 8.2275), // Center of Switzerland
//           zoom: 8,
//           onTap: (tapPosition, point) {
//             // Handle map tap if needed
//           },
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//             userAgentPackageName: 'com.example.app',
//           ),
//           MarkerLayer(markers: _flutterMapMarkers),
//         ],
//       );
//     }
//   }
// }
