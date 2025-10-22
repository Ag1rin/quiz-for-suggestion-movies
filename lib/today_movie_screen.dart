import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Import config

class TodayMovieScreen extends StatefulWidget {
  final String favoriteGenre;

  const TodayMovieScreen({super.key, required this.favoriteGenre});

  @override
  TodayMovieScreenState createState() => TodayMovieScreenState();
}

class TodayMovieScreenState extends State<TodayMovieScreen> {
  Map<String, dynamic>? lastMovie;

  @override
  void initState() {
    super.initState();
    _loadLastMovie();
  }

  Future<void> _loadLastMovie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastMovieJson = prefs.getString('lastMovie');
    if (lastMovieJson != null) {
      setState(
        () => lastMovie = json.decode(lastMovieJson) as Map<String, dynamic>?,
      );
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
    String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    final response = await http.get(Uri.parse(url));
    var results = json.decode(response.body)['results'] as List<dynamic>;
    return results.isNotEmpty ? results[0] as Map<String, dynamic> : {};
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: lastMovie != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://image.tmdb.org/t/p/w500${lastMovie!['poster_path']}',
                ),
                Text(
                  lastMovie!['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                Text(
                  'Genre: ${widget.favoriteGenre}, Runtime: ${lastMovie!['runtime'] ?? 'N/A'} min, Language: ${lastMovie!['original_language'] ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            )
          : const CircularProgressIndicator(),
    );
  }
}
