import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart'; // Added for caching images
import 'config.dart';

class SimilarMoviesScreen extends StatefulWidget {
  final String favoriteGenre;

  const SimilarMoviesScreen({super.key, required this.favoriteGenre});

  @override
  SimilarMoviesScreenState createState() => SimilarMoviesScreenState();
}

class SimilarMoviesScreenState extends State<SimilarMoviesScreen> with SingleTickerProviderStateMixin {
  List<dynamic> movies = [];
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
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
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
    String genreId = genreIds[widget.favoriteGenre] ?? '28';
    String url = 'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() => movies = json.decode(response.body)['results']);
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
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
        ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            var movie = movies[index];
            return ListTile(
              leading: CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w200${movie['poster_path'] ?? ''}',
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
                width: 50,
                height: 75,
              ),
              title: Text(movie['title'] ?? 'No Title', style: const TextStyle(color: Colors.white)),
              subtitle: Text('Genre: ${widget.favoriteGenre}', style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  _addToFavorites(movie);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addToFavorites(Map movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(json.encode(movie));
    prefs.setStringList('favorites', favorites);
  }
}