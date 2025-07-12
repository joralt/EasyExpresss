// lib/map_info.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show NetworkTileProvider;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';      // Para reverse-geocoding
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class MapInfoPage extends StatefulWidget {
  const MapInfoPage({Key? key}) : super(key: key);

  @override
  State<MapInfoPage> createState() => _MapInfoPageState();
}

class _MapInfoPageState extends State<MapInfoPage> {
  final MapController _mapController = MapController();

  /// Coordenadas de La Maná, Cotopaxi
  LatLng _center = LatLng(-0.9337, -79.2044);
  LatLng? _markerPos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, 15);
    });
  }

  Future<void> _locateMe() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu GPS'))
      );
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    final me = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _center = me;
      _markerPos = me;
      _mapController.move(me, 17);
    });
  }

  Future<void> _openInWaze() async {
    if (_markerPos == null) return;
    final lat = _markerPos!.latitude, lng = _markerPos!.longitude;
    final uriApp = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      final uriWeb = Uri.parse(
        'https://www.waze.com/ul?ll=$lat%2C$lng&navigate=yes'
      );
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    final marker = _markerPos;
    if (user == null || marker == null) {
      Navigator.pop(context);
      return;
    }

    // Reverse geocode
    List<Placemark> placemarks = await placemarkFromCoordinates(
      marker.latitude, marker.longitude
    );
    final pm = placemarks.first;
    final addressString = [
      if (pm.street?.isNotEmpty == true) pm.street,
      if (pm.subLocality?.isNotEmpty == true) pm.subLocality,
      if (pm.locality?.isNotEmpty == true) pm.locality,
      if (pm.administrativeArea?.isNotEmpty == true) pm.administrativeArea,
    ].join(', ');

    // Guardar en Firestore
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .set({
      'location': GeoPoint(marker.latitude, marker.longitude),
      'address': addressString,
    }, SetOptions(merge: true));

    // Navegar al HomeScreen
    final userData = {
      'Nombres': user.displayName ?? '',
      'Correo': user.email ?? '',
      'Foto': user.photoURL ?? '',
      'location': GeoPoint(marker.latitude, marker.longitude),
      'address': addressString,
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu dirección'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Mi ubicación actual'),
            onTap: _locateMe,
          ),
          const Divider(height: 1),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _center,
                zoom: 15,
                onTap: (_, latlng) => setState(() {
                  _markerPos = latlng;
                }),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  // <-- Aquí agregamos el User-Agent obligatorio
                  tileProvider: NetworkTileProvider(
                    headers: {
                      'User-Agent': 'EasyExpress/1.0 (contacto@tudominio.com)'
                    },
                  ),
                ),
                if (_markerPos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerPos!,
                        width: 40,
                        height: 40,
                        builder: (_) => const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
          if (_markerPos != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('Abrir en Waze'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _openInWaze,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _confirm,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
