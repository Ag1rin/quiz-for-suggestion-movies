import 'package:flutter/material.dart';
import 'dart:ui'; // For blur
import 'home_screen.dart'; // Import for going to home

class QuizScreen extends StatefulWidget {
  @override
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

  void answerQuestion(String answer) {
    setState(() {
      answers[currentQuestion] = answer;
      if (answer == 'Yes') {
        genreScores[questions[currentQuestion]['genre']] =
            (genreScores[questions[currentQuestion]['genre']] ?? 0) + 1;
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
            child: Image.asset('assets/background.gif', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          Padding(
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _glassButton('Yes', () => answerQuestion('Yes')),
                    _glassButton('No', () => answerQuestion('No')),
                  ],
                ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (currentQuestion > 0)
                      _glassButton('Previous', previousQuestion),
                    _glassButton(
                      currentQuestion == 14 ? 'Finish' : 'Next',
                      currentQuestion == 14 ? finishQuiz : nextQuestion,
                    ),
                  ],
                ),
              ],
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
}
