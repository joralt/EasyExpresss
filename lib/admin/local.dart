import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;


class LocalesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Locales',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildHorizontalButton(
              context: context,
              label: 'Agregar Local',
              imagePath: 'assets/arestaurante.png', // Reemplaza con tu imagen
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgregarLocalScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildHorizontalButton(
              context: context,
              label: 'Modificar Local',
              imagePath: 'assets/edicion.png', // Reemplaza con tu imagen
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModificarLocalScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            _buildHorizontalButton(
              context: context,
              label: 'Eliminar Local',
              imagePath: 'assets/eliminar.png', // Reemplaza con tu imagen
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EliminarLocalScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHorizontalButton({
    required BuildContext context,
    required String label,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeleccionarUbicacionScreen extends StatefulWidget {
  @override
  _SeleccionarUbicacionScreenState createState() => _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState extends State<SeleccionarUbicacionScreen> {
  LatLng _selectedLocation = LatLng(-0.938889, -79.223889); // La Maná, Ecuador

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Ubicación')),
      body: FlutterMap(
        options: MapOptions(
          center: _selectedLocation,
          zoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: _selectedLocation,
                builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, _selectedLocation);
        },
      ),
    );
  }
}


class AgregarLocalScreen extends StatefulWidget {
  @override
  _AgregarLocalScreenState createState() => _AgregarLocalScreenState();
}

class _AgregarLocalScreenState extends State<AgregarLocalScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? selectedCategory;
  LatLng? selectedLocation;
  File? _selectedImage;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng location) async {
    try {
      print("📍 Obteniendo dirección para: ${location.latitude}, ${location.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street}, ${place.locality}, ${place.country}";
        print("✅ Dirección obtenida: $address");
        return address;
      } else {
        print("⚠️ No se encontraron direcciones para estas coordenadas.");
        return "Sin dirección disponible";
      }
    } catch (e) {
      print("❌ Error al obtener dirección: $e");
      return "Sin dirección disponible";
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      print("⏳ Iniciando subida de imagen...");

      String fileName = "locales/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: "image/jpeg",
      );

      UploadTask uploadTask = ref.putFile(imageFile, metadata);

      print("📤 Subiendo imagen a Firebase Storage...");

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print("✅ Imagen subida con éxito: $downloadUrl");
        return downloadUrl;
      } else {
        print("❌ Error: La imagen no se subió correctamente.");
        return null;
      }
    } catch (e) {
      print("❌ Error al subir la imagen: $e");
      return null;
    }
  }

  void agregarLocal() async {
    if (!_formKey.currentState!.validate()) {
      print("❌ Validación del formulario fallida");
      return;
    }

    setState(() => isLoading = true);
    print("⏳ Iniciando proceso de guardado...");

    // 🔍 Intentar obtener dirección antes de guardar
    String address = "Sin dirección disponible";
    if (selectedLocation != null) {
      address = await _getAddressFromCoordinates(selectedLocation!);
    }

    String? imageUrl;
    if (_selectedImage != null) {
      print("📸 Subiendo imagen...");
      imageUrl = await _uploadImage(_selectedImage!);

      if (imageUrl == null) {
        print("❌ Error: La imagen no se subió correctamente");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir la imagen')));
        setState(() => isLoading = false);
        return;
      }
      print("✅ Imagen subida con URL: $imageUrl");
    }

    final newLocal = {
      'Nombre': nameController.text.trim(),
      'Categoria': selectedCategory,
      'Contacto': contactController.text.trim(),
      'Descripción': descriptionController.text.trim(),
      'Ubicación': address,  // ✅ Se guarda la dirección en vez de coordenadas
      'Coordenadas': selectedLocation != null
          ? {'lat': selectedLocation!.latitude, 'lng': selectedLocation!.longitude}
          : null,
      'Estado': 'Activo',
      'Imagen': imageUrl ?? '',
    };

    print("📌 Datos a guardar en Firestore: $newLocal");

    try {
      await FirebaseFirestore.instance.collection('LOCALES').add(newLocal);
      print("✅ Local guardado con éxito en Firestore");

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local agregado con éxito')));
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error al guardar en Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }

    setState(() {
      isLoading = false;
      print("✔️ Finalizado el guardado, botón habilitado.");
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Local'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'Categoría'),
                  items: ["Restaurantes", "Rapida", "Picanterías", "Tiendas", "Farmacias", "Heladerias", "Licorerias"]
                      .map((category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value),
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
                ),
                SizedBox(height: 15),
                _buildTextField(controller: nameController, label: 'Nombre del Local', icon: Icons.store),
                SizedBox(height: 15),

                // 🔹 Selector de Imagen
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                          Text("Agregar Imagen", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                _buildTextField(controller: contactController, label: 'Contacto', icon: Icons.phone),
                SizedBox(height: 15),
                _buildTextField(controller: descriptionController, label: 'Descripción', icon: Icons.description),
                SizedBox(height: 15),

                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.map),
                      onPressed: () async {
                        LatLng? pickedLocation = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SeleccionarUbicacionScreen()),
                        );

                        if (pickedLocation != null) {
                          setState(() {
                            selectedLocation = pickedLocation;
                            locationController.text = "Lat: ${pickedLocation.latitude}, Lng: ${pickedLocation.longitude}";
                          });
                        }
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Selecciona una ubicación' : null,
                ),
                SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : agregarLocal,
                    child: Text('Guardar Local', style: TextStyle(fontSize: 16, color: Colors.black)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerScreen({Key? key, required this.initialLocation}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pickedLocation = widget.initialLocation;
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Seleccionar Ubicación")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _pickedLocation ?? widget.initialLocation,
              zoom: 15.0,
              onTap: (tapPosition, latLng) => setState(() => _pickedLocation = latLng),
            ),
            children: [
              TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation!,
                      builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // Botón para agregar ubicación actual
          Positioned(
            bottom: 80,
            left: 20,
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.my_location, color: Colors.white),
              label: Text("Ubicación Actual"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 160), // Mueve el botón más arriba
        child: FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: () => Navigator.pop(context, _pickedLocation),
        ),
      ),
    );
  }
}





























