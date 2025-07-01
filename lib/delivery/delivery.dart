// lib/delivery/delivery_dashboard.dart
import 'package:flutter/material.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Repartidor')),
      body: const Center(child: Text('Aquí verás tus entregas asignadas')),
    );
  }
}
