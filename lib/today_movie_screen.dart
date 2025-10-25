import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart'; // Added for caching images
import 'config.dart';

class TodayMovieScreen extends StatefulWidget {
  final String favoriteGenre;

  const TodayMovieScreen({super.key, required this.favoriteGenre});

  @override
  TodayMovieScreenState createState() => TodayMovieScreenState();
}

class TodayMovieScreenState extends State<TodayMovieScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? lastMovie;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);
    _loadLastMovie();
  }

  Future<void> _loadLastMovie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastMovieJson = prefs.getString('lastMovie');
    if (lastMovieJson != null) {
      setState(() => lastMovie = json.decode(lastMovieJson) as Map<String, dynamic>?);
    } else {
      var movie = await _getMovieRecommendation(widget.favoriteGenre);
      setState(() => lastMovie = movie);
      prefs.setString('lastMovie', json.encode(movie));
    }
  }

  Future<Map<String, dynamic>> _getMovieRecommendation(String genre) async {
    Map<String, String> genreIds = {
      'Action': '28',
      'Drama': '18',
      'Comedy': '35',
      'Horror': '27',
      'Sci-Fi': '878',
      'Romance': '10749',
      'Thriller': '53',
      'Adventure': '12',
      'Fantasy': '14',
      'Animation': '16',
    };
    String genreId = genreIds[genre] ?? '28';
    String url = 'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var results = json.decode(response.body)['results'] as List<dynamic>;
        return results.isNotEmpty ? results[0] as Map<String, dynamic> : {};
      } else {
        throw Exception('Failed to load movie: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movie: $e');
      return {};
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset('assets/main.gif', fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withAlpha(76)),
          ),
        ),
        Center(
          child: lastMovie != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/w500${lastMovie!['poster_path'] ?? ''}',
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      fit: BoxFit.cover,
                      width: 200,
                      height: 300,
                    ),
                    Text(lastMovie!['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 24)),
                    Text(
                      'Genre: ${widget.favoriteGenre}, Runtime: ${lastMovie!['runtime'] ?? 'N/A'} min, Language: ${lastMovie!['original_language'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ],
    );
  }
}