class ModificarLocalScreen extends StatefulWidget {
  @override
  _ModificarLocalScreenState createState() => _ModificarLocalScreenState();
}

class _ModificarLocalScreenState extends State<ModificarLocalScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController platoNameController = TextEditingController();
  final TextEditingController platoDescriptionController = TextEditingController();
  final TextEditingController platoPriceController = TextEditingController();

  String? selectedLocalId;
  String? selectedPlatoId;
  Map<String, dynamic>? selectedLocalData;

  File? _image; // Para almacenar la imagen seleccionada
  String? _imageUrl; // Para almacenar la URL de la imagen subida
  final ImagePicker _picker = ImagePicker(); // Instancia de ImagePicker

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    platoNameController.dispose();
    platoDescriptionController.dispose();
    platoPriceController.dispose();
    super.dispose();
  }

  Future<void> fetchLocalData(String localId) async {
    final localSnapshot = await FirebaseFirestore.instance.collection('LOCALES').doc(localId).get();
    if (localSnapshot.exists) {
      final data = localSnapshot.data()!;
      setState(() {
        selectedLocalId = localId;
        selectedLocalData = data;
        nameController.text = data['Nombre'] ?? '';
        categoryController.text = data['Categoria'] ?? '';
        contactController.text = data['Contacto'] ?? '';
        descriptionController.text = data['Descripción'] ?? '';
        locationController.text = data['Ubicación'] ?? '';
      });
    }
  }



  void modificarLocal() async {
    if (selectedLocalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona un local para modificar')),
      );
      return;
    }


    final updatedData = {
      'Nombre': nameController.text.trim(),
      'Categoria': categoryController.text.trim(),
      'Contacto': contactController.text.trim(),
      'Descripción': descriptionController.text.trim(),
      'Ubicación': locationController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance.collection('LOCALES').doc(selectedLocalId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local modificado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al modificar el local: $e')),
      );
    }
  }
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage(); // Llamamos a la función para subir la imagen
    }
  }


  Future<void> _uploadImage() async {
    if (_image == null) {
      print('Error: No se ha seleccionado una imagen.');
      return;
    }

    Future<String?> _uploadImage() async {
      if (_image == null) {
        print('⚠ No se ha seleccionado ninguna imagen.');
        return null;
      }

      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('platos/$fileName.jpg');

        UploadTask uploadTask = storageRef.putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('✅ Imagen subida correctamente: $downloadUrl');

        return downloadUrl; // 🔴 Retornamos la URL de la imagen
      } catch (e) {
        print('❌ Error al subir la imagen: $e');
        return null;
      }
    }

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('platos/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;

      // 🔴 Obtener la URL de la imagen subida
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
      });

      print('✅ Imagen subida correctamente: $_imageUrl');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagen subida con éxito')),
      );
    } catch (e) {
      print('❌ Error al subir la imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e')),
      );
    }
  }

  void agregarOmodificarPlato() async {
    if (selectedLocalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona un local primero')),
      );
      return;
    }
    Future<String?> _uploadImage() async {
      if (_image == null) {
        print('⚠ No se ha seleccionado ninguna imagen.');
        return null;
      }

      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('platos/$fileName.jpg');

        SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg', // 🔴 Evita el error de metadatos nulos
        );

        UploadTask uploadTask = storageRef.putFile(_image!, metadata);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('✅ Imagen subida correctamente: $downloadUrl');

        return downloadUrl; // 🔴 Ahora la función RETORNA la URL
      } catch (e) {
        print('❌ Error al subir la imagen: $e');
        return null;
      }
    }

    final double? precio = double.tryParse(platoPriceController.text.trim());
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa un precio válido')),
      );
      return;
    }

    // 🔴 Esperar la subida de la imagen antes de guardar en Firestore
    if (_image != null) {
      _imageUrl = await _uploadImage(); // 🔴 Aquí esperamos la URL de la imagen
    }

    // 📌 Verificar que la URL de la imagen esté lista antes de guardar
    if (_image != null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen. Inténtalo de nuevo.')),
      );
      return;
    }

    final platoData = {
      'nombre': platoNameController.text.trim(),
      'descripcion': platoDescriptionController.text.trim(),
      'precio': precio,
      'imagen': _imageUrl ?? '', // Guardamos la URL de la imagen en Firestore
    };

    try {
      if (selectedPlatoId == null) {
        await FirebaseFirestore.instance
            .collection('LOCALES')
            .doc(selectedLocalId)
            .collection('PLATOS')
            .add(platoData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plato agregado con éxito')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('LOCALES')
            .doc(selectedLocalId)
            .collection('PLATOS')
            .doc(selectedPlatoId)
            .update(platoData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plato modificado con éxito')),
        );
      }

      // 🔴 Limpiar los datos después de agregar/modificar
      platoNameController.clear();
      platoDescriptionController.clear();
      platoPriceController.clear();
      setState(() {
        _image = null;
        _imageUrl = null;
        selectedPlatoId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el plato: $e')),
      );
    }
  }

  void cargarPlatoParaEditar(String platoId, Map<String, dynamic> platoData) {
    setState(() {
      selectedPlatoId = platoId;
      platoNameController.text = platoData['nombre'] ?? '';
      platoDescriptionController.text = platoData['descripcion'] ?? '';
      platoPriceController.text = platoData['precio']?.toString() ?? '';
    });
  }

  Widget _buildPlatosList(String localId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('LOCALES')
          .doc(localId)
          .collection('PLATOS')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar los platos.'));
        }

        final platos = snapshot.data?.docs ?? [];

        if (platos.isEmpty) {
          return Center(
            child: Text(
              'No hay platos disponibles',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: platos.length,
          itemBuilder: (context, index) {
            final plato = platos[index];
            final platoData = plato.data() as Map<String, dynamic>;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  platoData['nombre'] ?? 'Sin nombre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  platoData['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                trailing: Text(
                  '\$${platoData['precio']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () {
                  cargarPlatoParaEditar(plato.id, platoData);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modificar Local',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection('LOCALES').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }

                final locales = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedLocalId,
                  decoration: InputDecoration(
                    labelText: 'Selecciona un local',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  isExpanded: true,
                  items: locales.map((local) {
                    final localData = local.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: local.id,
                      child: Text(localData['Nombre'] ?? 'Sin nombre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    fetchLocalData(value!);
                  },
                );
              },
            ),
            if (selectedLocalData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: nameController,
                          label: 'Nombre del Local',
                          icon: Icons.store,
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: categoryController,
                          label: 'Categoría',
                          icon: Icons.category,
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: contactController,
                          label: 'Contacto',
                          icon: Icons.phone,
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: descriptionController,
                          label: 'Descripción',
                          icon: Icons.description,
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          controller: locationController,
                          label: 'Ubicación',
                          icon: Icons.location_on,
                        ),
                        SizedBox(height: 30),
                        Center(
                          child: ElevatedButton(
                            onPressed: modificarLocal,
                            child: Text(
                              'Guardar Cambios',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Divider(),
                        Text(
                          'Platos',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        _buildPlatosList(selectedLocalId ?? ''),
                        Divider(),
                        _buildTextField(
                          controller: platoNameController,
                          label: 'Nombre del Plato',
                          icon: Icons.fastfood,
                        ),
                        SizedBox(height: 10),
                        _buildTextField(
                          controller: platoDescriptionController,
                          label: 'Descripción del Plato',
                          icon: Icons.description,
                        ),
                        SizedBox(height: 10),
                        _buildTextField(
                          controller: platoPriceController,
                          label: 'Precio del Plato',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage, // Llamamos a la función para seleccionar imagen
                            icon: Icon(Icons.image),
                            label: Text('Seleccionar Imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _image != null
                            ? Center(
                          child: Image.file(
                            _image!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        )
                            : _imageUrl != null
                            ? Center(
                          child: Image.network(
                            _imageUrl!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: agregarOmodificarPlato,
                            child: Text(
                              selectedPlatoId == null ? 'Agregar Plato' : 'Modificar Plato',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}










































class EliminarLocalScreen extends StatelessWidget {
  void eliminarLocal(BuildContext context, String localId) async {
    try {
      await FirebaseFirestore.instance.collection('LOCALES').doc(localId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local eliminado con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el local: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eliminar Local',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('LOCALES').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final locales = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: locales.length,
            itemBuilder: (context, index) {
              final local = locales[index];
              final localData = local.data() as Map<String, dynamic>;
              final localId = local.id;

              return Card(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(Icons.store, color: Colors.green, size: 30),
                  title: Text(
                    localData['Nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    localData['Ubicación'] ?? 'Sin ubicación',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      eliminarLocal(context, localId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


