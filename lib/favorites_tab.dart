import 'package:flutter/material.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Favoritos',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
