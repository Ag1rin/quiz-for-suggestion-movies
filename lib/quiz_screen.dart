import 'package:flutter/material.dart';
import 'dart:ui'; // For blur
import 'home_screen.dart'; // Import for going to home

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestion = 0;
  Map<String, int> genreScores = {
    'Action': 0,
    'Drama': 0,
    'Comedy': 0,
    'Horror': 0,
    'Sci-Fi': 0,
    'Romance': 0,
    'Thriller': 0,
    'Adventure': 0,
    'Fantasy': 0,
    'Animation': 0,
    'Documentary': 0,
    'Mystery': 0,
    'Crime': 0,
    'Biography': 0,
    'Musical': 0,
  };

  List<Map<String, dynamic>> questions = [
    {
      'question':
          'Do you enjoy movies with intense action scenes and high-speed chases?',
      'genre': 'Action',
    },
    {
      'question':
          'Are dramatic films that focus on human relationships and emotions appealing to you?',
      'genre': 'Drama',
    },
    {
      'question':
          'Do you prefer movies filled with jokes and hilarious situations?',
      'genre': 'Comedy',
    },
    {
      'question':
          'Do you like horror movies with scary scenes and unknown terrors?',
      'genre': 'Horror',
    },
    {
      'question':
          'Are you interested in sci-fi films featuring future technology and space exploration?',
      'genre': 'Sci-Fi',
    },
    {
      'question':
          'Do romantic movies with heartfelt love stories matter to you?',
      'genre': 'Romance',
    },
    {
      'question':
          'Do you enjoy films with suspense, mysteries, and plot twists?',
      'genre': 'Thriller',
    },
    {
      'question':
          'Is adventure in nature, discovering new places, and epic journeys exciting for you?',
      'genre': 'Adventure',
    },
    {
      'question':
          'Do you prefer fantasy movies with magic, mythical creatures, and imaginary worlds?',
      'genre': 'Fantasy',
    },
    {
      'question':
          'Are creative animated films with engaging stories for all ages interesting to you?',
      'genre': 'Animation',
    },
    {
      'question':
          'Do you like documentary films that explore real-life events and facts?',
      'genre': 'Documentary',
    },
    {
      'question':
          'Are mystery movies with puzzles and detective work your thing?',
      'genre': 'Mystery',
    },
    {
      'question':
          'Do crime films involving investigations and criminal activities appeal to you?',
      'genre': 'Crime',
    },
    {
      'question':
          'Are biographical movies about real people\'s lives and achievements inspiring?',
      'genre': 'Biography',
    },
    {
      'question':
          'Do you enjoy musical films with songs, dances, and performances?',
      'genre': 'Musical',
    },
  ];

  List<String?> answers = List.filled(15, null); // For storing answers
  late AnimationController _animationController; // Controller for GIF animation
  late Animation<double> _fadeAnimation; // Fade effect for reverse simulation

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6), // Match your 10-second GIF
    )..repeat(reverse: true); // Repeat with reverse
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_animationController); // Fade from slightly dim to full
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void answerQuestion(String answer) {
    setState(() {
      answers[currentQuestion] = answer;
      if (answer == 'Yes') {
        genreScores[questions[currentQuestion]['genre']] =
            (genreScores[questions[currentQuestion]['genre']] ?? 0) + 1;
      }
      // Automatically go to next question if not the last
      if (currentQuestion < 14) {
        currentQuestion++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestion < 14) setState(() => currentQuestion++);
  }

  void previousQuestion() {
    if (currentQuestion > 0) setState(() => currentQuestion--);
  }

  void finishQuiz() {
    String favoriteGenre = genreScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    // Save genre in SharedPreferences if needed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(favoriteGenre: favoriteGenre),
      ),
    );
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
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glass box for question
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                questions[currentQuestion]['question'],
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        // Fixed Yes/No buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _glassButton(
                              'Yes',
                              answers[currentQuestion] == null
                                  ? () => answerQuestion('Yes')
                                  : null,
                            ),
                            SizedBox(width: 20),
                            _glassButton(
                              'No',
                              answers[currentQuestion] == null
                                  ? () => answerQuestion('No')
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Glass box for Previous/Next buttons, not too close to bottom
              Padding(
                padding: EdgeInsets.only(
                  bottom: 100,
                ), // More distance from bottom
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ), // Tight padding to fit buttons
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // Box fits buttons tightly
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentQuestion > 0)
                            _glassButton('Previous', previousQuestion),
                          if (currentQuestion > 0) SizedBox(width: 10),
                          _glassButton(
                            currentQuestion == 14 ? 'Finish' : 'Next',
                            currentQuestion == 14 ? finishQuiz : nextQuestion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2), // Faint glow effect
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
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
      ),
    );
  }
}
