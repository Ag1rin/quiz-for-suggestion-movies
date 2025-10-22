import 'package:flutter/material.dart';
import 'dart:ui'; // For blur
import 'quiz_screen.dart'; // Import for going to quiz

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController; // Controller for GIF animation
  late Animation<double> _fadeAnimation; // Fade effect for reverse simulation

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Adjust based on your GIF length
    )..repeat(reverse: true); // Repeat with reverse
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation, // Fade in/out to simulate reverse
              child: Image.asset('assets/background.gif', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            children: [
              _buildPage(
                'Welcome!',
                'Here you can discover a movie tailored to your interests every day.',
              ),
              _buildPage(
                'How It Works',
                'It starts with a 15-question test to remember your favorite genre and suggest movies daily based on it.',
              ),
              _buildPage(
                'Quiz Guide',
                'The quiz has two options per question. Please answer carefully.',
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_currentPage > 0)
                      _glassButton(
                        'Previous',
                        () => _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        ),
                      ),
                    _glassButton(_currentPage == 2 ? 'Let\'s Go' : 'Next', () {
                      if (_currentPage == 2) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => QuizScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    }),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildDot(index)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(String title, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              description,
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: Text(text, style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: _currentPage == index ? 12 : 8,
      height: _currentPage == index ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.5),
      ),
    );
  }
}
