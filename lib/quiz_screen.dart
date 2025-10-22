import 'package:flutter/material.dart';
import 'dart:ui'; // For blur
import 'package:shared_preferences/shared_preferences.dart'; // For saving genre
import 'home_screen.dart'; // Import for going to home

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
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
  };

  List<Map<String, dynamic>> questions = [
    // 10 questions
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
  ];

  List<String?> answers = List.filled(10, null);

  void answerQuestion(String answer) {
    setState(() {
      answers[currentQuestion] = answer;
      if (answer == 'Yes') {
        genreScores[questions[currentQuestion]['genre']] =
            (genreScores[questions[currentQuestion]['genre']] ?? 0) + 1;
      }
      if (currentQuestion < 9) {
        currentQuestion++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestion < 9) setState(() => currentQuestion++);
  }

  void previousQuestion() {
    if (currentQuestion > 0) setState(() => currentQuestion--);
  }

  Future<void> finishQuiz() async {
    String favoriteGenre = genreScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('favoriteGenre', favoriteGenre);
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(favoriteGenre: favoriteGenre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        // Lazy load GIF to improve startup
        future: Future.delayed(Duration.zero), // Simple delay for async load
        builder: (context, snapshot) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/background.gif', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  // ignore: deprecated_member_use
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
                            Text(
                              questions[currentQuestion]['question'],
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 40),
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
                  Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentQuestion > 0)
                          _glassButton('Previous', previousQuestion),
                        if (currentQuestion > 0) SizedBox(width: 10),
                        _glassButton(
                          currentQuestion == 9 ? 'Finish' : 'Next',
                          currentQuestion == 9 ? finishQuiz : nextQuestion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.2),
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
              // ignore: deprecated_member_use
              backgroundColor: Colors.white.withOpacity(0.2),
              // ignore: deprecated_member_use
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
