import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart'; // Import next file
import 'quiz_screen.dart'; // Import next file
import 'home_screen.dart'; // Import home

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimeAndGenre();
  }

  Future<void> _checkFirstTimeAndGenre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoriteGenre = prefs.getString('favoriteGenre');
    if (favoriteGenre != null) {
      // If genre saved, go directly to home
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(favoriteGenre: favoriteGenre),
        ),
      );
    } else {
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
      if (isFirstTime) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => OnboardingScreen()),
        );
        await prefs.setBool('isFirstTime', false);
      } else {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => QuizScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
