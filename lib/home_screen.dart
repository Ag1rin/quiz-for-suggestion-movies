import 'package:flutter/material.dart';
// Add notification and API code here later

class HomeScreen extends StatelessWidget {
  final String favoriteGenre;

  const HomeScreen({super.key, required this.favoriteGenre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Your favorite genre: $favoriteGenre\nDaily movie recommendations coming soon!',
          style: TextStyle(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
