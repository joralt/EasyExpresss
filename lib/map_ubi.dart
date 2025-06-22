// map_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart'; // Asegúrate de que este nombre coincide con tu archivo

class MapInfoPage extends StatefulWidget {
  const MapInfoPage({Key? key}) : super(key: key);

  @override
  State<MapInfoPage> createState() => _MapInfoPageState();
}

class _MapInfoPageState extends State<MapInfoPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  LatLng _center = LatLng(-0.1807, -78.4678);
  LatLng? _markerPos;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activa tu GPS')));
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _center = LatLng(pos.latitude, pos.longitude);
      _markerPos = _center;
    });
  }

  Future<void> _openInWaze() async {
    if (_markerPos == null) return;
    final lat = _markerPos!.latitude, lng = _markerPos!.longitude;
    final uriApp = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      final uriWeb = Uri.parse('https://www.waze.com/ul?ll=$lat%2C$lng&navigate=yes');
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  }

  void _confirm() {
    final user = FirebaseAuth.instance.currentUser;
    final marker = _markerPos;
    if (user == null || marker == null) {
      Navigator.pop(context);
      return;
    }

    final userData = {
      'Nombres': user.displayName ?? '',
      'Correo' : user.email ?? '',
      'Foto'   : user.photoURL ?? '',
      'location': GeoPoint(marker.latitude, marker.longitude),
    };

    // Navega inmediatamente al HomeScreen
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => HomeScreen(userData: userData),
    ));

    // Guarda la ubicación en Firestore en segundo plano
    FirebaseFirestore.instance.collection('usuarios').doc(user.uid)
      .set({'location': GeoPoint(marker.latitude, marker.longitude)}, SetOptions(merge: true))
      .then((_) => debugPrint('Ubicación guardada en Firestore'))
      .catchError((e) => debugPrint('Error guardando ubicación: \$e'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresa tu dirección'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mi perfil', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Dirección o punto de referencia',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.my_location),
          title: const Text('Mi ubicación actual'),
          onTap: _locateMe,
        ),
        ListTile(
          leading: const Icon(Icons.public),
          title: const Text('Cambiar de país'),
          subtitle: const Text('Ecuador'),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: FlutterMap(
            options: MapOptions(
              center: _center,
              zoom: 15,
              onTap: (_, latlng) => setState(() => _markerPos = latlng),
            ),
            children: [
              TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: const ['a','b','c']),
              if (_markerPos != null)
                MarkerLayer(markers: [Marker(point: _markerPos!, width:40, height:40, builder: (_)=> const Icon(Icons.location_on, size:40, color:Colors.red))]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:3), color:Colors.white70,
            child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize:10)),
          ),
        ),
        const SizedBox(height: 24),
        if (_markerPos != null)
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text('Abrir en Waze'),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),padding: const EdgeInsets.symmetric(vertical:14)),
            onPressed: _openInWaze,
          )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: _confirm,
          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical:14)),
          child: const Text('Confirmar'),
        )),
      ]),
    );
  }
}
