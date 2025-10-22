import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; // Import config

class SimilarMoviesScreen extends StatefulWidget {
  final String favoriteGenre;

  const SimilarMoviesScreen({super.key, required this.favoriteGenre});

  @override
  SimilarMoviesScreenState createState() => SimilarMoviesScreenState();
}

class SimilarMoviesScreenState extends State<SimilarMoviesScreen> {
  List<dynamic> movies = [];

  @override
  void initState() {
    super.initState();
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
    String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    final response = await http.get(Uri.parse(url));
    setState(() => movies = json.decode(response.body)['results']);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        var movie = movies[index];
        return ListTile(
          leading: Image.network(
            'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
          ),
          title: Text(
            movie['title'],
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Genre: ${widget.favoriteGenre}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              _addToFavorites(movie);
            },
          ),
        );
      },
    );
  }

  Future<void> _addToFavorites(Map movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(jsonEncode(movie));
    prefs.setStringList('favorites', favorites);
  }
}
