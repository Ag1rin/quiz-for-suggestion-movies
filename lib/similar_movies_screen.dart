import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'config.dart';

class SimilarMoviesScreen extends StatefulWidget {
  final String favoriteGenre;

  const SimilarMoviesScreen({super.key, required this.favoriteGenre});

  @override
  SimilarMoviesScreenState createState() => SimilarMoviesScreenState();
}

class SimilarMoviesScreenState extends State<SimilarMoviesScreen> with SingleTickerProviderStateMixin {
  List<dynamic> movies = [];
  List<String> favoritesIds = []; // For checking duplicates and show filled heart
  int _currentPage = 1;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
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
    _loadFavorites();
    _fetchMovies(initialLoad: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading) {
        _fetchMovies();
      }
    });
  }

  /// Load favorite movie IDs from SharedPreferences
  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoritesJson = prefs.getStringList('favorites');

    favoritesIds = favoritesJson
            ?.map((jsonStr) => jsonDecode(jsonStr)['id'].toString())
            .toList() ??
        [];

    setState(() {});
  }

  /// Fetch movies from TMDB and get runtime for each
  Future<void> _fetchMovies({bool initialLoad = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (initialLoad) {
      movies.clear();
      _currentPage = 1;
    }
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
    String url = 'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId&page=$_currentPage';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var newMovies = json.decode(response.body)['results'] as List<dynamic>;
        for (var movie in newMovies) {
          movie['runtime'] = await _getMovieRuntime(movie['id']);
        }
        setState(() {
          movies.addAll(newMovies);
          _currentPage++;
        });
      } else {
        print('Failed to load movies: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Get runtime for a single movie from TMDB
  Future<int?> _getMovieRuntime(int movieId) async {
    String url = 'https://api.themoviedb.org/3/movie/$movieId?api_key=${Config.tmdbApiKey}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body)['runtime'];
      }
    } catch (e) {
      print('Error fetching runtime: $e');
    }
    return null;
  }

  Future<void> _refreshMovies() async {
    await _fetchMovies(initialLoad: true);
  }

  /// Add movie to favorites if not already added
  Future<void> _addToFavorites(Map movie) async {
    String movieId = movie['id'].toString();
    if (favoritesIds.contains(movieId)) return; // Prevent duplicate

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(json.encode(movie));
    prefs.setStringList('favorites', favorites);
    setState(() {
      favoritesIds.add(movieId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${movie['title']} added to favorites')),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
        RefreshIndicator(
          onRefresh: _refreshMovies,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: movies.length + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              if (index < movies.length) {
                var movie = movies[index];
                String movieId = movie['id'].toString();
                bool isFavorite = favoritesIds.contains(movieId);
                return ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/w200${movie['poster_path'] ?? ''}',
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    fit: BoxFit.cover,
                    width: 50,
                    height: 75,
                  ),
                  title: Text(movie['title'], style: TextStyle(color: Colors.white)),
                  subtitle: Text('Runtime: ${movie['runtime'] ?? 'N/A'} min', style: TextStyle(color: Colors.grey)),
                  trailing: IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    onPressed: () {
                      _addToFavorites(movie);
                    },
                  ),
                );
              } else {
                return _isLoading ? Center(child: CircularProgressIndicator()) : SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }
}